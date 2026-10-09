# Dots

Zsh uses Oh My Zsh with its bundled `robbyrussell` theme and `git`, `extract`, and `sudo` plugins,
plus zsh-completions, zsh-autosuggestions, and zsh-syntax-highlighting.
`install.sh` installs Oh My Zsh and the extra plugins under `~/.oh-my-zsh`
before linking the dotfiles. Open a new terminal or run `exec zsh` after setup.

Shell shortcuts:

- Ctrl-R searches history; Ctrl-T inserts files; Alt-C picks a directory.
- Ctrl-F accepts a suggestion; Alt-Right moves forward a word or accepts the next suggested word.
- Ctrl-P / Ctrl-N search history using what you've started typing.
- Ctrl-X Ctrl-E edits the current command in nvim; Ctrl-X Ctrl-U / Ctrl-X Ctrl-R undo / redo edits.
- Escape twice adds sudo to the command; `extract archive.zip` unpacks archives.
- `cd` (or `z`) jumps with zoxide; `zi` opens its directory picker.
- `serve [port]` serves the current directory (default 8000); `reload` starts a fresh shell.

Python environments are activated manually, e.g. `source .venv/bin/activate`.

Neovim uses Space as the leader key. A few useful shortcuts:

| Keys | Action |
| --- | --- |
| `gzaiw)` | Put parentheses around a word |
| `gzd)` / `gzr)"` | Remove parentheses / replace them with quotes |
| `<leader>or` / `<leader>os` | Restore this project's session / select a session |
| `<leader>ol` / `<leader>od` | Restore the last session / stop saving this session |
| `<leader>fz` | Pick a directory from zoxide history |
| `<leader>f"` / `<leader>fj` / `<leader>fc` | Registers / jumps / changes |
| `<leader>fk` | Search keymaps |
| `<leader>cl` / `[q` / `]q` | Toggle quickfix / previous / next result |
| `Ctrl-h/j/k/l` | Move between Neovim splits and tmux panes |

Sessions save on exit; restoration is explicit. Python formatting uses Ruff
for imports and formatting. Inline diagnostics are off; use `<leader>d` for
details, or `<leader>fd` to list diagnostics. Flash stays on `s` / `S`, leaving
normal search and character motions alone.

Lualine shows mode, branch, filename, Git changes, errors/warnings, and position.
Git changes reuse Gitsigns' data. After changing tmux configuration, use
`Ctrl-a r` to reload it; restart Neovim to pick up plugin changes.

Mango uses Super+h/j/k/l or Super+arrows to focus windows within the current
workspace. Three-finger swipes do the same. Super+B / N and four-finger
horizontal swipes jump between occupied tags on the current monitor.
Super+1–9 still opens any tag directly, including empty ones.

The external HDMI-A-1 display sits on the left (1080p, 120 Hz); the eDP-1
laptop sits on the right (1080p, 60 Hz). Suggested workspace roles:

| Left monitor | Right laptop |
| --- | --- |
| 1 browser | 6 docs / preview / logs |
| 2 coding | 7 chat |
| 3 focused work | 8 music / utilities |
| 4 API tools | 9 spare |
| 5 spare | |

Super+1–5 jumps to the external display; Super+6–9 jumps to the laptop.
Super+Shift+number moves the focused window to that tag on its assigned display.
Super+comma / period focuses the left / right screen; add Shift to move a window
to the other screen's current tag. Super+Alt+Left / Right also focuses the
left / right screen without changing its workspace. Super+Alt+Shift+Right
sends the window directly to companion workspace 6; Super+Alt+Shift+Left
sends it to the left screen's current workspace.

Apps are not assigned to specific monitors or workspaces; new windows open
on the current workspace. Move them with the shortcuts above as needed.
Workspace 6 uses monocle so reference material gets the full
laptop width; Super+Tab cycles its windows. Super+G temporarily tiles them.
Return from chat with Super+6, then Super+Alt+Left returns to your main work.
Ordinary focus and window exchange stop at workspace/monitor edges.

Waybar shows all occupied tags on each display, plus its current and urgent
tags. Empty inactive tags are hidden but remain accessible through the number
shortcuts. Mango has per-monitor tags, so the split is a routing
convention, not a hard restriction. Startup opens 1 and 6. On unplugging either
display, all number shortcuts fall back to the remaining display. Reconnecting resumes shortcut
routing; existing windows are not forcibly redistributed by a background script.

Implementation references: [Mango monitor rules](https://mangowm.github.io/docs/configuration/monitors/),
[cross-monitor commands](https://mangowm.github.io/docs/bindings/keys/),
and [Waybar 0.15 workspace options](https://github.com/Alexays/Waybar/blob/0.15.0/man/waybar-ext-workspaces.5.scd).

Super+Shift+C reloads Mango; Super+Ctrl+B restarts Waybar. Escape leaves
resize mode. Volume and brightness keys work on the lock screen. Screenshot
shortcuts remain; screen recording is not configured.
