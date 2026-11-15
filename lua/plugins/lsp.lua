return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      keymap = { preset = "enter" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      signature = { enabled = true },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        "ruff", -- basedpyright comes from Homebrew; Mason's pip install needs Python >= 3.10
        "vtsls", "eslint-lsp", "prettier",
        "rust-analyzer",
        "lua-language-server", "stylua",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            disableOrganizeImports = true,
            analysis = { typeCheckingMode = "standard" },
          },
        },
        -- Point the type checker at the project's .venv (uv/poetry default) when there is one.
        before_init = function(_, config)
          local python = config.root_dir and vim.fs.joinpath(config.root_dir, ".venv", "bin", "python")
          if python and vim.uv.fs_stat(python) then
            config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, { pythonPath = python })
          end
        end,
      })

      vim.lsp.config("vtsls", {
        settings = { vtsls = { autoUseWorkspaceTsdk = true } },
      })

      vim.lsp.config("rust_analyzer", {
        settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          map("<leader>cD", function()
            local win = vim.api.nvim_get_current_win()
            local source_client = vim.lsp.get_clients({ bufnr = ev.buf, name = "vtsls" })[1]
            if not source_client then
              vim.lsp.buf.definition()
              return
            end
            local encoding = source_client.offset_encoding or "utf-16"
            local params = vim.lsp.util.make_position_params(0, encoding)
            source_client:exec_cmd({
              command = "typescript.goToSourceDefinition",
              arguments = { params.textDocument.uri, params.position },
            }, { bufnr = ev.buf }, function(err, result)
              -- The response may arrive after a tab switch, buffer change, or window close.
              if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= ev.buf then
                return
              end
              if err then
                vim.notify(err.message, vim.log.levels.ERROR)
              elseif result and #result > 0 then
                vim.api.nvim_win_call(win, function()
                  vim.lsp.util.show_document(result[1], encoding, { focus = true })
                end)
              else
                vim.notify("No source definition found")
              end
            end)
          end, "Go to source definition")
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>uh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
          end, "Toggle inlay hints")
        end,
      })

      vim.lsp.enable({ "basedpyright", "ruff", "vtsls", "eslint", "rust_analyzer", "lua_ls" })
    end,
  },
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
        rust = { "rustfmt" },
        lua = { "stylua" },
        javascript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
        json = { "biome", "prettier", stop_after_first = true },
        jsonc = { "biome", "prettier", stop_after_first = true },
        css = { "prettier" },
        html = { "prettier" },
        yaml = { "prettier" },
      },
      -- Only run JS formatters in projects that configure them, so saving never reformats an unrelated repo.
      formatters = {
        prettier = { require_cwd = true },
        biome = { require_cwd = true },
      },
      -- Off by default: saving during review shouldn't add formatting churn to an agent's diff.
      format_on_save = function(bufnr)
        if not vim.b[bufnr].autoformat then
          return
        end
        return { timeout_ms = 1500, lsp_format = "never" }
      end,
    },
    keys = {
      { "<leader>cf", function() require("conform").format({ lsp_format = "fallback" }) end, desc = "Format file", mode = { "n", "x" } },
      {
        "<leader>uf",
        function()
          vim.b.autoformat = not vim.b.autoformat
          vim.notify("Format on save for this buffer " .. (vim.b.autoformat and "on" or "off"))
        end,
        desc = "Toggle format on save (buffer)",
      },
    },
  },
}
