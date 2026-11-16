# Diffs

Ask an agent to “open the diffs in Neovim” or “open the diffs in Neovide” to send the branch or PR diff to Neovide. It reuses a running Neovide session or opens a new window; terminal Neovim sessions are not reused. New diff windows start maximized, and existing windows keep their size. See [agent requests](../README.md#asking-an-agent-to-open-things-in-neovide) for commands and setup.

| Keys | What it does |
|---|---|
| `Space gd` | Side-by-side diff of uncommitted changes |
| `Space gD` | Fetch the PR's base branch, then diff everything this branch changes, including uncommitted work. The right side is the real file, so `gd` and `K` work there. |
| `Space gq` | Close the diff view |
| `Space gh` / `Space gH` | History of this file / of the whole repo |
| `Space gs` | List the files that changed |
| `Space gl` | Git log |

## Inside the diff view

| Keys | What it does |
|---|---|
| `Tab` / `Shift+Tab` | Next / previous file |
| `gf` | Open the file in a normal tab |
| `Space e` / `Space b` | Jump to the file list / hide or show it |
| `-` or `s` on the file list | Stage or unstage that file. `S` stages all. |
| `X` on the file list | Throw away the changes to that file |
| `]x` / `[x` | Next / previous merge conflict |

## Changed blocks in a normal buffer

| Keys | What it does |
|---|---|
| `]h` / `[h` | Next / previous changed block |
| `Space hp` | Preview the change inline |
| `Space hs` / `Space hr` | Stage / undo the change (in visual mode, only the selected lines) |
| `Space hS` / `Space hR` | Stage / undo the whole file |
| `Space gb` | Who last changed this line, and in which commit |
| `Space gB` | Show that blame at the end of every line, or hide it |
| `ih` | Select the changed block, e.g. `vih` or `dih` |
