local M = {}

local function github(repo)
  return "https://github.com/" .. repo
end

local plugins = {
  -- Shared libraries must be available before their consumers are configured.
  github("nvim-lua/plenary.nvim"),
  github("nvim-tree/nvim-web-devicons"),
  github("nvim-neotest/nvim-nio"),
  github("saghen/blink.lib"),
  github("rafamadriz/friendly-snippets"),

  -- VS Code workbench and editor surfaces.
  github("Mofiqul/vscode.nvim"),
  github("folke/snacks.nvim"),
  github("akinsho/bufferline.nvim"),
  github("nvim-lualine/lualine.nvim"),
  github("folke/which-key.nvim"),
  { src = github("mg979/vim-visual-multi"), version = "master" },
  github("folke/tokyonight.nvim"),
  { src = github("catppuccin/nvim"), name = "catppuccin" },

  -- Language intelligence and editing.
  github("nvim-treesitter/nvim-treesitter"),
  github("saghen/blink.cmp"),
  github("mason-org/mason.nvim"),
  github("mason-org/mason-lspconfig.nvim"),
  github("neovim/nvim-lspconfig"),
  github("b0o/SchemaStore.nvim"),
  github("stevearc/conform.nvim"),
  github("echasnovski/mini.pairs"),
  github("folke/ts-comments.nvim"),
  github("windwp/nvim-ts-autotag"),
  github("lewis6991/gitsigns.nvim"),
  github("MagicDuck/grug-far.nvim"),
  github("folke/trouble.nvim"),
  github("folke/todo-comments.nvim"),
  github("folke/persistence.nvim"),

  -- Debug adapter integration.
  github("mfussenegger/nvim-dap"),
  github("rcarriga/nvim-dap-ui"),
  github("theHamsta/nvim-dap-virtual-text"),
  github("jay-babu/mason-nvim-dap.nvim"),

  -- Native extension marketplace and README rendering.
  github("OXY2DEV/markview.nvim"),
  github("alex-popov-tech/store.nvim"),
}

local function load_store_extensions()
  local directory = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "extensions")
  vim.fn.mkdir(directory, "p")

  local files = vim.fn.glob(vim.fs.joinpath(directory, "*.lua"), false, true)
  table.sort(files)
  for _, file in ipairs(files) do
    local ok, err = pcall(dofile, file)
    if not ok then
      vim.notify("Unable to load extension " .. vim.fn.fnamemodify(file, ":t") .. ":\n" .. err, vim.log.levels.ERROR)
    end
  end
end

function M.setup()
  if not vim.pack then
    error("nvim-vscode requires Neovim with vim.pack support")
  end

  -- vim-visual-multi reads these while its plugin scripts are sourced.
  vim.g.VM_maps = {
    ["Find Under"] = "<C-d>",
    ["Find Subword Under"] = "<C-d>",
    ["Select All"] = "<C-S-l>",
    ["Add Cursor Down"] = "<C-A-Down>",
    ["Add Cursor Up"] = "<C-A-Up>",
  }
  vim.g.VM_theme = "iceblue"

  -- Native Neovim package management with immediate access to core modules.
  vim.pack.add(plugins, { confirm = false, load = true })
  load_store_extensions()
end

return M
