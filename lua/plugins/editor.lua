-- Opens a directory in its own tab (reusing the current tab if it is empty)
-- and scopes the tab's cwd to it, so pickers and git commands stay in that repo.
local function open_in_tab(dir)
  local empty = vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified and vim.fn.winnr("$") == 1
  if not empty then
    vim.cmd.tabnew()
  end
  vim.cmd.tcd(vim.fn.fnameescape(dir))
  Snacks.picker.files()
end

-- Repos live in ~/dev/<org>/<repo>; T3 puts agent worktrees under ~/.t3/worktrees.
local function project_roots()
  local home = vim.fn.expand("~")
  local roots = vim.fn.glob(home .. "/dev/*", false, true)
  local t3 = home .. "/.t3/worktrees"
  if vim.fn.isdirectory(t3) == 1 then
    table.insert(roots, t3)
    vim.list_extend(roots, vim.fn.glob(t3 .. "/*", false, true))
  end
  return vim.tbl_filter(function(dir)
    return vim.fn.isdirectory(dir) == 1
  end, roots)
end

local function open_project()
  Snacks.picker.projects({
    dev = project_roots(),
    patterns = { ".git" },
    confirm = function(picker, item)
      picker:close()
      if item then
        open_in_tab(item.file)
      end
    end,
  })
end

local function open_worktree()
  local lines = vim.fn.systemlist({ "git", "worktree", "list", "--porcelain" })
  if vim.v.shell_error ~= 0 then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end
  local items, current = {}, nil
  for _, line in ipairs(lines) do
    local path = line:match("^worktree (.+)")
    if path then
      current = { file = path, dir = true, branch = "(detached)" }
      table.insert(items, current)
    elseif current then
      current.branch = line:match("^branch refs/heads/(.+)") or current.branch
    end
  end
  for _, item in ipairs(items) do
    item.text = item.branch .. " " .. item.file
  end
  Snacks.picker({
    title = "Worktrees",
    items = items,
    layout = { preset = "select" },
    format = function(item)
      return { { item.branch, "Title" }, { "  " }, { vim.fn.fnamemodify(item.file, ":~"), "Comment" } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        open_in_tab(item.file)
      end
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
      indent = { enabled = true, animate = { enabled = false } },
      input = { enabled = true },
      lazygit = { enabled = true },
      notifier = { enabled = true },
      picker = {
        enabled = true,
        sources = { files = { hidden = true }, grep = { hidden = true } },
      },
      words = { enabled = true },
    },
    keys = {
      { "<leader><space>", function() Snacks.picker.files() end, desc = "Find files" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fr", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent files" },
      { "<leader>fp", open_project, desc = "Open project in tab" },
      { "<leader>fw", open_worktree, desc = "Open worktree in tab" },
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
      { "]]", function() Snacks.words.jump(1, true) end, desc = "Next reference" },
      { "[[", function() Snacks.words.jump(-1, true) end, desc = "Previous reference" },
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
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash jump" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash select" },
    },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    init = function()
      -- Diff, PR and terminal tabs can't be restored from a session file, so drop them before saving.
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        callback = function()
          for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
              local buf = vim.api.nvim_win_get_buf(win)
              local name = vim.api.nvim_buf_get_name(buf)
              if name:match("^diffview://") or name:match("^octo://") or vim.bo[buf].buftype == "terminal" then
                if #vim.api.nvim_list_tabpages() > 1 then
                  pcall(vim.cmd.tabclose, vim.api.nvim_tabpage_get_number(tab))
                end
                break
              end
            end
          end
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local name = vim.api.nvim_buf_get_name(buf)
            if name:match("^diffview://") or name:match("^octo://") then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
          end
        end,
      })
    end,
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session for this directory" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save this session" },
    },
  },
}
