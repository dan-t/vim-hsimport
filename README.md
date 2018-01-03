hsimport Vim Plugin
===================

`vim-hsimport` is a Vim plugin that automatically creates import statements for
Haskell source files for the symbol/identifier under the cursor.

It can create import statements for the whole module, for only the desired
symbol/indentifier and is also able to create qualified module import
statements.

It uses [hdevtools](<https://github.com/hdevtools/hdevtools>) for its finding
of modules with the desired symbol. By using `hdevtools` it should also
support any cabal setting, a `cabal sandbox` and even `stack`.

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

1. Install `hsimport`, using a `cabal sandbox` is the recommend way:

        $ mkdir hsimport
        $ cd hsimport
        $ cabal sandbox init
        $ cabal install hsimport
   
    Your `hsimport` binary is now at `hsimport/.cabal-sandbox/bin/hsimport`.
    Ensure that the binary is reachable through your `$PATH` environment variable.

2. Install `hdevtools`, using a `cabal sandbox` is the recommend way:

        $ mkdir hdevtools
        $ cd hdevtools
        $ cabal sandbox init
        $ cabal install hdevtools

    Your `hdevtools` binary is now at `hdevtools/.cabal-sandbox/bin/hdevtools`.
    Ensure that the binary is reachable through your `$PATH` environment variable.

3. Install `vim-hsimport`. [pathogen.vim](<https://github.com/tpope/vim-pathogen/>)
   is the recommended way:

        $ cd ~/.vim/bundle
        $ git clone https://github.com/dan-t/vim-hsimport

Configuration
-------------

You most likely want to add keybindings for the two available commands into your `~/.vimrc` e.g.:

    autocmd FileType haskell nmap <silent> <F1> :silent update <bar> HsimportModule<CR>
    autocmd FileType haskell nmap <silent> <F2> :silent update <bar> HsimportSymbol<CR>

How the imports are pretty printed and where they're placed can be configured. Please take a look
at the [README](<https://github.com/dan-t/hsimport/blob/master/README.md>) of `hsimport`.

Issues
------

Currently the modules for your own project are considered by a quite simple heuristic.
The source tree is searched by `grep` with a regex that should "mostly" match
the symbol with data/type definitions and with top level function/operator
definitions.

I'm very open for changing this to something more robust. The solution can return false
positives, because the real inspection is done by `hdevtools`, it's just about to reduce
the number of source files given to `hdevtools` and that it's still fast enough to be
interactive usable.

Credits
-------

Heavily inspired by [vim-hdevtools](<https://github.com/bitc/vim-hdevtools/>).
