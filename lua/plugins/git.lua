local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git" })
end

-- Runs a command in the current tab's cwd and calls back on the main loop.
local function run(cmd, cb)
  vim.system(cmd, { text = true, cwd = vim.fn.getcwd() }, vim.schedule_wrap(cb))
end

local function float_terminal(cmd)
  Snacks.terminal.open(cmd, {
    cwd = vim.fn.getcwd(),
    auto_close = false,
    win = { position = "float", width = 0.9, height = 0.9, border = "rounded" },
  })
end

-- The PR shown in the current Octo buffer, if any. Without one, gh uses the current branch's PR.
local function octo_pr()
  local ok, utils = pcall(require, "octo.utils")
  if not ok then
    return nil
  end
  local buffer = utils.get_current_buffer()
  if buffer and buffer:isPullRequest() then
    return { number = tostring(buffer.number), repo = buffer.repo }
  end
end

local function pr_args(pr)
  if not pr then
    return {}
  end
  return { pr.number, "--repo", pr.repo }
end

local function pr_view(fields, cb)
  local pr = octo_pr()
  local cmd = vim.list_extend({ "gh", "pr", "view" }, pr_args(pr))
  vim.list_extend(cmd, { "--json", table.concat(fields, ",") })
  run(cmd, function(res)
    if res.code ~= 0 then
      notify("No pull request found for this branch", vim.log.levels.WARN)
      return
    end
    cb(vim.json.decode(res.stdout), pr)
  end)
end

