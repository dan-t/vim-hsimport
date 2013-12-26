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

if !s:has_hsimport
  finish
endif

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= ' | '
else
  let b:undo_ftplugin = ''
endif

command! -buffer -nargs=? HsimportModule call hsimport#import_module(<q-args>)
command! -buffer -nargs=? HsimportSymbol call hsimport#import_symbol(<q-args>)

let b:undo_ftplugin .= join(map([
      \ 'HsimportModule',
      \ 'HsimportSymbol'
      \ ], '"delcommand " . v:val'), ' | ')
let b:undo_ftplugin .= ' | unlet b:did_ftplugin_hsimport'
