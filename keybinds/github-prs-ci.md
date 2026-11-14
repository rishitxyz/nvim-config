# GitHub PRs and CI

| Keys | What it does |
|---|---|
| `Space gG` | gh-dash: your PRs and review requests across all repos, with their CI status |
| `Space gp` | List the repo's PRs and open one in Octo |
| `Space gP` | Open the current branch's PR in Octo |
| `Space gr` | Start or resume a review of the PR |
| `Space gc` | PR checks. Inside Octo they show in Octo, otherwise a live terminal view. |
| `Space ga` | CI for the latest commit: failed logs in a split, a live view if a run is still going, or "all passed" |
| `Space gR` | Mark a draft PR ready for review |
| `Space gm` | Squash-merge after a yes/no prompt. It deletes the remote branch and keeps your local branch and worktree. |
| `Space gO` | Menu of every Octo command |
| `Space gg` | lazygit for committing, rebasing and pushing |

## Inside an Octo PR buffer

Localleader is `,`.

| Keys | What it does |
|---|---|
| `,ca` | Add a comment |
| `,cr` | Reply to a comment |
| `,cd` / `,ce` | Delete a comment / see its edit history |
| `]c` / `[c` | Next / previous comment |
| `,pa` | Approve the PR |
| `,vs` | Start a review |
| `,pd` / `,pf` / `,pc` | Show the diff / the changed files / the commits |
| `,rt` / `,rT` | Resolve / unresolve a thread |
| `,la` / `,va` | Add a label / add a reviewer |
| `Ctrl+b` | Open the PR in the browser |
| `Ctrl+y` | Copy the PR's URL |
| `Ctrl+r` | Reload the PR |

## During a review (the diff view Octo opens)

| Keys | What it does |
|---|---|
| `]q` / `[q` | Next / previous file |
| `]u` / `[u` | Next / previous file you haven't marked viewed |
| `,` then Space | Mark the file viewed. This syncs to GitHub's "Viewed" checkbox. |
| `,ca` | Comment on the line, or on the selected lines |
| `,sa` | Suggest a code change on those lines |
| `]t` / `[t` | Next / previous comment thread. Here these replace the tab-switching keys. |
| `,vs` | Submit the review. In the submit window, `Ctrl+a` approves, `Ctrl+m` comments and `Ctrl+r` requests changes. |
| `,vd` | Throw away the review |
| `Ctrl+c` | Close the review |
