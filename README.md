hsimport Vim Plugin
===================

`vim-hsimport` is a Vim plugin that automatically creates import statements for
Haskell source files for the symbol/identifier under the cursor.

`vim-hsimport` can create import statements for the whole module, for only
the desired symbol/indentifier and is also able to create qualified module
import statements.

By using `hdevtools` in conjunction with a `cabal sandabox`, dynamically only
the modules of packages are considered, which your project depends on.

If the symbol/identifier is contained in multiple modules, then a selection
dialog is shown.


In conjunction to the [hsimport](<https://github.com/dan-t/hsimport>) command the Vim plugin also
uses the command [hdevtools](<https://github.com/bitc/hdevtools/>) and the Vim plugin
[vim-hdevtools](<https://github.com/bitc/vim-hdevtools/>).

Currently you need to use forks of `hdevtools` and `vim-hdevtools` to get a working
version of `vim-hsimport`, please see the installation section for details.

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

    function! FindCabalSandbox()
       let l:sandbox    = finddir('.cabal-sandbox', './;')
       let l:absSandbox = fnamemodify(l:sandbox, ':p')
       return l:absSandbox
    endfunction

    function! HaskellSourceRoot()
       return fnamemodify(FindCabalSandbox(), ':h:h')
    endfunction

    function! FindCabalSandboxPackageConf()
       return glob(FindCabalSandbox() . '*-packages.conf.d')
    endfunction

    let g:hdevtools_options = '-g-W -g-i' . HaskellSourceRoot() . ' -g-package-conf=' . FindCabalSandboxPackageConf()

If the root directory of your projects Haskell source code is equal to the position of your
projects cabal file, then you can just use `HaskellSourceRoot` as it is.

If e.g. your Haskell source code root is the directory `src`, which lies in the same directory
than your projects cabal file, then you could use:

    function! HaskellSourceRoot()
       return fnamemodify(FindCabalSandbox(), ':h:h') . '/src'
    endfunction

You also most likely want to add keybindings for the two avialable commands into your `~/.vimrc` e.g.:

    nmap <silent> <F1> :silent update <bar> HsimportModule<CR>
    nmap <silent> <F2> :silent update <bar> HsimportSymbol<CR>

Issues
------

You have to call `cabal install` at least once to fill the package database of your `cabal sandbox`,
because that's the information which is used for finding modules.

If you have added another library as dependency to your project, than you have again to
call `cabal install` to update the package database accordingly.

Currently the modules for your own project are only considered if they're listed
under `exposed-modules` in the `library` section of the `cabal` file of your project.

Credits
-------

Heavily inspired by [vim-hdevtools](<https://github.com/bitc/vim-hdevtools/>).
