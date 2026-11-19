# To-do: desktop theming

Goal: one designed desktop that recolours as a whole when the theme changes.
The inspiration video (not a spec) is `~/Downloads/WhatsApp Video 2026-11-16 at 6.19.15 PM.mp4`
(22 s, not in the repo). Current state and context: [HANDOFF.md](HANDOFF.md).

Everything below is a proposal. Nothing here is approved until the user picks it.

## 1. Ideas from the reference video

The video is inspiration, not a spec (user, 2026-11-18). The goal is a better
desktop: take an idea only where it beats what we have, and say why.

A text description of the whole video, with timings and sampled colours, is in
[docs/inspirations/rice-video-2026-11-16.md](docs/inspirations/rice-video-2026-11-16.md).

Decided 2026-11-18:
- Keep the three fixed themes; Ultra Dark with `fuji-frame.jpg` is the
  favourite. Other themes may come later.
- About two wallpapers per theme is enough.
- Keep our carousel's behaviour: a 600 ms dwell applies a live preview, and
  the caption names the theme.

### A. Carousel (`.config/noctalia/plugins/themes/carousel.luau`)
Ideas from the video to judge; our behaviour stays:
- A lighter scrim (ours dims to 45%; the video does not dim at all).
- A larger centre card with a steeper slant; neighbours at full opacity,
  tucked behind it.
- A quick fade on open; after a pick the chosen card fades before the band.
- [ ] Choose which ideas to try, try them in the sandbox, keep what looks
      better; keep the Lua carousel tests passing.

### B. Wallpaper change (`.config/noctalia/wallpaper.toml`)
- [ ] The video uses wipes (diagonal ~500 ms, then wavy top-down ~250 ms). Ours is a
      700 ms `fade`; a straight `wipe` was tried and rejected as too busy. Try
      a diagonal wipe and keep whichever looks better.

### C. Bar
- [ ] Idea: a quieter bar, as in the video: workspace dots on the left (the
      active one an accent pill), one centre capsule with the clock, a
      wallpaper thumbnail and a small audio visualiser (see 3, `cava`), and
      three small icons on the right.

### D. Terminals
- [x] Fastfetch colour bar of theme shades and accent-coloured keys
      (done 2026-11-18; now slot-based, see README "Theming").
- [x] Open kitty windows recolour on a switch (seen live 2026-11-18).
- [x] Inner padding in kitty (`window_padding_width 4 10`).
- [x] Shade bar readable on all themes (the accent at six lightnesses).
- [x] yazi, fzf, fastfetch and delta recolour live via kitty palette slots
      112-142; Neovim and tmux reload on a switch (verified live 2026-11-19).

### E. Wallpapers
- [ ] Trim each theme to about two wallpapers; the user picks which. Ultra Dark
      keeps `fuji-frame.jpg`. Move the rest to a dated folder under
      `Pictures/wallpapers-retired/` rather than deleting them.

## 2. Make every app follow the theme

Noctalia ships 111 community templates. Turn them on in
`.config/noctalia/theme.toml` with `enable_community_templates = true` and
`community_ids = [...]`.

| App | Route | Note |
|---|---|---|
| Neovim, Yazi, tmux, fzf, bat / delta | | Done 2026-11-18; see HANDOFF.md "How the theming works" |
| Zen browser | `zen-browser` template or `noctalia firefox-theme` | The latter needs the Pywalfox extension |
| Obsidian, VS Code, Zathura | `obsidian`, `vscode`, `zathura` templates | |
| Claude Code, Codex | `claude-code`, `codex` templates | |
| zsh prompt | none | robbyrussell uses ANSI colours, so it already follows kitty |
| Lock screen | Noctalia's own lock screen in place of swaylock | swaylock (`swaylock/config`) is hard-coded grey |

## 3. Optional extras
- [ ] `papirus-icons` template: folder icons in the accent colour.
- [ ] Theme `noctalia-greeter` (installed) to match the login screen.
- [ ] Audio visualiser by the clock, as in the video: install `cava` and enable
      the built-in `cava` template.
- [ ] One cursor theme; Maple Mono for GTK apps too.
- [ ] Per-theme Mango settings: border width, blur and animation speed.
- [ ] Night light (Noctalia gamma control).
- [ ] Templates for apps that aren't installed yet: Spotify (spicetify), Discord,
      Telegram, lazygit, Thunar.

## 4. Finish
- [ ] Test the carousel with a physical keyboard: Super+Shift+T, arrows, holding
      a key, mouse clicks. Also test on both monitors and with an empty card
      cache (`~/.cache/theme/cards/`).
- [ ] Add `/Pictures/wallpapers-retired/` to `.gitignore` before any commit. It
      holds third-party images and is currently untracked but not ignored.
- [ ] Decide about the untracked `.config/mango/config.conf.bak` and `.bak2`.
- [x] Document each newly themed app in README.md under "Theming".
- [ ] Commit, only when the user asks.
