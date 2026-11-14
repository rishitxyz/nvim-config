local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })

map("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "New tab" })
map("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "]t", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "[t", "<cmd>tabprevious<cr>", { desc = "Previous tab" })

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

local fence_lang = { typescriptreact = "tsx", javascriptreact = "jsx" }

-- Copies `path:start-end` (repo-relative) and, for a selection, the code in a fenced block,
-- ready to paste into an agent thread.
local function copy_reference()
  local file = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= "" or file == "" then
    vim.notify("Not a file on disk", vim.log.levels.WARN)
    return
  end
  local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
  local path = vim.fs.relpath(root, file) or vim.fn.fnamemodify(file, ":.")

  local first, last = vim.fn.line("."), vim.fn.line(".")
  local visual = vim.fn.mode():match("[vV\22]") ~= nil
  if visual then
    first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then
      first, last = last, first
    end
  end

  local ref = first == last and ("%s:%d"):format(path, first) or ("%s:%d-%d"):format(path, first, last)
  local text = ref
  if visual then
    local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
    local lang = fence_lang[vim.bo.filetype] or vim.bo.filetype
    text = ("%s\n```%s\n%s\n```"):format(ref, lang, table.concat(lines, "\n"))
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  end
  vim.fn.setreg("+", text)
  vim.notify("Copied " .. ref)
end

map({ "n", "x" }, "<leader>yr", copy_reference, { desc = "Copy code reference" })
