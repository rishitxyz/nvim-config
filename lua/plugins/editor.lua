-- Opens a repo in its own tab (reusing the current tab if it is empty)
-- and scopes the tab's cwd to it, so pickers and git commands stay in that repo.
local function open_project()
  Snacks.picker.projects({
    dev = vim.fn.glob(vim.fn.expand("~/dev/*"), false, true),
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      local empty = vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified and vim.fn.winnr("$") == 1
      if not empty then
        vim.cmd.tabnew()
      end
      vim.cmd.tcd(vim.fn.fnameescape(item.file))
      Snacks.picker.files()
    end,
  })
end

return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 900,
    opts = {
      bigfile = { enabled = true },
      input = { enabled = true },
      lazygit = { enabled = true },
      notifier = { enabled = true },
      picker = {
        enabled = true,
        sources = { files = { hidden = true }, grep = { hidden = true } },
      },
    },
    keys = {
      { "<leader><space>", function() Snacks.picker.files() end, desc = "Find files" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fr", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent files" },
      { "<leader>fp", open_project, desc = "Open project in tab" },
      { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Grep word", mode = { "n", "x" } },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "Symbols" },
      { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace symbols" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sr", function() Snacks.picker.resume() end, desc = "Resume search" },
      { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Go to definition" },
      { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
      { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Go to implementation" },
      { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Go to type definition" },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-mini/mini.icons" },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      keymaps = { ["q"] = "actions.close" },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
  },
}
