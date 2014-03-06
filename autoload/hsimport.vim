
function! hsimport#import_module(symbol)
  let l:qualAndSym = s:split_module_qualifier_and_symbol(a:symbol)
  if len(l:qualAndSym) == 0
     return
  endif

  let l:module = s:select_module(l:qualAndSym[1])
  if l:module ==# ''
     return
  endif

  let l:srcFile = expand('%')
  call s:hsimport(l:module, '', l:qualAndSym[0], l:srcFile)

  return
endfunction


function! hsimport#import_symbol(symbol)
  let l:qualAndSym = s:split_module_qualifier_and_symbol(a:symbol)
  if len(l:qualAndSym) == 0
     return
  endif

  let l:module = s:select_module(l:qualAndSym[1])
  if l:module ==# ''
     return
  endif

  let l:srcFile = expand('%')
  if l:qualAndSym[0] !=# ''
     call s:hsimport(l:module, '', l:qualAndSym[0], l:srcFile)
  else
     call s:hsimport(l:module, l:qualAndSym[1], '', l:srcFile)
  endif

  return
endfunction


function! hsimport#debug()
   return get(g:, 'hsimport_debug', 0)
endfunction


function! hsimport#src_dir()
   return get(g:, 'hsimport_src_dir', '')
endfunction


function! s:select_module(symbol)
  if a:symbol ==# ''
    return ''
  endif

  let l:srcFiles = s:source_files_containing(a:symbol)
  let l:modules = hdevtools#findsymbol(a:symbol, l:srcFiles)
  let l:numModules = len(l:modules)
  if l:numModules == 0
    return ''
  endif

  if l:numModules == 1
    return l:modules[0]
  endif

  let l:inputList = ['Select Module to Import:']
  let l:i = 1
  for l:module in l:modules
    let l:inputList += [printf('%d ', l:i) . l:module]
    let l:i += 1
  endfor

  let l:idx = inputlist(l:inputList)
  if l:idx == 0
    return ''
  endif

  if l:idx < 1 || l:idx > l:numModules
    return ''
  endif

  let l:module = l:modules[l:idx - 1]
  return l:module
endfunction


function! s:source_files_containing(symbol)
   let l:srcFiles = []
   let l:srcDir = hsimport#src_dir()
   if l:srcDir !=# ''
      " Currently only source files are considered that contain the symbol in
      " the export list or are having a top level function/operator defintion
      " for the symbol.
      "
      " The export list has mostly to look something like:
      "
      " module Blub
      "    ( symbol
      "    , symbol
      "    ) where
      "
      let l:escapedSymbol     = shellescape(a:symbol)
      let l:exportRegex       = '^ *[(,].*' . l:escapedSymbol . '.*$'
      let l:topLevelFuncRegex = '^' . l:escapedSymbol . ' *::.*$'
      let l:topLevelOpRegex   = '^\(' . l:escapedSymbol . '\) *::.*$'
      let l:grepRegex         = shellescape(l:exportRegex . "|" . l:topLevelFuncRegex . "|" . l:topLevelOpRegex)
      let l:grpCmd            = 'grep --exclude=.hdevtools.sock -Rl -E ' . l:grepRegex . ' ' . l:srcDir
      if hsimport#debug() == 1
         echo 'grpCmd: ' . l:grpCmd
      endif

      let l:grepOutput = system(l:grpCmd)
      if hsimport#debug() == 1
         echo 'grepOutput:'
         echo l:grepOutput
      endif

      let l:files = split(l:grepOutput, '\n')

      " convert files to absolute paths and remove the current file if it's contained in the list
      let l:curFile = fnamemodify(expand('%'), ':p')
      for l:file in l:files
         let l:absFile = fnamemodify(l:file, ':p')
         if l:absFile !=# l:curFile
            let l:srcFiles += [l:absFile]
         endif
      endfor
   endif

   if hsimport#debug() == 1
      echo 'srcFiles:'
      echo l:srcFiles
   endif

   return l:srcFiles
endfunction


