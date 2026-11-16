-- Lets `bin/nvim-review` (run by agents) open diffs, files and PR conversations in this Neovim.
-- Each UI instance listens on stdpath("state")/sockets/<pid>.sock, and `last`
-- points at the most recently focused one.
local M = {}

local sock_dir = vim.fn.stdpath("state") .. "/sockets"
local last_file = sock_dir .. "/last"
local last_neovide_file = sock_dir .. "/last-neovide"
local window_script = vim.fn.stdpath("config") .. "/bin/ghostty-window.js"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Review" })
end

-- Diffs get a maximized Ghostty window; the old size comes back when the last diff closes.
-- The window is found by a title marker unique to this Neovim.
local title_marker ---@type string?
local saved_bounds ---@type string?
local open_diffs = 0
local warned = false
local ui_ready = false
local after_ui = {} ---@type fun()[]

local function ghostty_window(action, arg, on_done, attempt)
  if not ui_ready then
    -- A diff requested at startup opens before the UI attaches and sets the window title.
    table.insert(after_ui, function()
      ghostty_window(action, arg, on_done)
    end)
    return
  end
  if not title_marker then
    return
  end
  attempt = attempt or 1
  vim.system({ "osascript", "-l", "JavaScript", window_script, title_marker, action, arg }, { text = true }, vim.schedule_wrap(function(res)
    local out = vim.trim(res.stdout or "")
    if out:match("^error: no Ghostty window") and attempt < 10 then
      -- System Events briefly reports no windows while Ghostty is being activated,
      -- and a new window may not show its title yet.
      vim.defer_fn(function()
        ghostty_window(action, arg, on_done, attempt + 1)
      end, 300)
      return
    end
    if res.code ~= 0 or out:match("^error") then
      if not warned then
        warned = true
        local detail = vim.trim(out .. " " .. (res.stderr or ""))
        local denied = detail:match("assistive") or detail:match("%-1719") or detail:match("%-25211")
        local hint = denied and "Allow Ghostty under System Settings → Privacy & Security → Accessibility."
          or "Couldn't find this Neovim's Ghostty window."
        notify("Couldn't resize the window. " .. hint .. "\n" .. detail, vim.log.levels.WARN)
      end
      return
    end
    if on_done then
      on_done(out)
    end
  end))
end

function M.on_diff_opened()
  open_diffs = open_diffs + 1
  if open_diffs == 1 then
    ghostty_window("maximize", "", function(bounds)
      saved_bounds = bounds
    end)
  end
end

function M.on_diff_closed()
  open_diffs = math.max(open_diffs - 1, 0)
  if open_diffs == 0 and saved_bounds then
    local bounds = saved_bounds
    saved_bounds = nil
    ghostty_window("restore", bounds)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user_review", { clear = true })
  local path = sock_dir .. "/" .. vim.fn.getpid() .. ".sock"

  local function mark_last()
    local f = io.open(last_file, "w")
    if f then
      f:write(path)
      f:close()
    end
    if vim.g.neovide then
      local gui = io.open(last_neovide_file, "w")
      if gui then
        gui:write(path)
        gui:close()
      end
    end
  end

  -- Headless instances (plugin installs, scripts) never fire UIEnter, so they don't register.
  vim.api.nvim_create_autocmd("UIEnter", {
    group = group,
    once = true,
    callback = function()
      if not vim.g.neovide and vim.env.TERM_PROGRAM == "ghostty" and vim.fn.has("mac") == 1 then
        title_marker = "nvim " .. vim.fn.getpid()
        vim.o.title = true
        vim.o.titlestring = "%{fnamemodify(getcwd(), ':t')} · " .. title_marker
      end
      ui_ready = true
      for _, fn in ipairs(after_ui) do
        vim.schedule(fn)
      end
      after_ui = {}
      vim.fn.mkdir(sock_dir, "p")
      os.remove(path)
      if pcall(vim.fn.serverstart, path) then
        mark_last()
        vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = mark_last })
        vim.api.nvim_create_autocmd("VimLeavePre", {
          group = group,
          callback = function()
            os.remove(path)
          end,
        })
      end
    end,
  })
end

local function tab_is_empty()
  return vim.api.nvim_buf_get_name(0) == "" and not vim.bo.modified and vim.fn.winnr("$") == 1
end

local function has_diffview(tabnr)
  for _, buf in ipairs(vim.fn.tabpagebuflist(tabnr)) do
    if vim.api.nvim_buf_get_name(buf):match("^diffview://") then
      return true
    end
  end
  return false
end

