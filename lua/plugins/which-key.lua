return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 450,
      preset = "modern",
      spec = {
        { "<leader><space>", desc = "Quick Open" },
        { "<leader>,", desc = "Open Editors" },
        { "<leader>/", desc = "Find in Files" },
        { "<leader>e", desc = "Explorer" },
        { "<leader>b", group = "Editors" },
        { "<leader>c", group = "Code" },
        { "<leader>d", group = "Run and Debug" },
        { "<leader>f", group = "File" },
        { "<leader>g", group = "Source Control" },
        { "<leader>q", group = "Window" },
        { "<leader>s", group = "Search and Preferences" },
        { "<leader>u", group = "View" },
        { "<leader>x", group = "Problems" },
        { "<leader>w", group = "Editor Groups" },
      },
    },
  },
}