-- Fetches the PR's base branch (or the repo's default branch) and opens the full PR diff,
-- including uncommitted changes, with real files on the right so LSP works.
local function diff_against_base()
  notify("Fetching base branch…")
  run({ "gh", "pr", "view", "--json", "baseRefName", "-q", ".baseRefName" }, function(res)
    local base = res.code == 0 and vim.trim(res.stdout) or ""
    if base == "" then
      local ref = vim.fn.systemlist({ "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })[1]
      base = vim.v.shell_error == 0 and ref and ref:gsub("^origin/", "") or "main"
    end
    run({ "git", "fetch", "origin", base }, function(fetch)
      if fetch.code ~= 0 then
        notify("Fetch failed, diffing against the local origin/" .. base, vim.log.levels.WARN)
      end
      vim.cmd(("DiffviewOpen origin/%s...HEAD --imply-local"):format(base))
    end)
  end)
end

local function open_pr()
  pr_view({ "number" }, function(pr)
    vim.cmd("Octo pr edit " .. pr.number)
  end)
end

local function merge_pr()
  pr_view({ "number", "title", "baseRefName", "headRefName", "isDraft", "state", "isCrossRepository", "url" }, function(pr, octo)
    if pr.state ~= "OPEN" then
      notify(("PR #%d is %s"):format(pr.number, pr.state:lower()), vim.log.levels.WARN)
      return
    end
    if pr.isDraft then
      notify(("PR #%d is a draft. Mark it ready first (<leader>gR)."):format(pr.number), vim.log.levels.WARN)
      return
    end
    local question = ("Squash-merge #%d into %s and delete its remote branch?\n%s"):format(pr.number, pr.baseRefName, pr.title)
    if vim.fn.confirm(question, "&Yes\n&No", 2) ~= 1 then
      return
    end
    notify(("Merging #%d…"):format(pr.number))
    local repo = pr.url:match("github%.com/([^/]+/[^/]+)/pull/")
    -- Merge by number and delete only the remote branch: T3 owns the local branch and its worktree.
    run({ "gh", "pr", "merge", tostring(pr.number), "--squash", "--repo", repo }, function(res)
      if res.code ~= 0 then
        notify("Merge failed:\n" .. vim.trim(res.stderr), vim.log.levels.ERROR)
        return
      end
      notify(("Merged #%d into %s"):format(pr.number, pr.baseRefName))
      if not pr.isCrossRepository then
        run({ "gh", "api", "-X", "DELETE", ("repos/%s/git/refs/heads/%s"):format(repo, pr.headRefName) }, function() end)
      end
      if octo then
        vim.cmd("Octo pr reload")
      end
    end)
  end)
end

local function mark_ready()
  local cmd = vim.list_extend({ "gh", "pr", "ready" }, pr_args(octo_pr()))
  run(cmd, function(res)
    if res.code ~= 0 then
      notify(vim.trim(res.stderr), vim.log.levels.WARN)
    else
      notify("Marked ready for review")
    end
  end)
end

local function pr_checks()
  if octo_pr() then
    vim.cmd("Octo pr checks")
  else
    float_terminal({ "gh", "pr", "checks", "--watch" })
  end
end

local function show_log(title, text)
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, title)
  local lines = vim.split(text:gsub("\27%[[%d;]*m", ""), "\n", { trimempty = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
  vim.cmd("normal! G")
end

-- Looks at every workflow run for the branch's latest commit: shows failed logs,
-- watches a run still in progress, or reports that all passed.
local function ci_status()
  local branch = vim.trim(vim.fn.system({ "git", "branch", "--show-current" }))
  if vim.v.shell_error ~= 0 or branch == "" then
    notify("Not on a branch", vim.log.levels.WARN)
    return
  end
  run({ "gh", "run", "list", "--branch", branch, "--limit", "20", "--json", "databaseId,headSha,status,conclusion,workflowName" }, function(res)
    if res.code ~= 0 then
      notify(vim.trim(res.stderr), vim.log.levels.WARN)
      return
    end
    local runs = vim.json.decode(res.stdout)
    if #runs == 0 then
      notify("No workflow runs for " .. branch, vim.log.levels.WARN)
      return
    end
    local sha = runs[1].headSha
    local failed, running, total = {}, nil, 0
    for _, r in ipairs(runs) do
      if r.headSha == sha then
        total = total + 1
        if r.status ~= "completed" then
          running = running or r
        elseif r.conclusion ~= "success" and r.conclusion ~= "skipped" and r.conclusion ~= "neutral" then
          table.insert(failed, r)
        end
      end
    end

    if #failed > 0 then
      local chunks, pending = {}, #failed
      for i, r in ipairs(failed) do
        run({ "gh", "run", "view", tostring(r.databaseId), "--log-failed" }, function(log)
          chunks[i] = ("# %s (%s)\n%s"):format(r.workflowName, r.conclusion, log.code == 0 and log.stdout or log.stderr)
          pending = pending - 1
          if pending == 0 then
            show_log("CI failures: " .. branch, table.concat(chunks, "\n"))
          end
        end)
      end
    elseif running then
      float_terminal({ "gh", "run", "watch", tostring(running.databaseId) })
    else
      notify(("All %d workflow runs passed on %s"):format(total, sha:sub(1, 7)))
    end
  end)
end

local function copy_permalink()
  Snacks.gitbrowse({
    what = "permalink",
    notify = false,
    open = function(url)
      vim.fn.setreg("+", url)
      notify("Copied " .. url)
    end,
  })
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
      { "<leader>gD", diff_against_base, desc = "Diff branch vs PR base" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gG", function() Snacks.terminal.toggle("gh dash", { win = { position = "float", width = 0.95, height = 0.95, border = "rounded" } }) end, desc = "GitHub dashboard" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Changed files" },
      { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git log" },
      { "<leader>go", function() Snacks.gitbrowse() end, desc = "Open in GitHub", mode = { "n", "x" } },
      { "<leader>yp", copy_permalink, desc = "Copy GitHub permalink", mode = { "n", "x" } },
      { "<leader>ga", ci_status, desc = "CI status / failed logs" },
    },
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim", "nvim-mini/mini.icons" },
    opts = {
      picker = "snacks",
      enable_builtin = true,
      default_merge_method = "squash",
      mappings = {
        pull_request = { approve_pr = { lhs = "<localleader>pa", desc = "approve PR" } },
      },
    },
    config = function(_, opts)
      require("octo").setup(opts)
      vim.treesitter.language.register("markdown", "octo")
    end,
    keys = {
      { "<leader>gp", "<cmd>Octo pr list<cr>", desc = "GitHub PRs" },
      { "<leader>gP", open_pr, desc = "Open this branch's PR" },
      { "<leader>gr", "<cmd>Octo review<cr>", desc = "Review PR" },
      { "<leader>gc", pr_checks, desc = "PR checks" },
      { "<leader>gR", mark_ready, desc = "Mark PR ready" },
      { "<leader>gm", merge_pr, desc = "Squash-merge PR" },
      { "<leader>gO", "<cmd>Octo<cr>", desc = "Octo actions" },
    },
  },
}
