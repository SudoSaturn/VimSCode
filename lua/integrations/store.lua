local M = {}

function M.setup()
  require("store").setup({
    layout = "tab",
    plugin_manager = "vim.pack",
    plugins_folder = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "extensions"),
    telemetry = false,
  })
end

function M.open()
  vim.cmd.Store()
end

return M
