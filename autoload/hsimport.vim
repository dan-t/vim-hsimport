
function! hsimport#import_module(symbol)
  let l:module = s:select_module(a:symbol)
  if l:module ==# ''
    return
  endif

  let l:srcFile = expand('%')
  call s:hsimport(l:module, '', '', l:srcFile)
  return
endfunction


function! hsimport#import_symbol(symbol)
  let l:symbol = hsimport#get_symbol(a:symbol)
  if l:symbol ==# ''
    return ''
  endif

  let l:module = s:select_module(l:symbol)
  if l:module ==# ''
    return
  endif

  let l:srcFile = expand('%')
  call s:hsimport(l:module, l:symbol, '', l:srcFile)
  return
endfunction


function! s:select_module(symbol)
  let l:symbol = s:get_symbol(a:symbol)
  if l:symbol ==# ''
    return ''
  endif

  let l:modules = hdevtools#findsymbol(l:symbol)
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
    call extend(l:inputList, [printf('%d ', l:i) . l:module])
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


function! s:get_symbol(symbol)
  let l:symbol = a:symbol

  " No symbol argument given, probably called from a keyboard shortcut
  if l:symbol ==# ''
    " Get the symbol under the cursor
    let l:symbol = hdevtools#extract_identifier(getline("."), col("."))
    if l:symbol ==# ''
      call s:print_warning('No Symbol Under Cursor')
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
      call s:print_error(l:line)
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


function! s:print_error(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction


function! s:print_warning(msg)
  echohl WarningMsg
  echomsg a:msg
  echohl None
endfunction
