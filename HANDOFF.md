# Handoff: desktop theming

Updated 2026-11-18. Open tasks are in [TODO.md](TODO.md). Usage and the theming
reference are in [README.md](README.md) under "Desktop shell" and "Theming".

## Goal
A calm, cozy, cohesive desktop that reads as one design, not a pile of widgets.
Rounded, floating elements and a tasteful amount of information. Everything
recolours together when the theme changes. The inspiration (not a spec) is a 22 s
screen recording, `~/Downloads/WhatsApp Video 2026-11-16 at 6.19.15 PM.mp4`
(not in the repo). It shows terminals, a slanted-card wallpaper carousel and a
whole-desktop recolour.

## Stack
- Mango (Wayland compositor) and Noctalia v5.5.0 (bar, panels, notifications,
  wallpaper, colour templates).
- `~/.config/*` and `~/Pictures` link into this checkout.
- Font: Maple Mono NF everywhere in the shell.
- Three themes: `ultra-dark` (sage on near-black), `catppuccin-macchiato` and
  `tokyo-night`. The wallpaper-derived **Auto** theme was removed on 2026-11-18;
  its six pictures are kept in
  `Pictures/wallpapers-retired/auto/2026-11-18-theme-removed/`.

## State on 2026-11-18
- **Git:** branch `master`, last commit `40262ca` (2026-10-09). Everything below
  is **uncommitted**: 11 modified tracked files and 13 untracked paths. Nothing
  has been pushed or deployed. The uncommitted work spans several sessions
  (an earlier Claude chat, Codex and this session), so the working tree can't
  be split by session.
