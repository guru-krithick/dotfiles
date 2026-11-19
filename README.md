# Dots

Claude Code and Codex share a portable setup under
`.config/agent-config/`: personal instructions, Claude subagents, Codex
coordination and role definitions, reusable skills, notification scripts, and
the Rosé Pine Powerline configuration. No personal worker cap is configured.

On a new Linux or macOS machine, install Python 3.11.8+, Node.js, curl, and the
Claude/Codex clients. Clone this repository anywhere, then run:

```sh
./.local/bin/agent-config plan
./.local/bin/agent-config apply --bootstrap
```

The command links its own launcher and configuration source, so it also works
before running Stow. `install.sh` includes this setup in the full Arch bootstrap.
Add `~/.local/bin` to your PATH when using the agent setup alone. Sign in to each
client separately and restart it after applying.

Day to day:

```sh
agent-config capture   # copy model/display preferences back into dotfiles
git diff              # review before committing/syncing
agent-config apply    # apply the checkout's current preferences
agent-config check    # exit nonzero when another apply is needed
```

Transport changes through this Git repository: capture or edit the source,
commit/push as usual, then pull and apply on the other machine. Edit instructions,
skills, roles, and Powerline theme files in the checkout, then run `apply`.
Instructions, skills, subagents, roles, and the theme link to the source; Codex's
global instructions are generated from the shared and Codex-specific files.
`capture` handles model/display preferences changed in the clients. It
deliberately does not export authentication, providers, MCP
credentials, permissions, plugins, project trust, or conversations.

Only selected preferences are merged into local `settings.json` and
`config.toml`; local-only settings remain on each machine. Whole `.claude` and
`.codex` directories are never linked into Git. Powerline is pinned and verified
against its lock file, then installed under `~/.local/share/agent-config/`.
Backups and manifests live under `~/.local/state/agent-config/backups/`, outside
the checkout. XDG config/data/state roots and custom Claude/Codex home variables
are respected. `--only claude` or `--only codex` applies one client; `--home`
supports a migration preview or isolated test home. `plan` and `check` do not
write files or download anything. Desktop toasts use `notify-send` when available;
Codex terminal alerts continue to work without it.

Both clients run without approval prompts. Claude defaults to `bypassPermissions`
and skips its startup confirmation (`skipDangerousModePermissionPrompt`); Codex
uses `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`.
`apply` owns `permissions.defaultMode` and every hook whose command points into
`agent-config/`; other permission rules and hooks stay local.

Two Claude accounts share this setup: `cc` runs `claude` with the default
`~/.claude`, and `cc1` runs `CLAUDE_CONFIG_DIR=$HOME/.claude-alt claude`. Each
home keeps its own login. `config/claude-homes.json` lists the homes, primary
first: `plan`, `apply` and `check` cover every home, while `capture` reads only
the primary. `~/.claude-alt/projects` links to `~/.claude/projects`, so `/resume`,
transcripts and auto-memory are shared; if a non-empty `projects` directory is
already there, `apply` stops for a manual merge. A `CLAUDE_CONFIG_DIR` that names
a listed home (as inside `cc1`) changes nothing; any other value replaces the
primary. Claude subagents in `agents/claude/*.md` link into each home's
`agents/`; Codex roles stay in `agents/*.toml`.

The Codex footer includes model/effort, working directory, branch, context and
five-hour limit. `repo_explorer` investigates code and `change_reviewer` reviews
changes; neither has a separate sandbox or an imposed worker-count setting.
The main thread owns implementation and integration. The tool's own runtime
limits still apply.

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

The bar shows the occupied tags of its display, plus the current and urgent
ones. Catppuccin also shows empty tags as faint dots; the other themes hide
them. All tags remain accessible through the number shortcuts.
Mango has per-monitor tags, so the split is a routing
convention, not a hard restriction. Startup opens 1 and 6. On unplugging either
display, all number shortcuts fall back to the remaining display. Reconnecting resumes shortcut
routing; existing windows are not forcibly redistributed by a background script.

