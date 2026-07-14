-- NVICode: a standalone VS Code-like Neovim configuration. Plugins are fetched with
-- Neovim's native vim.pack API and configured by our integration modules.
require("config.options")
require("config.kitty").setup()
require("config.plugins").setup()
require("integrations").setup()
require("config.keymaps")
require("config.autocmds")
require("vscode.workbench").setup()
require("vscode.sidebar").setup()
