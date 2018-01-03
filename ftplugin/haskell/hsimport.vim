if exists('b:did_ftplugin_hsimport') && b:did_ftplugin_hsimport
  finish
endif
let b:did_ftplugin_hsimport = 1

if !exists('s:has_hsimport')
  let s:has_hsimport = 0
  if !executable('hsimport')
    call hsimport#print_error('hsimport is not executable!')
    finish
  endif
  let s:has_hsimport = 1
endif

if !exists('s:has_hdevtools')
  let s:has_hdevtools = 0
  if !executable('hdevtools')
    call hsimport#print_error('hdevtools is not executable!')
    finish
  endif
  let s:has_hdevtools = 1
endif

if !exists('s:has_grep')
  let s:has_grep = 0
  if !executable('grep')
    call hsimport#print_error('grep is not executable!')
    finish
  endif
  let s:has_grep = 1
endif

if !s:has_hsimport || !s:has_hdevtools || !s:has_grep
  finish
endif

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= ' | '
else
  let b:undo_ftplugin = ''
endif

command! -buffer -nargs=? HsimportModule call hsimport#import_module(<q-args>)
command! -buffer -nargs=? HsimportSymbol call hsimport#import_symbol(<q-args>)
command! -buffer -nargs=0 HsimportVersion call hsimport#version()

let b:undo_ftplugin .= join(map([
      \ 'HsimportModule',
      \ 'HsimportSymbol',
      \ 'HsimportVersion'
      \ ], '"delcommand " . v:val'), ' | ')
let b:undo_ftplugin .= ' | unlet b:did_ftplugin_hsimport'
