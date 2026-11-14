---
name: nvim-review
description: Open files, PR or branch diffs, or a PR's conversation in the user's Neovim. Use when the user asks to show, open, view or edit a file, a diff, a PR, changes or PR comments "in nvim", "in neovim", "in vim" or "in my editor".
---

# nvim-review

Run `~/.config/nvim/bin/nvim-review` with Bash, from your current working directory. It opens the request in the user's running Neovim, or in a new tab of their Ghostty window if none is running. It never takes focus away from the app the user is in, so tell them where it opened.

Pick the mode from what the user asked for:

| User asks for | Command |
|---|---|
| A file, or to open a file so they can edit it | `nvim-review --file <path>` |
| A specific place in a file | `nvim-review --file <path>:<line>` |
| Several files | repeat `--file` for each one (at most 3) |
| The diff, the PR, the branch, your changes | `nvim-review` |
| A PR by number | `nvim-review 512` |
| A PR by URL | `nvim-review <url>` (finds the local clone itself) |
| PR comments, the review, the conversation | `nvim-review --comments`, or `--comments 512` / `--comments <url>` |
| Something in another repo | add `--repo <dir>` |

Use the full path `~/.config/nvim/bin/nvim-review` in the command.

## Choosing files

- Paths can be absolute or relative to your working directory.
- Resolve "the file" from the conversation: the file you just changed, the one being discussed, or the one that defines what the user named. Search the repo if you need to.
- When pointing at code (a function, a bug, a line you changed), pass `:<line>` so the cursor lands there.
- If it's ambiguous which file they mean, ask before running the command.
- "Show me the file" and "open it so I can edit" both use `--file`. The file opens as a normal, editable buffer.

## Choosing the diff

If you work in a git worktree, run from there. The script prefers the worktree that has the PR's branch checked out, so the diff includes uncommitted changes.

## After running

Reply with the one line the script prints. Don't summarize or review anything unless the user asked for that too. If it fails, show the error and stop. Don't retry with guessed arguments.
