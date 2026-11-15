local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.cursorlineopt = "number"
opt.laststatus = 3
opt.showmode = false
opt.showtabline = 1
opt.winborder = "rounded"
opt.fillchars = { eob = " ", diff = "╱" }
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"

opt.splitright = true
opt.splitbelow = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false
opt.confirm = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.diffopt:append({ "algorithm:histogram", "inline:word" })
opt.sessionoptions = { "buffers", "curdir", "folds", "tabpages", "winsize" }

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { spacing = 2, prefix = "●" },
  float = {
    source = true,
    format = function(d)
      return d.code and ("%s [%s]"):format(d.message, d.code) or d.message
    end,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

-- One tab per repo: label each tab with its tab-local cwd.
function _G.repo_tabline()
  local parts = {}
  for i = 1, vim.fn.tabpagenr("$") do
    local hl = i == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#"
    local name = vim.fn.fnamemodify(vim.fn.getcwd(-1, i), ":t")
    local label = vim.fn.gettabvar(i, "review_label", "")
    if label ~= "" then
      name = name .. " · " .. label
    else
      for _, buf in ipairs(vim.fn.tabpagebuflist(i)) do
        if vim.api.nvim_buf_get_name(buf):match("^diffview://") then
          name = name .. " · diff"
          break
        end
      end
    end
    table.insert(parts, hl .. "%" .. i .. "T  " .. name .. "  ")
  end
  return table.concat(parts) .. "%#TabLineFill#%T"
end
opt.tabline = "%!v:lua.repo_tabline()"