function! s:split_module_qualifier_and_symbol(symbol)
   let l:symbol = s:get_symbol(a:symbol)
   if l:symbol ==# ''
      return []
   endif

   let l:words = split(l:symbol, '\.')
   if len(l:words) <= 1
      return ['', l:symbol]
   endif

   let l:moduleWords = []
   let l:symbolWords = []
   let l:nonModuleWordFound = 0
   " consider every word starting with an upper alphabetic 
   " character to be part of the module qualifier, until a word
   " starting with a non upper alphabetic character or a non
   " alphabetic character is found
   for l:word in l:words
      if l:nonModuleWordFound == 0 && l:word =~# '\v^\u+\w*$'
         let l:moduleWords += [l:word]
      else
         let l:symbolWords += [l:word]
         let l:nonModuleWordFound = 1
      endif
   endfor

   " If there're no symbol words, than we might have a qualified
   " data type e.g: 'T.Text', so we're assuming, that the last
   " module word is specifying the symbol.
   if len(l:symbolWords) == 0 && len(l:moduleWords) >= 2
      let l:symbolWords += [l:moduleWords[-1]]
      let l:moduleWords = l:moduleWords[0 : len(l:moduleWords) - 2]
   endif

   return [join(l:moduleWords, '.'), join(l:symbolWords, '')]
endfunction


function! hsimport#test_split_module_qualifier_and_symbol()
   let l:tests = [
      \ ['data', ['', 'data']],
      \ ['Data', ['', 'Data']],
      \ ['T.Text', ['T', 'Text']],
      \ ['Data.Text', ['Data', 'Text']],
      \ ['Data.Text.Text', ['Data.Text', 'Text']],
      \ ['Data.Text.pack', ['Data.Text', 'pack']],
      \ ['.&.', ['', '.&.']],
      \ ['.|.', ['', '.|.']]
      \ ]

   for l:test in l:tests
      let l:result = s:split_module_qualifier_and_symbol(l:test[0])
      if l:result !=# l:test[1]
         let l:refStr = '[' . l:test[1][0] . ', ' . l:test[1][1] . ']'
         let l:resultStr = ''
         if len(l:result) == 2
            let l:resultStr = '[' . l:result[0] . ', ' . l:result[1] . ']'
         endif

         let l:errmsg = 'Test failed for ' . l:test[0] . ': Expected=' . l:refStr . '. Got=' . l:resultStr
         call hsimport#print_error(l:errmsg)
      endif
   endfor
endfunction


function! s:get_symbol(symbol)
  let l:symbol = a:symbol

  " No symbol argument given, probably called from a keyboard shortcut
  if l:symbol ==# ''
    " Get the symbol under the cursor
    let l:symbol = hdevtools#extract_identifier(getline("."), col("."))
    if l:symbol ==# ''
      call hsimport#print_warning('No Symbol Under Cursor')
    endif
  endif

  return l:symbol
endfunction


function! s:hsimport(module, symbol, qualifiedName, srcFile)
  let l:cursorPos = getpos('.')
  let l:numLinesBefore = line('$')
  let l:cmd = s:build_command(a:module, a:symbol, a:qualifiedName, a:srcFile)
  let l:output = system(l:cmd)
  let l:lines = split(l:output, '\n')

  if v:shell_error != 0
    for l:line in l:lines
      call hsimport#print_error(l:line)
    endfor
  else
    exec 'edit ' . a:srcFile
  endif

  " keep cursor at the same position
  let l:numLinesAfter = line('$')
  let l:lineNumDiff = l:numLinesAfter - l:numLinesBefore
  let l:cursorPos[1] = l:cursorPos[1] + l:lineNumDiff
  call setpos('.', l:cursorPos)
endfunction


function! s:build_command(module, symbol, qualifiedName, sourceFile)
  let l:modParam = '-m ' . shellescape(a:module)

  let l:symParam = ''
  if a:symbol !=# ''
    let l:symParam = '-s ' . shellescape(a:symbol) 
  endif

  let l:qualParam = ''
  if a:qualifiedName !=# ''
     let l:qualParam = '-q ' . shellescape(a:qualifiedName)
  endif

  let l:srcParam = shellescape(a:sourceFile)
  let l:cmd = 'hsimport ' . l:modParam . ' ' . l:symParam . ' ' . l:qualParam . ' ' . l:srcParam
  return l:cmd
endfunction


function! hsimport#print_error(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction


function! hsimport#print_warning(msg)
  echohl WarningMsg
  echomsg a:msg
  echohl None
endfunction
