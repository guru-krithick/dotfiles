# Inspiration: themed Arch desktop screen recording (2026-11-16)

**Source:** `~/Downloads/WhatsApp Video 2026-11-16 at 6.19.15 PM.mp4`. The
video is not in this repo. It runs 22.2 s at 1280x720 and was recompressed by
WhatsApp, so the colours below are approximate.

**Status:** inspiration, not a spec. The user likes every part of it: the
motion, the colours, the minimal bar and the terminals. Take an idea from it
only where it makes this desktop better. Decisions that differ from the video
are listed at the end.

This file describes the video in text so a person or a model can work from it
without watching. Times are seconds into the video. Pixel values are for the
1280x720 frame; multiply by 1.5 for a 1920x1080 screen.

## In one paragraph

It is a tiling Wayland desktop with four kitty terminals, each running
fastfetch with a Pokémon sprite. The whole desktop is tinted in one colour
taken from the wallpaper: red with a red eye wallpaper, green with a pixel-art
forest, purple with a Gengar poster. The user opens and closes terminals, opens
a carousel of slanted wallpaper cards, picks one, and the wallpaper wipes over.
The bar, the terminal backgrounds, the fastfetch colour bar and the choice of
Pokémon all change to the new colour. Everything is quick and quiet. Nothing
bounces, and no text appears besides the clock and the terminals' contents.

## Timeline

| Time | What happens | Colour |
|---|---|---|
| 0.0-1.4 | Four terminals tiled 2x2, each with a fastfetch Pokémon: Scizor, Charizard, Blaziken, Groudon | Red |
| 1.4-2.0 | Terminals close one after another (~100 ms apart); the rest slide into the freed space and fade | Red |
| 2.0-4.8 | Close and reopen several more terminals (Ho-Oh, Flareon, Charmander); empty desktop shows the red eye wallpaper between them | Red |
| 5.6 | Carousel opens over the eye wallpaper | Red |
| 5.9-7.6 | Browses about six cards: city street, white skull, ghost, mountain road, Luffy, white-haired figure, forest. The desktop does not change while browsing | Red |
| 7.6 | Picks the forest; the band fades out (~150 ms) | Red |
| 7.9-8.5 | Old wallpaper alone for ~300 ms, then a diagonal wipe from the top-right corner to the bottom-left brings in the forest (~500 ms) | Red to green |
| 8.5-10 | Forest wallpaper alone; bar is already green | Green |
| 10-16 | Terminals open and close in green: Rayquaza, Sceptile, Scyther, Venusaur, Tyranitar, Bulbasaur, Leafeon. Single, two-up and 2x2 layouts | Green |
| 16.4-18.0 | Carousel again over the forest; browses past Charizard art to a Gengar poster | Green |
| 18.0 | Picks Gengar; the chosen card turns translucent, then the band is gone (~150 ms) | Green |
| 18.6-18.9 | Wallpaper wipes from top to bottom with a wavy, jagged edge (~250 ms). The transition differs from the first one, so it is probably random per change | Green to purple |
| 19.5-22 | Gengar wallpaper; terminals reopen in purple: Espeon, Mewtwo, Crobat, Gastly | Purple |

## Parts of the desktop

### Bar
- One thin strip across the top, about 22 px tall, with no outline. Its
  background is a very dark version of the theme colour.
- **Left:** four small workspace dots. The active one is a wider pill in the
  accent colour (red `#bc503d`, green `#338472` or magenta `#c456bf`); the others
  are dim dots.
- **Centre:** a dark pill holding the clock `21:49` in a bold mono font, a tiny
  thumbnail of the current wallpaper, and a small audio visualiser of thin
  vertical bars in the accent colour. In the green theme the pill sits in a
  shallow curved notch that dips from the top edge.
- **Right:** three tiny accent-coloured icons.
- There is no window title, media title, battery text or other words.

### Terminals
- kitty, tiled with a small gap (about 4 px). There are no visible borders.
  The focused window shows only a faint accent glow on its edge.
- The background is the theme colour darkened almost to black and slightly
  translucent, so the wallpaper shows faintly through it. For example the
  Gengar art is visible behind the purple terminals.
