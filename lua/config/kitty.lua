local M = {}

function M.setup()
  if vim.env.TERM ~= "xterm-kitty" then
    return
  end

  -- Neovim negotiates Kitty's progressive keyboard protocol itself. A short
  -- terminal timeout keeps Alt chords responsive without collapsing distinct
  -- Ctrl+Shift, Shift+Enter, Backspace, and Ctrl+/ key events.
  vim.opt.ttimeout = true
  vim.opt.ttimeoutlen = 10
  vim.g.vscode_kitty_keyboard = true

  vim.api.nvim_create_user_command("KittyKeys", function()
    local keys = { "<C-S-p>", "<C-S-e>", "<C-S-f>", "<C-`>", "<C-/>", "<A-S-Down>" }
    local lines = { "Kitty keyboard protocol: active", "TERM=" .. vim.env.TERM, "" }
    for _, key in ipairs(keys) do
      local mapping = vim.fn.maparg(key, "n", false, true)
      lines[#lines + 1] = string.format("%-14s %s", key, mapping.desc or "unmapped")
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "VS Code keybindings" })
  end, { desc = "Inspect Kitty-specific VS Code keybindings" })
end

return M
