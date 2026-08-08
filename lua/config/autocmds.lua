local group = vim.api.nvim_create_augroup("nvicode_experience", { clear = true })

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

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    local workspace = vim.fn.argc() == 0
    if not workspace then
      for index = 0, vim.fn.argc() - 1 do
        if vim.fn.isdirectory(vim.fn.argv(index)) == 1 then
          workspace = true
          break
        end
      end
    end
    if workspace and #vim.api.nvim_list_uis() > 0 then
      vim.schedule(function()
        require("vscode.sidebar").open_explorer()
      end)
    end
  end,
})
