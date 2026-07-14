return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "dark",
      transparent = false,
      italic_comments = true,
      underline_links = true,
      disable_nvimtree_bg = true,
      terminal_colors = true,
      color_overrides = {
        vscBack = "#1e1e1e",
        vscTabCurrent = "#1e1e1e",
        vscTabOther = "#2d2d2d",
        vscLeftDark = "#181818",
        vscPopupBack = "#252526",
      },
    },
    config = function(_, opts)
      require("vscode").setup(opts)
      vim.cmd.colorscheme("vscode")
    end,
  },
  { "folke/tokyonight.nvim", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
}
