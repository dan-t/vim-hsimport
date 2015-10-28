
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
  call s:hsimport(l:module, '', 0, l:qualAndSym[0], l:srcFile)

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
     call s:hsimport(l:module, '', 0, l:qualAndSym[0], l:srcFile)
  else
     let l:symbol = l:qualAndSym[1]
     let l:allOfSym = 0
     " Check if the symbol starts with an upper case letter, if
     " yes, then ask if all contructors or methods of the type/class
     " should be imported
     if l:symbol =~# '\v^\u+\w*$'
        let l:allOfSym = s:import_all_of_symbol(l:symbol)
     endif
     call s:hsimport(l:module, l:symbol, l:allOfSym, '', l:srcFile)
  endif

  return
endfunction


function! s:debug(msg)
  if get(g:, 'hsimport_debug', 0) != 0
    echo a:msg
  endif
endfunction


function! s:import_all_of_symbol(symbol)
  if a:symbol ==# ''
    return 0
  endif

  let l:inputList  = ['']
  let l:inputList += ['1 Import only Type/Class  : ' . a:symbol]
  let l:inputList += ['2 Import all of Type/Class: ' . a:symbol . '(..)']

  let l:idx = inputlist(l:inputList)
  if l:idx == 0 || l:idx == 1
     return 0
  endif

  return 1
endfunction


function! s:select_module(symbol)
  if a:symbol ==# ''
    return ''
  endif

  let l:srcFiles = s:source_files_containing(a:symbol)
  let l:modules = filter(s:hdevtools_findsymbol(a:symbol, l:srcFiles), 'v:val != "Prelude"')
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
  let l:src_dir = s:src_root()
  call s:debug('src_dir: ' . l:src_dir)

  if l:src_dir ==# ''
    return []
  endif

  let l:srcFiles = []
  let l:dataRegex         = '^data\s*' . a:symbol . '.*$'
  let l:typeRegex         = '^type\s*' . a:symbol . '.*$'
  let l:topLevelFuncRegex = '^' . a:symbol . '\s*::.*$'
  let l:topLevelOpRegex   = '^\(' . a:symbol . '\)\s*::.*$'
  let l:grepRegex         = shellescape(l:dataRegex . "|" . l:typeRegex . "|" . l:topLevelFuncRegex . "|" . l:topLevelOpRegex)
  let l:grepExclude       = '--exclude=.hdevtools.sock --exclude-dir=dist --exclude-dir=.cabal-sandbox'
  let l:grpCmd            = 'grep -Rl -E ' . l:grepExclude . ' ' . l:grepRegex . ' ' . l:src_dir
  call s:debug('grpCmd: ' . l:grpCmd)

  let l:grepOutput = system(l:grpCmd)
  call s:debug('grepOutput: ' . l:grepOutput)

  " convert files to absolute paths and remove the current file if it's contained in the list
  let l:files = split(l:grepOutput, '\n')
  let l:curFile = fnamemodify(expand('%'), ':p')
  for l:file in l:files
    let l:absFile = fnamemodify(l:file, ':p')
    if l:absFile !=# l:curFile
      let l:srcFiles += [l:absFile]
    endif
  endfor

  call s:debug('srcFiles: ' . join(l:srcFiles, '\n'))
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
    let l:symbol = s:extract_identifier(getline("."), col("."))
    if l:symbol ==# ''
      call hsimport#print_warning('No Symbol Under Cursor')
    endif
  endif

  return l:symbol
endfunction


function! s:hsimport(module, symbol, allOfSym, qualifiedName, srcFile)
  let l:cursorPos = getpos('.')
  let l:numLinesBefore = line('$')
  let l:cmd = s:build_command(a:module, a:symbol, a:allOfSym, a:qualifiedName, a:srcFile)
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


function! s:build_command(module, symbol, allOfSym, qualifiedName, sourceFile)
  let l:modParam = '-m ' . shellescape(a:module)

  let l:symParam = ''
  if a:symbol !=# ''
    let l:symParam = '-s ' . shellescape(a:symbol) 
  endif

  let l:allOfSymParam = ''
  if a:allOfSym == 1
    let l:allOfSymParam = '-a'
  endif

  let l:qualParam = ''
  if a:qualifiedName !=# ''
     let l:qualParam = '-q ' . shellescape(a:qualifiedName)
  endif

  let l:srcParam = shellescape(a:sourceFile)
  let l:cmd = 'hsimport ' . l:modParam . ' ' . l:symParam . ' ' . l:allOfSymParam . ' ' . l:qualParam . ' ' . l:srcParam
  return l:cmd
endfunction


