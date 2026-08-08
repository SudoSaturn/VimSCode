local M = {}

local function setup_colorscheme()
  -- Use Kitty's live terminal palette when it is available.
  require("vscode.theme").setup()
end

local function setup_snacks()
  require("nvim-web-devicons").setup({
    color_icons = true,
    default = true,
  })
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
          layout = {
            preview = false,
            layout = {
              position = "left",
              width = 38,
              box = "vertical",
              { win = "input", height = 1, border = "none" },
              { win = "list", border = "none" },
              { win = "preview", title = "{preview}", height = 0.4, border = "top" },
            },
          },
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
    terminal = {
      enabled = true,
      win = {
        position = "bottom",
        height = 0.32,
        on_win = function(self)
          vim.wo[self.win].winbar = ""
        end,
      },
    },
    words = { enabled = true },
    zen = { enabled = true },
  })
  Snacks.input.enable()
  vim.ui.select = Snacks.picker.select
end

local function workbench_layout()
  local editor_column
  local has_sidebar = false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buffer = vim.api.nvim_win_get_buf(win)
    local config = vim.api.nvim_win_get_config(win)
    local filetype = vim.bo[buffer].filetype
    has_sidebar = has_sidebar or filetype == "snacks_layout_box" or filetype == "nvicode_extensions_header"
    if config.relative == "" and vim.bo[buffer].buftype == "" then
      local column = vim.api.nvim_win_get_position(win)[2]
      editor_column = not editor_column and column or math.min(editor_column, column)
    end
  end
  return editor_column or 0, has_sidebar
end

local function setup_bufferline()
  require("bufferline").setup({
    options = {
      always_show_bufferline = true,
      close_command = function(bufnr)
        Snacks.bufdelete(bufnr)
      end,
      custom_areas = {
        left = function()
          local width, has_sidebar = workbench_layout()
          if width == 0 then
            return {}
          end
          local palette = require("vscode.theme").palette()
          local title = has_sidebar and vim.g.nvicode_sidebar_title or ""
          if title == "" then
            return { { text = string.rep(" ", width), fg = palette.background, bg = palette.background } }
          end
          local icon = vim.g.nvicode_sidebar_icon or ""
          local prefix = string.rep(" ", 5) .. icon .. " "
          local used = vim.fn.strdisplaywidth(prefix .. title)
          local rule = math.max(width - used - 1, 0)
          local rule_text = rule > 0 and string.rep("─", rule - 1) .. "╮" or ""
          return {
            { text = prefix, fg = palette.accent, bg = palette.background },
            { text = title, fg = palette.foreground, bg = palette.background, bold = true },
            { text = " " .. rule_text, fg = palette.separator, bg = palette.background },
          }
        end,
        right = function()
          local palette = require("vscode.theme").palette()
          return {
            { text = "%@v:lua.VimSCodeToggleTerminalPanel@ 󰆍 %T", fg = palette.muted, bg = palette.background },
          }
        end,
      },
      custom_filter = function(bufnr)
        local filetype = vim.bo[bufnr].filetype
        return vim.bo[bufnr].buftype == "" and not filetype:match("^snacks_") and not filetype:match("^nvicode_")
      end,
      color_icons = false,
      diagnostics = "nvim_lsp",
      enforce_regular_tabs = true,
      get_element_icon = function(element)
        local icon = require("nvim-web-devicons").get_icon(vim.fn.fnamemodify(element.path, ":t"), element.extension, {
          default = true,
        })
        return icon
      end,
      indicator = { icon = "", style = "icon" },
      modified_icon = "●",
      separator_style = { "", "" },
      show_buffer_close_icons = true,
      show_close_icon = false,
      truncate_names = false,
    },
  })
end

local function setup_lualine()
  require("lualine").setup({
    options = {
      component_separators = "",
      globalstatus = true,
      section_separators = "",
      theme = "auto",
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
  require("vscode.theme").apply()
  setup_lualine()
  setup_which_key()
end

return M
