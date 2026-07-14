local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local output = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { output, "WarningMsg" },
    }, true, {})
    error("Unable to install lazy.nvim")
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Any normal lazy.nvim spec dropped into lua/plugins remains compatible.
  spec = { { import = "plugins" } },
  defaults = { lazy = true, version = false },
  install = { colorscheme = { "vscode", "habamax" } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  ui = {
    border = "rounded",
    backdrop = 100,
    title = " Extensions ",
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