" a verbatim copy from vim-hdevtools
function! s:extract_identifier(line_text, col)
  if a:col > len(a:line_text)
    return ''
  endif

  let l:index = a:col - 1
  let l:delimiter = '\s\|[(),;`{}"[\]]'

  " Move the index forward till the cursor is not on a delimiter
  while match(a:line_text[l:index], l:delimiter) == 0
    let l:index = l:index + 1
    if l:index == len(a:line_text)
      return ''
    endif
  endwhile

  let l:start_index = l:index
  " Move start_index backwards until it hits a delimiter or beginning of line
  while l:start_index > 0 && match(a:line_text[l:start_index-1], l:delimiter) < 0
    let l:start_index = l:start_index - 1
  endwhile

  let l:end_index = l:index
  " Move end_index forwards until it hits a delimiter or end of line
  while l:end_index < len(a:line_text) - 1 && match(a:line_text[l:end_index+1], l:delimiter) < 0
    let l:end_index = l:end_index + 1
  endwhile

  let l:fragment = a:line_text[l:start_index : l:end_index]
  let l:index = l:index - l:start_index

  let l:results = []

  let l:name_regex = '\(\u\(\w\|''\)*\.\)*\(\a\|_\)\(\w\|''\)*'
  let l:operator_regex = '\(\u\(\w\|''\)*\.\)*\(\\\|[-!#$%&*+./<=>?@^|~:]\)\+'

  " Perform two passes over the fragment(one for finding a name, and the other
  " for finding an operator). Each pass tries to find a match that has the
  " cursor contained within it.
  for l:regex in [l:name_regex, l:operator_regex]
    let l:remainder = l:fragment
    let l:rindex = l:index
    while 1
      let l:i = match(l:remainder, l:regex)
      if l:i < 0
        break
      endif
      let l:result = matchstr(l:remainder, l:regex)
      let l:end = l:i + len(l:result)
      if l:i <= l:rindex && l:end > l:rindex
        call add(l:results, l:result)
        break
      endif
      let l:remainder = l:remainder[l:end :]
      let l:rindex = l:rindex - l:end
    endwhile
  endfor

  " There can be at most 2 matches(one from each pass). The longest one is the
  " correct one.
  if len(l:results) == 0
    return ''
  elseif len(l:results) == 1
    return l:results[0]
  else
    if len(l:results[0]) > len(l:results[1])
      return l:results[0]
    else
      return l:results[1]
    endif
  endif
endfunction


" a verbatim copy from vim-hdevtools
" Unit Test for extract_identifier
function! hsimport#test_extract_identifier()
  let l:tests = [
        \ 'let #foo# = 5',
        \ '#main#',
        \ '1 #+# 1',
        \ '1#+#1',
        \ 'blah #Foo.Bar# blah',
        \ 'blah #Foo.bar# blah',
        \ 'blah #foo#.Bar blah',
        \ 'blah #foo#.bar blah',
        \ 'blah foo#.#Bar blah',
        \ 'blah foo#.#bar blah',
        \ 'blah foo.#bar# blah',
        \ 'blah foo.#Bar# blah',
        \ 'blah #A.B.C.d# blah',
        \ '#foo#+bar',
        \ 'foo+#bar#',
        \ '#Foo#+bar',
        \ 'foo+#Bar#',
        \ '#Prelude..#',
        \ '[#foo#..bar]',
        \ '[foo..#bar#]',
        \ '#Foo.bar#',
        \ '#Foo#*bar',
        \ 'Foo#*#bar',
        \ 'Foo*#bar#',
        \ '#Foo.foo#.bar',
        \ 'Foo.foo#.#bar',
        \ 'Foo.foo.#bar#',
        \ '"a"#++#"b"',
        \ '''a''#<#''b''',
        \ '#Foo.$#',
        \ 'foo.#Foo.$#',
        \ '#-#',
        \ '#/#',
        \ '#\#',
        \ '#@#'
        \ ]
  for l:test in l:tests
    let l:expected = matchstr(l:test, '#\zs.*\ze#')
    let l:input = substitute(l:test, '#', '', 'g')
    let l:start_index = match(l:test, '#') + 1
    let l:end_index = match(l:test, '\%>' . l:start_index . 'c#') - 1
    for l:i in range(l:start_index, l:end_index)
      let l:result = s:extract_identifier(l:input, l:i)
      if l:expected !=# l:result
        call hsimport#print_error("TEST FAILED expected: (" . l:expected . ") got: (" . l:result . ") for column " . l:i . " of: " . l:input)
      endif
    endfor
  endfor
endfunction


function! s:hdevtools_findsymbol(identifier, srcFiles)
  let l:identifier = a:identifier

  " No identifier argument given, probably called from a keyboard shortcut
  if l:identifier ==# ''
    hsimport#print_error('No identifier given!')
    return []
  endif

  let l:srcParam = ''
  for l:srcFile in a:srcFiles
     let l:srcParam .= ' ' . shellescape(l:srcFile)
  endfor

  let l:cmd = 'hdevtools findsymbol ' . shellescape(l:identifier) . ' ' . l:srcParam
  let l:output = system(l:cmd)
  let l:lines = split(l:output, '\n')

  " Check if the call to hdevtools info succeeded
  if v:shell_error != 0
    for l:line in l:lines
      call hsimport#print_error(l:line)
    endfor
  else
    return l:lines
  endif

  return []
endfunction


function! s:src_root()
  let l:old_cwd = getcwd()
  let l:cabal_dir = ''
  while 1
    let l:cwd = getcwd()
    call s:debug('cwd: ' . l:cwd)
    let l:files = split(globpath('.', '*.cabal'), '\n')
    call s:debug('globpath: ' . join(l:files, ' '))
    if len(l:files) == 1
      let l:cabal_dir = l:cwd
      break
    endif

    exec 'cd ..'
    if l:cwd == getcwd()
      break
    endif
  endwhile

  exec 'cd ' . l:old_cwd
  return l:cabal_dir
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
