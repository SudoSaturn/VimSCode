local M = {}

local treesitter_filetypes = {
  "bash",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "lua",
  "markdown",
  "python",
  "typescript",
  "typescriptreact",
  "yaml",
}

local function setup_treesitter()
  require("nvim-treesitter").install({
    "bash",
    "html",
    "javascript",
    "json",
    "json5",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "regex",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("standalone_treesitter", { clear = true }),
    pattern = treesitter_filetypes,
    callback = function()
      pcall(vim.treesitter.start)
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
  })
end

local function setup_completion()
  require("blink.cmp").setup({
    keymap = { preset = "super-tab" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 300 },
      menu = { border = "rounded", draw = { treesitter = { "lsp" } } },
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "lua" },
  })
end

local function setup_lsp()
  require("mason").setup({ ui = { border = "rounded", width = 0.8, height = 0.8 } })

  local capabilities = require("blink.cmp").get_lsp_capabilities()
  vim.lsp.config("*", { capabilities = capabilities })
  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        completion = { callSnippet = "Replace" },
        diagnostics = { globals = { "Snacks", "vim" } },
        workspace = { checkThirdParty = false },
      },
    },
  })
  vim.lsp.config("jsonls", {
    settings = {
      json = {
        schemas = require("schemastore").json.schemas(),
        validate = { enable = true },
      },
    },
  })
  vim.lsp.config("basedpyright", {
    settings = { basedpyright = { analysis = { typeCheckingMode = "standard" } } },
  })
  vim.lsp.config("vtsls", {})

  require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "jsonls", "basedpyright", "vtsls" },
    automatic_enable = true,
  })

  vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    update_in_insert = false,
    virtual_text = { spacing = 4, source = "if_many" },
    float = { border = "rounded", source = true },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = " ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = " ",
        [vim.diagnostic.severity.HINT] = "󰌵 ",
      },
    },
  })
end

local function setup_formatting()
  require("conform").setup({
    formatters_by_ft = {
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      lua = { "stylua" },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      python = { "ruff_format" },
      sh = { "shfmt" },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
    },
    default_format_opts = { lsp_format = "fallback" },
  })
end

local function setup_editor_tools()
  require("mini.pairs").setup()
  require("ts-comments").setup()
  require("nvim-ts-autotag").setup()
  require("gitsigns").setup({
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
  })
  require("grug-far").setup({ windowCreationCommand = "botright split" })
  require("trouble").setup({ focus = true })
  require("todo-comments").setup()
  require("persistence").setup({ options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" } })
end

function M.setup()
  setup_treesitter()
  setup_completion()
  setup_lsp()
  setup_formatting()
  setup_editor_tools()
end

return M
