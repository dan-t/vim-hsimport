hsimport Vim Plugin
===================

The Vim plugin for the command line program [hsimport](<https://github.com/dan-t/hsimport>).

In conjunction to the [hsimport](<https://github.com/dan-t/hsimport>) command the Vim plugin also
uses the command [hdevtools](<https://github.com/bitc/hdevtools/>) and the Vim plugin
[vim-hdevtools](<https://github.com/bitc/vim-hdevtools/>).

Currently you need to use forks of `hdevtools` and `vim-hdevtools` to get a working
version of `vim-hsimport`, please see the installation section for details.

Installation
------------

1. Ensure that you're having a cabal-install version greater or equal than 1.18, to be able
   to use cabal sandboxes. You can update your version by:

        $ cabal install cabal-install

2. Install `hsimport`, using a `cabal sandbox` is the recommend way:

        $ mkdir your_hsimport_build_dir
        $ cabal sandbox init
        $ cabal install hsimport
   
    Your `hsimport` binary is now at `your_hsimport_build_dir/.cabal-sandbox/bin/hsimport`.

    You now most likely want to create a symbolic link from a directory which is contained
    inside of your $PATH e.g:

        $ ln -s your_hsimport_build_dir/.cabal-sandbox/bin/hsimport ~/bin/hsimport 

3. Install the fork of `hdevtools`, using a `cabal sandbox` is the recommend way:

        $ mkdir your_hdevtools_build_dir
        $ git clone https://github.com/dan-t/hdevtools
        $ cabal sandbox init
        $ cabal install

    Your `hdevtools` binary is now at `your_hdevtools_build_dir/.cabal-sandbox/bin/hdevtools`.
    
    You now most likely want to create a symbolic link from a directory which is contained
    inside of your $PATH e.g:

        $ ln -s your_hdevtools_build_dir/.cabal-sandbox/bin/hdevtools ~/bin/hdevtools

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
        return finddir('.cabal-sandbox', './;')
    endfunction
    
    function! FindCabalSandboxPackageConf()
        return glob(FindCabalSandbox() . '/*-packages.conf.d')
    endfunction
    
    let g:hdevtools_options = '-g-package-conf=' . FindCabalSandboxPackageConf()


You also most likely want to add keybindings for the two avialable commands into your `~/.vimrc` e.g.:

    nmap <silent> <F1> HsimportModule<CR>
    nmap <silent> <F2> HsimportSymbol<CR>

Features
--------

`HsimportModule` imports the whole module of the symbol/identifier under the cursor.

`HsimportSymbol` imports only the symbol/indentifier under the cursor.

Credits
-------

Heavily inspired by [vim-hdevtools](<https://github.com/bitc/vim-hdevtools/>).
