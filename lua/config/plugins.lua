local M = {}

local function github(repo)
  return "https://github.com/" .. repo
end

local plugins = {
  github("nvim-lua/plenary.nvim"),
  github("nvim-tree/nvim-web-devicons"),
  github("saghen/blink.lib"),
  github("rafamadriz/friendly-snippets"),

  github("Mofiqul/vscode.nvim"),
  github("folke/snacks.nvim"),
  github("akinsho/bufferline.nvim"),
  github("nvim-lualine/lualine.nvim"),
  github("folke/which-key.nvim"),
  { src = github("mg979/vim-visual-multi"), version = "master" },
  github("folke/tokyonight.nvim"),
  { src = github("catppuccin/nvim"), name = "catppuccin" },

  { src = github("nvim-treesitter/nvim-treesitter"), version = "main" },
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

local function run_with_progress(plugins_list)
  local width = 60
  local win, buf
  local orig_echo = vim.api.nvim_echo
  
  local function init_win()
    if win then return end
    buf = vim.api.nvim_create_buf(false, true)
    local ok, w = pcall(vim.api.nvim_open_win, buf, true, {
      relative = "editor",
      width = width,
      height = 5,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - 5) / 2),
      style = "minimal",
      border = "rounded",
      title = " Downloading Plugins ",
      title_pos = "center",
      zindex = 250,
    })
    if ok then
      win = w
    end
  end

  local function update_bar(pct, name)
    init_win()
    local filled = math.floor((pct / 100) * (width - 4))
    local bar = "[" .. string.rep("=", filled) .. string.rep(" ", (width - 4) - filled) .. "]"
    local text = name and name ~= "" and ("Installing: " .. name) or (pct == 100 and "Done!" or "Starting...")
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "",
        "  " .. bar,
        "",
        "  " .. text
      })
      vim.cmd("redraw")
    end
  end

  vim.api.nvim_echo = function(chunks, history, opts)
    if opts and opts.kind == "progress" and opts.source == "vim.pack" then
      local pct = opts.percent or 0
      local msg = chunks[1] and chunks[1][1] or ""
      local name = msg:match("%(%d+/%d+%)%s*%-?%s*(.*)")
      update_bar(pct, name or "")
    else
      orig_echo(chunks, history, opts)
    end
  end
  
  local ok, err = pcall(vim.pack.add, plugins_list, { confirm = false, load = true })
  
  vim.api.nvim_echo = orig_echo
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  
  if not ok then
    error("Failed to install plugins: " .. tostring(err))
  end
end

function M.setup()
  if not vim.pack then
    error("VimSCode requires Neovim with vim.pack support")
  end

  vim.g.VM_maps = {
    ["Find Under"] = "<C-d>",
    ["Find Subword Under"] = "<C-d>",
    ["Select All"] = "<C-S-l>",
    ["Add Cursor Down"] = "<C-A-Down>",
    ["Add Cursor Up"] = "<C-A-Up>",
  }
  vim.g.VM_theme = "iceblue"

  run_with_progress(plugins)
  load_store_extensions()
end

return M
