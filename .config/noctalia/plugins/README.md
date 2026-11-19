# Desktop plugins

`themes/` is the local theme carousel (Super+Shift+T). `service.luau`
(`guru/themes:switcher`) keeps `theme catalog` ready, draws missing cards with
`theme cards`, shows and hides the overlay with Mango's `themes` key mode, and
applies one switch at a time through `theme set <id> --wallpaper <path>`.
`carousel.luau` is a full-screen overlay layer on the focused output: the ring
of cards, the dwell timer and the motion. It takes keys as IPC events
(`noctalia msg plugin guru/themes:carousel all press left`, `release left`,
`close`; also `next`, `prev`, `next-theme`, `prev-theme`, `apply`). Requires
plugin API 52 (Noctalia v5.5.0). Tests: `.config/theme/tests/theme_carousel_test.lua`.

`stdout/` is an unchanged copy of `tordex/stdout` 1.1.0 from
https://github.com/noctalia-dev/community-plugins/tree/29a0756b71f19a38ace074d195be3a14cd6700f6/stdout
(revision `29a0756b71f19a38ace074d195be3a14cd6700f6`). Its manifest declares
MIT and credits tordex; upstream supplies no separate licence file. The included
thumbnail and translations come from the same revision.

The path source in `shell.toml` keeps the pomodoro widget available offline,
including on a fresh Stow install. To update, replace the directory from a
reviewed upstream revision and update this note.
