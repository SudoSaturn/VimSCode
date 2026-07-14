# Store-managed extensions

`store.nvim` writes native `vim.pack` installation snippets into this directory.
The core configuration loads every `*.lua` file here in alphabetical order.

Core product integrations remain in `lua/config/plugins.lua` and
`lua/integrations/`; this directory is only for extensions installed from the
`:Store` marketplace.
