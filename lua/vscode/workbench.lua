local M = {}

local function edit_config(file)
  vim.cmd.edit(vim.fs.joinpath(vim.fn.stdpath("config"), file))
end

function M.themes()
  Snacks.picker.colorschemes({ layout = { preset = "vscode" } })
end

function M.extensions()
  require("vscode.sidebar").open_extensions()
end

function M.settings()
  local choices = {
    { label = "Color Theme", action = M.themes },
    { label = "Extensions", action = M.extensions },
    {
      label = "Keyboard Shortcuts",
      action = function()
        Snacks.picker.keymaps()
      end,
    },
    {
      label = "Language Servers and Debuggers",
      action = function()
        vim.cmd.Mason()
      end,
    },
    {
      label = "Plugin Manager",
      action = function()
        vim.cmd.Lazy()
      end,
    },
    {
      label = "Edit Settings",
      action = function()
        edit_config("lua/config/options.lua")
      end,
    },
    {
      label = "Edit Keyboard Shortcuts",
      action = function()
        edit_config("lua/config/keymaps.lua")
      end,
    },
    {
      label = "Edit Extensions",
      action = function()
        edit_config("lua/plugins")
      end,
    },
    {
      label = "Toggle Word Wrap",
      action = function()
        vim.wo.wrap = not vim.wo.wrap
      end,
    },
    {
      label = "Toggle Minimap-like Scroll Column",
      action = function()
        vim.wo.colorcolumn = vim.wo.colorcolumn == "" and "80,120" or ""
      end,
    },
  }

  vim.ui.select(choices, {
    prompt = "Preferences",
    kind = "vscode_settings",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      item.action()
    end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("Themes", M.themes, { desc = "Browse installed color themes" })
  vim.api.nvim_create_user_command("Extensions", M.extensions, { desc = "Browse configured extensions" })
  vim.api.nvim_create_user_command("Settings", M.settings, { desc = "Open VS Code-style settings" })
end

return M
