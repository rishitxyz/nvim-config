return {
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        background = { dark = "dragon" },
        colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
      })
      vim.cmd.colorscheme("kanagawa")
    end,
  },
  {
    "nvim-mini/mini.icons",
    lazy = true,
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
    opts = {},
  },
  {
    "nvim-mini/mini.statusline",
    lazy = false,
    dependencies = { "nvim-mini/mini.icons" },
    opts = {},
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hunk" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "tabs" },
        { "<leader>u", group = "toggle" },
      },
    },
  },
}
