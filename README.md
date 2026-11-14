# nvim-config

My Neovim config for Python (FastAPI), TypeScript (React, Vite, Electron) and Rust. It uses [lazy.nvim](https://github.com/folke/lazy.nvim) for plugins.

## Requirements

- Neovim 0.12 or newer
- `git`, `rg`, `fd`, `tree-sitter-cli`, `lazygit`, `node`, `gh`
- `basedpyright` from Homebrew. Mason installs it with pip, which needs Python 3.10 or newer.

```sh
brew install neovim ripgrep fd tree-sitter-cli lazygit gh basedpyright
```

## Install

```sh
git clone https://github.com/rishitxyz/nvim-config ~/.config/nvim
nvim
```

The first launch installs the plugins, Treesitter parsers, language servers and formatters.

## Keymaps

Leader is Space. Press it and wait to see every keymap.

| Keys | Action |
|---|---|
| `Space Space` / `Space /` | Find files / search text |
| `Space fp` | Open a repo from `~/dev/*` in its own tab |
| `-` | Browse the current directory (oil) |
| `Space gd` | Diff uncommitted changes |
| `Space gD` | Diff the branch against main |
| `Space gg` | lazygit |
| `Space gp` / `Space gr` | List GitHub PRs / review the current PR |
| `]h` `[h` | Next / previous change |
| `gd` / `gr` / `K` | Definition / references / docs |
| `Space ca` / `Space cr` | Code action / rename |
| `Space uf` | Toggle format on save |

Each tab has its own working directory, so file search and git commands only cover the repo open in that tab.
