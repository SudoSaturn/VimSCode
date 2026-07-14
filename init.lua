-- Standalone Neovim configuration powered by lazy.nvim (not LazyVim).
require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
require("vscode.workbench").setup()