- **Live desktop:** theme `ultra-dark`, wallpaper `ultra-dark/fuji-frame.jpg`
  (the user's choice).

## How the theming works
- `.local/bin/theme` (Python CLI) offers:
  - `set <id> [--wallpaper <path>]`, `next`, `prev`, `list`, `current`
  - `wallpaper`, `remember`, `sync-bar`, `choose`
  - `catalog` (JSON) and `cards` (ffmpeg card thumbnails cached in
    `~/.cache/theme/cards/`)

  Each theme remembers its last wallpaper in `~/.local/state/theme/wallpapers.json`.
- `.config/noctalia/palettes/<id>.json` holds the palettes;
  `.config/noctalia/bars/<id>.toml` holds the per-theme bars, which `theme`
  links to the git-ignored `bar.toml`.
- `.config/noctalia/theme.toml` lists the colour templates:
  - built-in: kitty, gtk3, gtk4, qt, kcolorscheme, btop
  - user: `templates/mango.conf` (a trimmed Mango template, because the built-in
    one writes keys this Mango lacks) and `templates/accent`, which drives the
    colour-matched fastfetch Pokémon via `.local/bin/pokesprite`
  - user, added 2026-11-18/19: `templates/kitty-roles.conf` (theme roles in
    kitty palette slots 112-142; its hook reloads kitty), `templates/yazi.tmTheme`
    (yazi preview syntax colours), `templates/tmux.conf` + `tmux-reload`
    (colour variables only) and `templates/nvim.lua` (base16 scheme for
    palettes without a Neovim mapping)
  - community (`community_ids`): bat only (also used by delta)
- yazi's flavor, fzf's `--color`, fastfetch and delta use the slot numbers,
  not hex, so they recolour live with kitty. README "Theming" lists the parts.
- Neovim (`nvim/lua/guru/theme.lua`) reads the active palette from Noctalia's
  settings and maps it: ultra-dark → vague, catppuccin-macchiato →
  catppuccin macchiato, tokyo-night → tokyonight night, anything else →
  `base16-noctalia`, else vague. All transparent. The nvim template's hook
  sends SIGUSR1 so open editors switch.
- `.config/noctalia/hooks.toml`: `started` runs `theme sync-bar`;
  `wallpaper_changed` runs `theme remember`.

## The theme carousel (built this session)
- Files are in `.config/noctalia/plugins/themes/`:
  - `plugin.toml`: a service plus a full-screen overlay layer on the focused output
  - `service.luau`: catalog, card cache, show/hide, Mango key mode, one switch
    at a time with the latest pick winning
  - `carousel.luau`: ring of slanted cards, spring motion, captions

  The old panel (`panel.luau`, with an Apply button) is gone.
- **Opening:** Super+Shift+T, or right-click the bar's wallpaper button.
- **Choosing:**
  - Left/Right moves one card; Up/Down/Tab jumps to the next theme.
  - Settling 600 ms applies the theme, with an accent tab that fills over that time.
  - Enter applies and closes; Esc closes.
  - It auto-closes 2.5 s after the last apply.
  - Super+Ctrl+T still runs `theme next`.
- **Key handling:** Noctalia v5.5.0 layers get keys only in text fields. So while
  the carousel is open, Mango switches to a `themes` key mode
  (`.config/mango/config.conf`) whose binds forward keys over
  `noctalia msg plugin guru/themes:carousel ...`. Esc and Super+Esc always
  return Mango to the default mode.
- The wallpaper transition stays `fade` 700 ms (`.config/noctalia/wallpaper.toml`);
  a straight `wipe` was tried and rejected.

## Verification (re-run 2026-11-18)
- `python3 -m unittest discover -s .config/theme/tests`: 29 tests OK.
- `lua .config/theme/tests/theme_carousel_test.lua .config/noctalia/plugins/themes`:
  12 scenarios pass.
- `noctalia config validate`: valid. `mango -p`: no errors.
- Visual checks:
  - Timed screenshots in a headless sandbox (Mango with `WLR_BACKENDS=headless`
    plus Noctalia with private XDG dirs) covered open, step, jump, dwell-apply,
    close, wrap, failure/retry and auto-close.
  - One live open/close with no apply left the theme and wallpaper unchanged.
  - The sandbox scripts lived in a temporary scratchpad and are gone; rebuild
    them if needed.
- **Not verified:**
  - the carousel with a physical keyboard (Super+Shift+T, held keys) and mouse
    clicks on the live screen
  - HiDPI outputs
  - CPU load when all cards are drawn at a fresh login
  - live recolouring of already-open kitty windows (known from code only)
  - anything after the Auto removal beyond the tests above
- **Sandbox-only oddity:** a black rectangle appears in the middle of the screen.
  It shows with the themes plugin disabled and never on the live desktop, so it
  is not the carousel.

## Before committing
- `Pictures/wallpapers-retired/` holds third-party images without a stated
  licence (provenance is in `Pictures/wallpapers/SOURCES.md`). It is untracked
  but **not** git-ignored. Add it to `.gitignore` as `/Pictures/wallpapers/` is.
- Decide about the untracked `.config/mango/config.conf.bak` and `.bak2`.
- Commit or push only when the user asks; no AI co-author trailers.

## Decided
- 2026-11-18: keep the three fixed themes. The video derives every colour from
  the wallpaper; the user chose not to follow that model.
- 2026-11-18: the video is inspiration, not a target. Take an idea from it
  only where it makes the desktop better.
- 2026-11-18: Ultra Dark with `fuji-frame.jpg` is the favourite; work on the
  three themes now, other themes later. About two wallpapers per theme.
- 2026-11-18: keep our carousel's dwell-apply and caption.
- 2026-11-18: Neovim uses one real colour scheme per theme (vague stays for
  Ultra Dark); a generated base16 scheme only for unmapped palettes.
- 2026-11-18: yazi keeps the user's own icons (as `prepend_*` rules with
  terminal colour names) ahead of the flavor's.
- The video is described in text in
  [docs/inspirations/rice-video-2026-11-16.md](docs/inspirations/rice-video-2026-11-16.md).
  `docs/`, `HANDOFF.md` and `TODO.md` are in `.stow-local-ignore`, so stow
  does not link them into `$HOME`.
- 2026-11-18: the "hanging card on a line" in the video is the red eye
  wallpaper, not carousel motion. That task is dropped (see TODO.md 1).

## Open decisions (the user's)
- Which [TODO.md](TODO.md) sections to do, and in what order.
- Which two wallpapers each theme keeps (TODO.md 1E).

## Next bounded task (proposed)
TODO 1A: try the carousel ideas the user picks in the sandbox and keep what
looks better, with the Lua carousel tests still passing.
