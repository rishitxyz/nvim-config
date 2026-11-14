# nvim-config

A Neovim setup for working alongside coding agents. Agents write the code in their own git worktrees, and Neovim is where I review it: read the diff, check CI, comment on the PR and merge. The agents themselves run outside Neovim (I use T3 Code), so there is no AI plugin here.

It covers Python (FastAPI), TypeScript (React, Vite, Electron) and Rust, uses [lazy.nvim](https://github.com/folke/lazy.nvim) for plugins and [Rose Pine](https://github.com/rose-pine/neovim) for colors.

## How a review goes

1. `Space fp` or `Space fw` opens the agent's worktree in its own tab. Each tab has its own working directory, so search, git and LSP stay inside that repo, and two repos can be open side by side.
2. `Space gD` fetches the PR's base branch and shows the whole change, including anything the agent hasn't committed yet. The right side is the real file, so go-to-definition works while reading the diff.
3. Files the agent changes on disk reload when Neovim regains focus.
4. `Space yr` copies `path:lines` plus the selected code, ready to paste back into the agent's thread. `Space yp` copies a GitHub permalink instead.
5. `Space gr` starts a GitHub review in Octo, where comments, approvals and "viewed" marks sync to the PR.
6. `Space ga` shows CI status and opens the logs of failed runs. `Space gm` squash-merges after a confirmation and deletes only the remote branch, so the agent's local worktree stays intact.

Format on save is off by default so saving during a review doesn't add formatting changes to the agent's diff. `Space uf` turns it on.

## Asking an agent to open things in Neovim

From an agent thread you can ask for these, and they open in Neovim:

| Prompt | Opens |
|---|---|
| "show me the diffs of this PR in nvim" | The PR's diff in its own tab, labeled with the PR number |
| "show me the file where X is defined in nvim" | That file at the right line, in the tab for its repo |
| "open package.json in nvim so I can edit it" | The file as a normal buffer, ready to edit |
| "show me the PR comments in nvim" | The PR's conversation and review comments in Octo |

How it works:

- `lua/review.lua` makes every Neovim with a UI listen on `~/.local/state/nvim/sockets/<pid>.sock` and records the most recently focused one. Asking for the same diff or PR again refreshes its tab instead of adding another.
- `bin/nvim-review` resolves the request and sends it to that Neovim, then brings Ghostty to the front. With no Neovim running, it opens a new Ghostty window.
- For diffs, if a local worktree has the PR's branch checked out (usually the agent's own), the diff shows the files on disk, uncommitted changes included. Otherwise it fetches the PR head without checking anything out.
- `agent-skills/nvim-review` is a skill that tells Claude Code and Codex agents when to run the script and which arguments to pass.

```sh
nvim-review                      # this branch's PR, or the branch against the default branch
nvim-review 512                  # PR #512 of the repo in the current directory
nvim-review <PR URL>             # any PR; finds the local clone under ~/dev or ~/.t3/worktrees
nvim-review --file src/app.ts:42 # a file at a line (repeat --file for more files)
nvim-review --comments [PR]      # a PR's conversation
```

To install, link the script and the skill:

```sh
ln -s ~/.config/nvim/bin/nvim-review ~/.local/bin/nvim-review
ln -s ~/.config/nvim/agent-skills/nvim-review ~/.claude/skills/nvim-review
ln -s ~/.config/nvim/agent-skills/nvim-review ~/.codex/skills/nvim-review
```

Agents need network access (for `gh` and `git fetch`) and access to the socket, so Codex has to run with full access rather than its default sandbox.

## Requirements

- Neovim 0.12 or newer
- `git`, `rg`, `fd`, `tree-sitter-cli`, `lazygit`, `node`, `gh` with the `gh-dash` extension
- `basedpyright` from Homebrew. Mason installs it with pip, which needs Python 3.10 or newer.

```sh
brew install neovim ripgrep fd tree-sitter-cli lazygit gh basedpyright
gh extension install dlvhdr/gh-dash
```

## Install

```sh
git clone https://github.com/rishitxyz/nvim-config ~/.config/nvim
nvim
```

The first launch installs the plugins, Treesitter parsers, language servers and formatters. The project picker looks for repos in `~/dev/*` and agent worktrees in `~/.t3/worktrees`. Change `project_roots()` in `lua/plugins/editor.lua` if yours live elsewhere.

## Keymaps

Leader is Space. Localleader is `,` and is used inside Octo PR buffers (for example `,ca` to comment, `,pa` to approve). Press Space and wait to see every keymap.

The table below has the main ones. The full list, grouped by task, is in [`keybinds/`](keybinds):

- [Repos, tabs and files](keybinds/repos-tabs-files.md)
- [Reading code](keybinds/reading-code.md)
- [Diffs](keybinds/diffs.md)
- [Sending feedback to the agent](keybinds/agent-feedback.md)
- [GitHub PRs and CI](keybinds/github-prs-ci.md)
- [Editing](keybinds/editing.md)
- [Sessions](keybinds/sessions.md)

| Keys | Action |
|---|---|
| `Space fp` | Open a repo or agent worktree in its own tab |
| `Space fw` | Open one of this repo's worktrees in its own tab |
| `Space Space` / `Space /` | Find files / search text |
| `-` | Browse the current directory (oil) |
| `s` | Jump to any visible text (flash) |
| `Space gd` | Diff uncommitted changes |
| `Space gD` | Fetch, then diff the branch against its PR base |
| `]h` `[h` | Next / previous change |
| `Space gp` / `Space gP` | List GitHub PRs / open this branch's PR |
| `Space gr` | Review the PR |
| `Space gc` / `Space ga` | PR checks / CI status with failed logs |
| `Space gR` / `Space gm` | Mark PR ready / squash-merge it |
| `Space gG` | gh-dash |
| `Space gg` | lazygit |
| `Space yr` / `Space yp` | Copy a `path:lines` reference / a GitHub permalink |
| `Space qs` / `Space ql` | Restore this directory's session / the last session |
| `gd` / `gr` / `K` | Definition / references / docs |
| `Space ca` / `Space cr` | Code action / rename |
| `Space uf` | Toggle format on save |