Implementation references: [Mango monitor rules](https://mangowm.github.io/docs/configuration/monitors/),
[cross-monitor commands](https://mangowm.github.io/docs/bindings/keys/),
and [Noctalia's workspaces widget](https://docs.noctalia.dev/noctalia/bar/widgets/workspaces/).

Super+Shift+C reloads Mango; Super+Ctrl+B restarts Noctalia. Escape leaves
resize mode. Volume and brightness keys work on the lock screen. Screenshot
shortcuts remain; screen recording is not configured.

## Desktop shell

Noctalia, started by Mango, draws the bar, notifications, OSD, launcher,
control center, clipboard history, tray, wallpaper and theme colours.
swayidle and swaylock still lock the screen; Noctalia's own lock and idle
actions are switched off.

| Keys | Action |
| --- | --- |
| Super+D | Launcher |
| Super+C | Control center: network, bluetooth, audio, power, notifications |
| Super+Shift+V | Clipboard history (Super+Ctrl+Delete clears it) |
| Super+Shift+W | Wallpaper picker for the current theme; the picture button on every bar opens it too |
| Super+Shift+T | Theme carousel (press again to close); also right-click the bar's picture button |
| Super+F2 | Session menu; lock and suspend go through swaylock |
| Super+Ctrl+T / Super+Ctrl+W | Next theme / next wallpaper |

Volume, mic and brightness keys go through `noctalia msg` so the OSD shows.
Configuration is in `~/.config/noctalia/`: `bars/` (theme layouts), `bar.toml`
(the active layout link), `shell.toml`
(font, panels, session menu, lock and idle), `theme.toml` (palette and app
templates), `wallpaper.toml`, `hooks.toml`, plus `palettes/` and `templates/`.
`noctalia config validate` checks them. Changes made in Noctalia's Settings
window are saved to `~/.local/state/noctalia/settings.toml`, outside this
repository, and win over these files; copy a setting into them to keep it, and
delete it from `settings.toml` to fall back to them.

Each theme has its own bar arrangement:

| Theme | Bar |
| --- | --- |
| Ultra Dark | Top: inset charcoal rail; tags and a bounded song title left, shared clock/timer inset centre, status and wallpaper/dashboard actions right; pale sage and fog-white accents |
| Catppuccin Macchiato | Top: one floating bar with tag dots and small chips, like Cozytile |
| Tokyo Night | Bottom: compact centred strip, tags left, media centre, status/clock right |

Icons are scaled independently from text. Battery charge uses a battery
glyph with a readable label; volume percentages stay in the tooltip so the
bar does not repeat percentage labels.

Windows use 8 px inner and outer gaps and 12 px corners. Tokyo Night places
notifications at the bottom right and the volume/brightness OSD above its
bottom bar, with a 56 px screen-edge offset. The other themes use top-edge
popups. OSD offsets live in each bar layout so shared shell settings do not
override them.

Shell panels use Noctalia's `glass` translucency with more opaque content
cards, gentle downward shadows, and native animations at speed `0.9`.
Notifications and volume/brightness popups use 85% background opacity.
Mango supplies background blur only to Noctalia panel, attached-panel,
notification and OSD surfaces; bars and invisible click shields keep their
existing treatment. Compositor layer animations stay disabled so native
shell animations run once. After changing these layer rules, restart
Noctalia with Super+Ctrl+B; Mango caches rules when a surface is created.

All layouts include microphone/camera/screenshare activity. Catppuccin and
Tokyo Night also include a powerboost indicator and an idle inhibitor
(coffee glyph). Ultra Dark keeps power-profile and idle controls in
the dashboard; the custom boost toggle remains on Super+Shift+F.
Bar powerboost clicks run the existing `~/.local/bin/powerboost toggle`;
the native power-profile service provides the indicator without polling
the script. The coffee glyph uses Wayland idle inhibition, shared with the
existing swayidle setup.

Every bar, panel and toast uses Maple Mono NF, the shell font. Ultra Dark shows a single bounded track title. The clock and running timer share a
capsule. Native clock anchoring is disabled because it splits capsule groups.

Ultra Dark's default wallpaper is `ultra-dark/00-misty-pines.jpg`, mist rising
through a pine forest; its picker keeps the other nature scenes (fog over dark
water, a sage misty ridge, peaks and Fuji); they are 4K photographs. The former
car/urban/neon Ultra Dark scenes, two low-resolution generated images and the
removed Auto theme's wallpapers are preserved in dated folders under
`~/Pictures/wallpapers-retired/`.
Image provenance is recorded in `~/Pictures/wallpapers/SOURCES.md`.

The pomodoro uses `waybar/scripts/pomodoro.sh` through
`noctalia/scripts/pomodoro-widget`: left-click starts, right-click pauses or
resumes, middle-click resets, and scrolling adjusts a paused timer. All
themes hide it while idle; middle-click the clock to start.
The unchanged community `tordex/stdout` plugin is bundled in
`noctalia/plugins/` and enabled as a local source, so it works offline.
Its upstream revision and attribution are recorded in that directory.

Back to waybar, mako and rofi: in `~/.config/mango/config.conf`, comment out
every line that mentions noctalia, uncomment the old-stack block near the end,
and log in again. Their configurations are unchanged.

## Theming

`theme` switches the whole desktop: Noctalia's palette (the bar and panels
cross-fade), the wallpaper (a 700 ms fade) and, through Noctalia's
templates, kitty, Mango's borders, GTK 3/4, Qt (qt6ct), btop and the terminal
apps below. Open GTK and Qt apps pick up the new colours when restarted.

Terminal apps recolour while open:

- **kitty** reloads on every switch. Besides the 16 ANSI colours, Noctalia
  writes the theme's roles (surfaces, outlines, accent, errors, diff shades)
  into kitty's palette slots 112-142 (`templates/kitty-roles.conf` →
  `kitty/themes/noctalia-roles.conf`; Ultra Dark fallbacks in `kitty.conf`).
- **yazi** (static flavor `yazi/flavors/noctalia.yazi/`), **fzf** (the
  `--color` list in `.zshrc`, transparent background), **fastfetch** (accent
  keys and the shade bar) and **delta** (`[delta]` in `.gitconfig`) draw with
  those slot numbers, so they follow kitty's reload instantly, even in shells
  opened before the switch. Syntax colours in yazi previews (rendered
  `tmtheme.xml`) and in bat/delta (the community `bat` template's `noctalia`
  theme) update on the next run.
- **Neovim** (`nvim/lua/guru/theme.lua`) maps each theme to its own colour
  scheme: ultra-dark → vague, catppuccin-macchiato → catppuccin macchiato,
  tokyo-night → tokyonight night, with transparent backgrounds. Other
  palettes get `base16-noctalia`, generated from `templates/nvim.lua`. Open
  editors switch on the template hook's SIGUSR1.
- **tmux** keeps its own status layout in `tmux.conf` and takes colour
  variables from `templates/tmux.conf`; running servers re-source on a switch.
- The fastfetch Pokémon follows the accent (`templates/accent`,
  `.local/bin/pokesprite`).

Pick slot numbers outside 112-142 for anything else that uses 256-colour
codes, or it will show theme colours. KDE apps such as Okular keep
their own colours unless qt6ct-kde replaces qt6ct and its `noctalia
(KColorScheme)` scheme is selected.

```sh
theme set tokyo-night   # also ultra-dark, catppuccin-macchiato
theme set tokyo-night --wallpaper ~/Pictures/wallpapers/tokyo-night/island-night.jpg
theme choose            # open or close the theme carousel
theme next              # or prev
theme wallpaper next    # or prev, random, or a path to an image
theme list              # theme current; both take --json
```

A theme is a palette, `~/.config/noctalia/palettes/<id>.json`, plus the folder
`~/Pictures/wallpapers/<id>/` (else `~/Pictures/wallpaper.jpg`) and an optional
`~/.config/noctalia/bars/<id>.toml` layout. Themes without their own layout use
`bars/default.toml`. `theme set` updates the generated `bar.toml` symlink;
that link stays across restarts and is ignored by Git. A regular, user-owned
`bar.toml` is preserved instead of being replaced. Noctalia's startup hook
runs `theme sync-bar` to recreate the link on a fresh checkout or if it was
deleted, without reapplying the palette or wallpaper. The wallpaper
picker browses that folder, and each theme returns to its last wallpaper,
including one picked in the picker. A wallpaper never changes a theme's palette.
Noctalia remembers the theme and wallpaper across restarts.

Super+Shift+T opens the theme carousel (the `guru/themes` plugin): every
wallpaper of every theme as one ring of slanted cards floating across the
focused screen over the dimmed desktop, opening on the current theme and
wallpaper. Left/Right move one card (hold to keep moving), Up/Down or
Tab/Shift+Tab jump to the previous/next theme at its remembered wallpaper, and
clicking a side card moves to it. Stay on a card for 0.6 s (the small bar under
it fills) and that theme with that wallpaper is applied; the overlay re-themes
with the desktop and keeps browsing. Enter or clicking the middle card applies
at once and closes; Escape, Super+Shift+T or a click on the dimmed desktop
closes and keeps what was applied. After an apply it closes by itself once
idle for 2.5 s. A failed switch shows a short error under its card; Enter
retries it. Motion follows the shell's animation speed and stops when shell
animations are off.

The overlay is a Noctalia layer, and those only receive keys in text fields, so
while it is open the plugin switches Mango to a `themes` key mode whose binds
(in `mango/config.conf`) forward the arrows, Tab, Enter and Escape to it over
`noctalia msg plugin`; closing returns to the default mode, and Escape or
Super+Escape always does. Switches run through `theme set <id> --wallpaper
<path>` (or `theme wallpaper <path>` within a theme), one at a time: a card
chosen while one runs waits and replaces any card already waiting. The cards are
cropped and slanted once by ffmpeg into `~/.cache/theme/cards/` (`theme cards`,
run in the background when the shell starts and when a new wallpaper is
remembered); `theme catalog` lists them as JSON. The plugin needs plugin API 52, available in Noctalia v5.5.0.

Ultra Dark explicitly selects dark mode when applied, overriding saved light
or automatic day/night settings so a theme switch cannot turn the bar and
terminal pale.

To add a theme, add `palettes/<id>.json` in Noctalia's palette format (copy an
existing one) and, optionally, `~/Pictures/wallpapers/<id>/` and
`bars/<id>.toml`; a theme without a Neovim mapping in
`nvim/lua/guru/theme.lua` uses the generated base16 scheme. kitty and Mango
include the generated `kitty/themes/noctalia.conf`,
`kitty/themes/noctalia-roles.conf` and `mango/noctalia.conf`, which git
ignores. Tests: `python3 -m unittest discover -s .config/theme/tests`.