- fastfetch layout:
  - left: a pixel-art Pokémon sprite, about 110 px tall
  - right: `user@host`, a dashed rule, then eight lines (OS, kernel, uptime,
    packages, CPU, GPU, memory, terminal and shell), each with a small glyph
    and a ` - ` separator, in a light grey
  - below that, a colour bar of about 6 flat blocks running from grey through
    the theme's shades to white, instead of round ANSI dots
- The Pokémon matches the theme colour. Red brings Scizor, Charizard,
  Blaziken, Groudon, Ho-Oh, Flareon and Charmander. Green brings Rayquaza,
  Sceptile, Scyther, Venusaur, Tyranitar, Bulbasaur and Leafeon. Purple brings
  Espeon, Mewtwo, Crobat and Gastly. Each new terminal gets a different one.
- Prompt: a small arrow, then the path `/home/diego` and a block cursor. A
  dim clock sits at the right end of the prompt line.

### Wallpaper carousel
- It is one horizontal band across the middle of the screen. The desktop
  behind it is not dimmed.
- The cards are parallelograms that all lean the same way: the top edge is
  shifted right of the bottom edge by about a third of the card's height.
- The centre card is about 480x267 (about 720x400 at 1080p) and drawn on top.
  Neighbours are about 0.55 of that size, at full opacity, and sit tight
  against each other partly hidden behind the centre card. Only the outermost
  cards fade at the screen edges. About eight cards are visible.
- There are no captions, names, borders or selection outline.
- **Opening:** the band fades in quickly with all cards at neighbour size.
  The focused card grows when browsing starts.
- **Moving:** cards slide sideways smoothly. The newly focused card grows as
  the old one shrinks, with no overshoot.
- **Closing after a pick:** the chosen card goes translucent and the whole band
  disappears in about 150 ms. The wallpaper changes only after that.

### Wallpaper transitions
- The first change is a diagonal wipe with a straight edge, from the top-right
  corner to the bottom-left, about 500 ms long.
- The second is a vertical wipe with a wavy, saw-toothed edge, from top to
  bottom, about 250 ms long.
- Both start about 300-500 ms after the carousel closes. Neither uses a
  crossfade.

### Window motion
- Opening: a new window slides and fades into its tile while the others move
  aside.
- Closing: the window fades out quickly and its neighbours slide to fill the
  space.
- The motion is fast, roughly 150-250 ms, with ease-out and no bounce.

### Colour system
Every surface comes from one palette per wallpaper. Colours sampled from the
frames:

| Role | Red (eye) | Green (forest) | Purple (Gengar) |
|---|---|---|---|
| Terminal background | `#181110` | `#1b2526` | `#171b34` |
| Bar background | `#130e0d` | `#0c1110` | `#0b1119` |
| Accent (active workspace) | `#bc503d` | `#338472` | `#c456bf` |
| Clock pill | `#1a1816` | | `#101114` |
| fastfetch bar, middle block | `#6f372d` | | |

The pattern: backgrounds are the hue at very low lightness (about 7-12%), never
neutral black. The accent is the hue at medium lightness and fairly saturated.
Text stays a neutral light grey.

## What this desktop does differently (decided)
- **Fixed themes** (2026-11-18): we keep three hand-made themes (Ultra Dark,
  Catppuccin Macchiato, Tokyo Night) rather than deriving colours from each
  wallpaper. Ultra Dark with `fuji-frame.jpg` is the favourite.
- **About two wallpapers per theme** is enough (2026-11-18).
- **Our carousel keeps its own behaviour** (2026-11-18): resting on a card for
  600 ms applies it as a live preview, with a caption naming the theme. The
  video applies only on a pick.

## Ideas still worth taking
- A quieter bar shaped like the video's (see TODO.md 1C).
- A fastfetch colour bar of theme shades instead of ANSI dots (TODO.md 1D).
- An audio visualiser in the clock capsule (TODO.md 3, `cava`).
- Slide-based window open and close motion in Mango. Ours opens with `zoom`
  and closes with `fade`. Our kitty is already translucent
  (`background_opacity 0.6`).
- Backgrounds tinted with the theme's hue rather than neutral black. Ultra Dark
  is already slightly green (`#070908`), which is the same idea at a gentler
  strength.
- A wipe in place of the fade for wallpaper changes (TODO.md 1B).
