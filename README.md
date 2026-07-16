# nvim-vscode

my neovim config, set up to feel a lot like VS Code.

it has the VS Code dark look, activity bar and side views, tabs, search,
terminal, git tools, autocomplete, debugging, settings/theme/extension search,
and familiar shortcuts.

## install

back up your old neovim config, then run:

```sh
git clone https://github.com/SudoSaturn/nvim-vscode ~/.config/nvim
nvim
```

plugins install automatically the first time through Neovim's native
`vim.pack` API and are configured by this project's own integration modules.

use `:Store` for the extension marketplace, `:packupdate` for native package
updates, `:Mason` for language tools, and `Ctrl+Shift+P` for the command palette.

## workbench keys

- `Ctrl+B` toggles the primary side bar
- `Ctrl+Shift+E/F/G/D/X` opens Explorer, Search, Source Control, Run/Debug, or Extensions
- `Ctrl+P` opens files and `Ctrl+Shift+P` opens the command palette
- `Ctrl+,` opens settings and `Ctrl+K Ctrl+S` searches keyboard shortcuts
- `Ctrl+backtick` toggles the integrated terminal

Any terminal using the Kitty keyboard logic should automatically detected (eg: Ghostty, Alacritty).
I am doing this project on a 13 year old thinkpad while moving my studio 
so i will be able to test more throughly once i can use my main machine.

Please let me know what is broken or messed up and ill make time to fix it up :)
