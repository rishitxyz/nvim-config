-- Resolves the remote's default branch (origin/main, origin/master, ...) for the current tab's repo.
local function default_branch()
  local out = vim.fn.systemlist({ "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]
  end
  for _, ref in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", ref })
    if vim.v.shell_error == 0 then
      return ref
    end
  end
end

local function diff_against_main()
  local base = default_branch()
  if not base then
    vim.notify("Could not find a main/master branch", vim.log.levels.WARN)
    return
  end
  vim.cmd("DiffviewOpen " .. base .. "...HEAD --imply-local")
end

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end
        map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Previous hunk")
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage lines")
        map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset lines")
        map("n", "<leader>hS", gs.stage_buffer, "Stage file")
        map("n", "<leader>hR", gs.reset_buffer, "Reset file")
        map("n", "<leader>hp", gs.preview_hunk_inline, "Preview hunk")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline blame")
        map({ "o", "x" }, "ih", gs.select_hunk, "Hunk")
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    opts = { enhanced_diff_hl = true },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff uncommitted changes" },
      { "<leader>gD", diff_against_main, desc = "Diff branch vs main (PR)" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Changed files" },
      { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
      { "<leader>go", function() Snacks.gitbrowse() end, desc = "Open in GitHub", mode = { "n", "x" } },
    },
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim", "nvim-mini/mini.icons" },
    opts = { picker = "snacks", enable_builtin = true },
    config = function(_, opts)
      require("octo").setup(opts)
      vim.treesitter.language.register("markdown", "octo")
    end,
    keys = {
      { "<leader>gp", "<cmd>Octo pr list<cr>", desc = "GitHub PRs" },
      { "<leader>gr", "<cmd>Octo review<cr>", desc = "Review current PR" },
      { "<leader>gO", "<cmd>Octo<cr>", desc = "Octo actions" },
    },
  },
}
