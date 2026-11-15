return {
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    opts = {
      window = { margin = { vertical = 0, horizontal = 1 }, zindex = 10 },
      hide = { cursorline = "smart", only_win = true },
      render = function(props)
        local file = vim.api.nvim_buf_get_name(props.buf)
        if file == "" then return "[No Name]" end
        local root = vim.fs.root(props.buf, ".git")
        local path = root and vim.fs.relpath(root, file) or vim.fn.fnamemodify(file, ":~")
        return { { path, gui = props.focused and "bold" or nil }, vim.bo[props.buf].modified and " [+]" or "" }
      end,
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    config = function()
      require("rose-pine").setup({ variant = "main", dark_variant = "main" })
      vim.cmd.colorscheme("rose-pine")
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
        { "<leader>q", group = "session" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "tabs" },
        { "<leader>u", group = "toggle" },
        { "<leader>y", group = "copy" },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "octo" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    opts = { file_types = { "markdown", "octo" } },
  },
}
