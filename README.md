hsimport Vim Plugin
===================

`vim-hsimport` is a Vim plugin that automatically creates import statements for
Haskell source files for the symbol/identifier under the cursor.

`vim-hsimport` can create import statements for the whole module, for only
the desired symbol/indentifier and is also able to create qualified module
import statements.

By using `hdevtools` in conjunction with a `cabal sandbox`, dynamically only
the modules of packages are considered, which your project depends on.

`vim-hsimport` does also consider the modules of your current project.

If the symbol/identifier is contained in multiple modules, then a selection
dialog is shown.


In conjunction to the [hsimport](<https://github.com/dan-t/hsimport>) command the Vim plugin also
uses the command [hdevtools](<https://github.com/bitc/hdevtools/>) and the Vim plugin
[vim-hdevtools](<https://github.com/bitc/vim-hdevtools/>).

Currently you need to use forks of `hdevtools` and `vim-hdevtools` to get a working
version of `vim-hsimport`, please see the installation section for details.

Currently the biggest issue is if and how modules of your current project are
considered for the import, please see the issues section.

Features / Vim Commands
-----------------------

`HsimportModule` imports the whole module of the symbol/identifier under the cursor.

`HsimportSymbol` imports only the symbol/indentifier under the cursor.

If the symbol/indentifier under the cursor is contained in multiple modules,
then a selection dialog will be shown.

If the symbol has a module qualifier e.g. `Text.pack`, then both commands will create
a qualified import for the selected module. If the module `Data.Text` was selected,
then the created import statement will be `import qualified Data.Text as Text`.

The first call of either command might take several seconds, because `hdevtools` has to
cache all of the modul informations.

Installation
------------

1. Ensure that you're having a cabal-install version greater or equal than 1.18, to be able
   to use cabal sandboxes. You can update your version by:

        $ cabal install cabal-install

2. Install `hsimport`, using a `cabal sandbox` is the recommend way:

        $ mkdir your_hsimport_build_dir
        $ cd your_hsimport_build_dir
        $ cabal sandbox init
        $ cabal install hsimport
   
    Your `hsimport` binary is now at `your_hsimport_build_dir/.cabal-sandbox/bin/hsimport`.

    You now most likely want to create a symbolic link from a directory which is contained
    inside of your $PATH e.g.:

        $ ln -s $PWD/your_hsimport_build_dir/.cabal-sandbox/bin/hsimport ~/bin/hsimport

3. Install the fork of `hdevtools`, using a `cabal sandbox` is the recommend way:

        $ git clone https://github.com/dan-t/hdevtools your_hdevtools_build_dir
        $ cd your_hdevtools_build_dir
        $ cabal sandbox init
        $ cabal install

    Your `hdevtools` binary is now at `your_hdevtools_build_dir/.cabal-sandbox/bin/hdevtools`.
    
    You now most likely want to create a symbolic link from a directory which is contained
    inside of your $PATH e.g.:

        $ ln -s $PWD/your_hdevtools_build_dir/.cabal-sandbox/bin/hdevtools ~/bin/hdevtools

4. Install `vim-hsimport`. [pathogen.vim](<https://github.com/tpope/vim-pathogen/>)
   is the recommended way:

        $ cd ~/.vim/bundle
        $ git clone https://github.com/dan-t/vim-hsimport

5. Install the fork of `vim-hdevtools`. [pathogen.vim](<https://github.com/tpope/vim-pathogen/>)
   is the recommended way:

        $ cd ~/.vim/bundle
        $ git clone https://github.com/dan-t/vim-hdevtools  

Configuration
-------------

If you're working on a project you normally would like to extend the import list of a Haskell
source file only by modules of libraries, which your project depends on.

This can be achieved by building your project in a `cabal sandbox` and telling `hdevtools` where
the sandbox is located.

For Vim put the following into your `~/.vimrc`:

    function! s:FindCabalSandbox()
       let l:sandbox    = finddir('.cabal-sandbox', './;')
       let l:absSandbox = fnamemodify(l:sandbox, ':p')
       return l:absSandbox
    endfunction
    
    function! s:FindCabalSandboxPackageConf()
       return glob(s:FindCabalSandbox() . '*-packages.conf.d')
    endfunction
    
    function! s:HaskellSourceDir()
       return fnamemodify(s:FindCabalSandbox(), ':h:h') . '/src'
    endfunction
    
    function! s:HdevtoolsSocketFile()
       return s:HaskellSourceDir() . '/.hdevtools.sock'
    endfunction
    
    autocmd Bufenter *.hs :call s:InitHaskellVars()
    
    function! s:InitHaskellVars()
       let g:hdevtools_options  = '-g-W'
       let g:hdevtools_options .= ' ' . '-g-package-conf=' . s:FindCabalSandboxPackageConf()
       let g:hdevtools_options .= ' ' . '-g-i' . s:HaskellSourceDir()
       let g:hdevtools_options .= ' ' . '--socket=' . s:HdevtoolsSocketFile()
       let g:hsimport_src_dir   = s:HaskellSourceDir()
    endfunction

If the root directory of your projects Haskell source code is named `src` and lies in the
same directory than your projects cabal file, then you can just use `HaskellSourceDir` as it
is, otherwise you have to change it.

Instead of the manual configuration above I highly recommend the use of [cabal-cargs](<https://github.com/dan-t/cabal-cargs>)
for the configuration of `hdevtools` and `hsimport`, because it will automatically find
the corresponding cabal file, the cabal sandbox and consider all settings in the cabal file:

    function! s:CabalCargs(args)
       let l:output = system('cabal-cargs ' . a:args)
       if v:shell_error != 0
          let l:lines = split(l:output, '\n')
          echohl ErrorMsg
          echomsg 'args: ' . a:args
          for l:line in l:lines
             echomsg l:line
          endfor
          echohl None
          return ''
       endif
       return l:output
    endfunction
    
    function! s:HdevtoolsOptions()
        return s:CabalCargs('--format=hdevtools --sourcefile=' . shellescape(expand('%')))
    endfunction
    
    function! s:HsimportSrcDir()
       let l:output  = s:CabalCargs('--format=pure --only=hs_source_dirs --sourcefile=' . shellescape(expand('%')))
       let l:srcDirs = split(l:output, ' ')
       if len(l:srcDirs) == 0
          return ''
       endif
       return l:srcDirs[0]
    endfunction
    
    autocmd Bufenter *.hs :call s:InitHaskellVars()
    
    function! s:InitHaskellVars()
       if filereadable(expand('%'))
          let g:hdevtools_options = s:HdevtoolsOptions()
          let g:hsimport_src_dir  = s:HsimportSrcDir()
       endif
    endfunction

You also most likely want to add keybindings for the two avialable commands into your `~/.vimrc` e.g.:

    nmap <silent> <F1> :silent update <bar> HsimportModule<CR>
    nmap <silent> <F2> :silent update <bar> HsimportSymbol<CR>

If you're developing with the GHC-API (the ghc library), then you also want to add `-g-package=ghc`
to `g:hdevtools_options`. Normally only exposed/non-hidden packages are considered, but even
if your project depends on `ghc`, then the `ghc` package is still marked as hidden. I don't know
why that's the case.

Issues
------

You have to call `cabal install` at least once to fill the package database of your `cabal sandbox`,
because that's the information which is used for finding modules.

If you have added another library as dependency to your project, then you have again to
call `cabal install` to update the package database accordingly.

Currently the modules for your own project are considered by a quite simple heuristic.
A project might have a lot of files, so `hdevtools` just can't be called with every
source file of your project, because loading each file with GHC might take some time.

So currently the source tree starting at `g:hdevtools_src_dir` is searched by `grep` with
a regex that should "mostly" match the symbol with the export list (in a quite fixed form, see below)
and with top level function/operator definitions.

So only source files are considered for further inspection that have the symbol at:

    module Blub
       ( symbol
       , symbol
       ) where

    symbol :: ...
    (symbol) :: ...

I'm very open for changing this to something more robust. The solution can return false
positives, because the real inspection is done by `hdevtools`, it's just about to reduce
the number of source files given to `hdevtools` and that it's still fast enough to be
interactive usable.

Credits
-------

Heavily inspired by [vim-hdevtools](<https://github.com/bitc/vim-hdevtools/>).
