local M = {}

local blue = "#007acc"
local dark = "#1e1e1e"
local panel = "#252526"
local tab = "#2d2d2d"
local text = "#cccccc"

local function setup_colorscheme()
  require("vscode").setup({
    style = "dark",
    transparent = false,
    italic_comments = true,
    underline_links = true,
    disable_nvimtree_bg = true,
    terminal_colors = true,
    color_overrides = {
      vscBack = dark,
      vscTabCurrent = dark,
      vscTabOther = tab,
      vscLeftDark = "#181818",
      vscPopupBack = panel,
    },
  })
  vim.cmd.colorscheme("vscode")
end

local function setup_snacks()
  require("snacks").setup({
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = true },
    indent = { enabled = true, char = "│", scope = { enabled = true, char = "│" } },
    input = { enabled = true },
    notifier = { enabled = true, style = "compact", top_down = false },
    picker = {
      enabled = true,
      prompt = "  > ",
      ui_select = true,
      sources = {
        explorer = {
          auto_close = false,
          follow_file = true,
          hidden = true,
          layout = { preset = "sidebar", layout = { position = "left", width = 38 } },
          win = {
            list = {
              keys = {
                ["<C-b>"] = "close",
                ["<C-S-e>"] = "close",
                ["<F2>"] = "explorer_rename",
                ["<C-n>"] = "explorer_add",
                ["<C-c>"] = "explorer_copy",
                ["<C-x>"] = "explorer_move",
                ["<C-v>"] = "explorer_paste",
                ["<Delete>"] = "explorer_del",
              },
            },
          },
        },
        files = { layout = { preset = "vscode" } },
        commands = { layout = { preset = "vscode" } },
        buffers = { layout = { preset = "vscode" } },
        lsp_symbols = { layout = { preset = "vscode" } },
        lsp_workspace_symbols = { layout = { preset = "vscode" } },
      },
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    terminal = { enabled = true, win = { position = "bottom", height = 0.32, border = "top" } },
    words = { enabled = true },
    zen = { enabled = true },
  })
  Snacks.input.enable()
  vim.ui.select = Snacks.picker.select
end

local function setup_bufferline()
  require("bufferline").setup({
    options = {
      always_show_bufferline = true,
      close_command = function(bufnr)
        Snacks.bufdelete(bufnr)
      end,
      diagnostics = "nvim_lsp",
      enforce_regular_tabs = true,
      indicator = { icon = "", style = "icon" },
      modified_icon = "●",
      separator_style = { "", "" },
      show_buffer_close_icons = true,
      show_close_icon = false,
      truncate_names = false,
    },
    highlights = {
      fill = { bg = "#181818" },
      background = { fg = "#969696", bg = tab },
      buffer_selected = { fg = "#ffffff", bg = dark, bold = false, italic = false },
      close_button = { fg = "#969696", bg = tab },
      close_button_selected = { fg = "#ffffff", bg = dark },
      diagnostic = { bg = tab },
      diagnostic_selected = { bg = dark, italic = false },
      modified = { fg = "#e2c08d", bg = tab },
      modified_selected = { fg = "#e2c08d", bg = dark },
      separator = { fg = tab, bg = tab },
      separator_selected = { fg = dark, bg = dark },
    },
  })
end

local function mode_theme()
  local function section()
    return { fg = "#ffffff", bg = blue }
  end
  return {
    normal = { a = section(), b = section(), c = section() },
    insert = { a = section(), b = section(), c = section() },
    visual = { a = section(), b = section(), c = section() },
    replace = { a = section(), b = section(), c = section() },
    command = { a = section(), b = section(), c = section() },
    inactive = {
      a = { fg = text, bg = panel },
      b = { fg = text, bg = panel },
      c = { fg = text, bg = panel },
    },
  }
end

local function setup_lualine()
  require("lualine").setup({
    options = {
      component_separators = "",
      globalstatus = true,
      section_separators = "",
      theme = mode_theme(),
    },
    sections = {
      lualine_a = {
        {
          "mode",
          fmt = function(value)
            return value:sub(1, 1)
          end,
        },
      },
      lualine_b = { { "branch", icon = "" }, "diff" },
      lualine_c = {
        { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " } },
      },
      lualine_x = { "filetype", "encoding" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    inactive_sections = { lualine_c = { "filename" }, lualine_x = { "location" } },
  })
end

local function setup_which_key()
  require("which-key").setup({
    delay = 450,
    preset = "modern",
    spec = {
      { "<leader><space>", desc = "Quick Open" },
      { "<leader>,", desc = "Open Editors" },
      { "<leader>/", desc = "Find in Files" },
      { "<leader>e", desc = "Explorer" },
      { "<leader>b", group = "Editors" },
      { "<leader>c", group = "Code" },
      { "<leader>f", group = "File" },
      { "<leader>g", group = "Source Control" },
      { "<leader>q", group = "Window" },
      { "<leader>s", group = "Search and Preferences" },
      { "<leader>u", group = "View" },
      { "<leader>x", group = "Problems" },
      { "<leader>w", group = "Editor Groups" },
    },
  })
end

function M.setup()
  setup_colorscheme()
  setup_snacks()
  setup_bufferline()
  setup_lualine()
  setup_which_key()
end

return M