-- The tab opened earlier for the same diff or PR conversation, if any.
local function labeled_tab(spec)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tab)
    if vim.fn.gettabvar(nr, "review_label", "") == spec.label and vim.fn.getcwd(-1, nr) == spec.dir then
      return tab
    end
  end
end

-- A plain editing tab (not a diff or PR tab) already scoped to dir, if any.
local function editing_tab(dir)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tab)
    if vim.fn.getcwd(-1, nr) == dir and vim.fn.gettabvar(nr, "review_label", "") == "" and not has_diffview(nr) then
      return tab
    end
  end
end

-- Runs open() in a tab of its own for spec.dir. Replaces the tab from an earlier request for the
-- same thing, and closes the empty tab a fresh Neovim starts with.
local function in_own_tab(spec, close_previous, open)
  local previous = labeled_tab(spec)
  if previous then
    vim.api.nvim_set_current_tabpage(previous)
    close_previous()
  end
  local empty_tab = tab_is_empty() and vim.api.nvim_get_current_tabpage() or nil
  open()
  vim.cmd.tcd(vim.fn.fnameescape(spec.dir))
  vim.t.review_label = spec.label
  local current = vim.api.nvim_get_current_tabpage()
  if empty_tab and empty_tab ~= current and vim.api.nvim_tabpage_is_valid(empty_tab) then
    vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(empty_tab))
  end
end

---@class ReviewDiffSpec
---@field dir string repo or worktree root
---@field base string ref to diff from, e.g. "origin/main"
---@field head string ref to diff to, "HEAD" for the working tree
---@field local_mode boolean right side is the files on disk (uncommitted changes included)
---@field label string tab label, e.g. "PR #512"

---@param spec ReviewDiffSpec
function M.open_diff(spec)
  require("lazy").load({ plugins = { "diffview.nvim" } })
  in_own_tab(spec, function()
    vim.cmd("DiffviewClose")
  end, function()
    local args = { "-C" .. vim.fn.fnameescape(spec.dir), spec.base .. "..." .. spec.head }
    if spec.local_mode then
      table.insert(args, "--imply-local")
    end
    vim.cmd("DiffviewOpen " .. table.concat(args, " "))
  end)
  notify(("%s: %s...%s"):format(spec.label, spec.base, spec.head))
end

---@class ReviewCommentsSpec
---@field dir string repo root, or any directory when the repo isn't cloned
---@field repo string "owner/name"
---@field pr string
---@field label string

---@param spec ReviewCommentsSpec
function M.open_comments(spec)
  require("lazy").load({ plugins = { "octo.nvim" } })
  in_own_tab(spec, function()
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd.tabclose()
    end
  end, function()
    if not tab_is_empty() then
      vim.cmd.tabnew()
    end
    vim.cmd.edit(("octo://%s/pull/%s"):format(spec.repo, spec.pr))
  end)
end

---@class ReviewFilesSpec
---@field dir string repo root of the first file
---@field files { path: string, line: integer }[] absolute paths; line 0 means "don't move"

---@param spec ReviewFilesSpec
function M.open_files(spec)
  local tab = editing_tab(spec.dir)
  if tab then
    vim.api.nvim_set_current_tabpage(tab)
  elseif not tab_is_empty() then
    vim.cmd.tabnew()
  end
  vim.cmd.tcd(vim.fn.fnameescape(spec.dir))

  for i, file in ipairs(spec.files) do
    local shown
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == file.path then
        shown = win
        break
      end
    end
    if shown then
      vim.api.nvim_set_current_win(shown)
    elseif i == 1 then
      vim.cmd.edit(vim.fn.fnameescape(file.path))
    else
      vim.cmd.vsplit(vim.fn.fnameescape(file.path))
    end
    if file.line > 0 then
      pcall(vim.api.nvim_win_set_cursor, 0, { file.line, 0 })
      vim.cmd("normal! zz")
    end
  end
  notify("Opened " .. table.concat(vim.tbl_map(function(f)
    return vim.fn.fnamemodify(f.path, ":.") .. (f.line > 0 and ":" .. f.line or "")
  end, spec.files), ", "))
end

local handlers = { diff = M.open_diff, comments = M.open_comments, files = M.open_files }

-- Entry point for `nvim --remote-expr`: reads the spec from a JSON file so nothing needs shell quoting.
---@param path string
function M.open_file(path)
  local ok, spec = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  os.remove(path)
  if not ok then
    return "error: could not read " .. path
  end
  local handler = handlers[spec.kind or "diff"]
  if not handler then
    return "error: unknown kind " .. tostring(spec.kind)
  end
  -- Defer so the RPC call returns before tabs and windows change.
  vim.schedule(function()
    local opened, err = pcall(handler, spec)
    if not opened then
      notify("Could not open: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
  return "ok"
end

return M
