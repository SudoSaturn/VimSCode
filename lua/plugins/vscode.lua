local blue = "#007acc"
local dark = "#1e1e1e"
local panel = "#252526"
local tab = "#2d2d2d"
local text = "#cccccc"

return {
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      bigfile = { enabled = true },
      dashboard = {
        preset = {
          header = [[
                         ▄▄▄▄▄▄▄▄▄
                    ▄███████████████▄
                  ▄██████▀     ▀██████▄
                 █████▀    ▄▄    ▀█████
                 ████    ▄████▄    ████
                 ████▄  ████████  ▄████
                  █████▄ ▀████▀ ▄█████
                    ▀████▄▄  ▄▄████▀
                       ▀████████▀
                          CODE
]],
          keys = {
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "p", desc = "Quick Open", action = ":lua Snacks.picker.files()" },
            { icon = " ", key = "r", desc = "Open Recent", action = ":lua Snacks.picker.recent()" },
            { icon = " ", key = "e", desc = "Explorer", action = ":lua Snacks.explorer()" },
            { icon = " ", key = "f", desc = "Find in Files", action = ":lua Snacks.picker.grep()" },
            {
              icon = " ",
              key = "s",
              desc = "Restore Session",
              action = function()
                require("persistence").load()
              end,
            },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
      explorer = { enabled = true },
      indent = {
        enabled = true,
        char = "│",
        scope = { enabled = true, char = "│" },
      },
      input = { enabled = true },
      notifier = {
        enabled = true,
        style = "compact",
        top_down = false,
      },
      picker = {
        enabled = true,
        prompt = "  > ",
        ui_select = true,
        sources = {
          explorer = {
            auto_close = false,
            follow_file = true,
            hidden = true,
            layout = { preset = "sidebar", layout = { position = "left", width = 34 } },
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
    },
    config = function(_, opts)
      require("snacks").setup(opts)
      Snacks.input.enable()
      vim.ui.select = Snacks.picker.select
    end,
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
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
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        component_separators = "",
        globalstatus = true,
        section_separators = "",
        theme = {
          normal = {
            a = { fg = "#ffffff", bg = blue },
            b = { fg = "#ffffff", bg = blue },
            c = { fg = "#ffffff", bg = blue },
          },
          insert = {
            a = { fg = "#ffffff", bg = blue },
            b = { fg = "#ffffff", bg = blue },
            c = { fg = "#ffffff", bg = blue },
          },
          visual = {
            a = { fg = "#ffffff", bg = blue },
            b = { fg = "#ffffff", bg = blue },
            c = { fg = "#ffffff", bg = blue },
          },
          replace = {
            a = { fg = "#ffffff", bg = blue },
            b = { fg = "#ffffff", bg = blue },
            c = { fg = "#ffffff", bg = blue },
          },
          command = {
            a = { fg = "#ffffff", bg = blue },
            b = { fg = "#ffffff", bg = blue },
            c = { fg = "#ffffff", bg = blue },
          },
          inactive = { a = { fg = text, bg = panel }, b = { fg = text, bg = panel }, c = { fg = text, bg = panel } },
        },
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
    },
  },

  -- Ctrl+D adds the next matching selection; Ctrl+Shift+L selects every match.
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "VeryLazy",
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select All"] = "<C-S-l>",
        ["Add Cursor Down"] = "<C-A-Down>",
        ["Add Cursor Up"] = "<C-A-Up>",
      }
      vim.g.VM_theme = "iceblue"
    end,
  },
}
