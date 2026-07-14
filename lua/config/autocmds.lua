local group = vim.api.nvim_create_augroup("vscode_experience", { clear = true })

-- VS Code terminals are ready for input as soon as they open.
vim.api.nvim_create_autocmd("TermOpen", {
  group = group,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd.startinsert()
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "help", "qf", "checkhealth", "lspinfo", "notify", "startuptime" },
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Keep the Explorer visible on the left at startup, matching the default workbench.
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    if #vim.api.nvim_list_uis() > 0 then
      vim.schedule(function()
        require("vscode.sidebar").open_explorer()
      end)
    end
  end,
})
