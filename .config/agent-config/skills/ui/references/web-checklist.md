# Final web checklist

Last pass over the changed web UI code before calling the work done. Condensed from Vercel's Web Interface Guidelines (vercel-labs/web-interface-guidelines `command.md`, MIT; see `../NOTICE.md`). Project conventions (copy style, casing, libraries) override these where they differ. Report findings as `file:line - issue`, grouped by file; skip files that pass.

**Accessibility.** Icon-only buttons have `aria-label`; form controls have a label; decorative icons `aria-hidden`. `<button>` for actions, `<a>`/`<Link>` for navigation, no clickable `div`/`span`. Images have `alt` (`""` if decorative). Async updates (toasts, validation) use `aria-live="polite"`. Semantic HTML before ARIA; headings in order; skip link to main content; `scroll-margin-top` on anchored headings.

**Focus.** Every interactive element has a visible `:focus-visible` style; no `outline: none` without a replacement; `:focus-within` for compound controls; sticky headers and overlays never cover the focused element.

**Forms.** Meaningful `name` and `autocomplete`; correct `type` and `inputmode`; paste never blocked; labels clickable; no spellcheck on emails, codes, usernames; checkbox/radio and label share one hit target. Submit stays enabled until the request starts, then shows progress. Errors inline beside the field, focus the first on submit. Warn before leaving with unsaved changes.

**Motion.** `prefers-reduced-motion` respected; only `transform`/`opacity` animated; no `transition: all`; correct `transform-origin` (SVG: on a `<g>` with `transform-box: fill-box`); animations interruptible; autoplaying motion over 5 s has pause/stop.

**Typography and content.** `…` not `...`, including "Loading…"; curly quotes; non-breaking spaces in units and shortcuts (`10&nbsp;MB`, `⌘&nbsp;K`); `tabular-nums` for numbers that are compared; `text-wrap: balance`/`pretty` on headings. Containers handle long, short and empty content (`truncate`, `line-clamp`, `break-words`, `min-w-0` on flex children); empty arrays and strings never render broken UI.

**Images and performance.** `<img>` has width and height; below the fold `loading="lazy"`, above-fold hero `fetchpriority="high"`. Lists over ~50 items virtualized or `content-visibility: auto`. No layout reads in render; batch DOM reads and writes. Controlled inputs cheap per keystroke. `preconnect` asset origins; preload critical fonts with `font-display: swap`. Video instead of animated GIF.

**Navigation and state.** URL holds filters, tabs, pagination and open panels; links are real links (Cmd/middle-click work). Destructive actions confirm or offer undo.

**Touch and layout.** `touch-action: manipulation`; deliberate `-webkit-tap-highlight-color`; `overscroll-behavior: contain` in modals, drawers, sheets. No text selection during drag. Gestures have tap and keyboard alternatives. `autoFocus` only for a single primary desktop input. Full-bleed layouts use `env(safe-area-inset-*)`; no unintended horizontal scroll; flex/grid over JS measurement. Zoom never disabled (`user-scalable=no`, `maximum-scale=1`).

**Theming.** Dark themes set `color-scheme: dark` on `<html>`; `<meta name="theme-color">` matches the background; native `<select>` has explicit background and text colours.

**Locale and hydration.** Dates and numbers through `Intl.*`; language from `Accept-Language`/`navigator.languages`, not IP; `translate="no"` on brand names and code. Inputs with `value` have `onChange` (or use `defaultValue`); guard date/time rendering against hydration mismatch; `suppressHydrationWarning` only where unavoidable.

**States and copy.** Hover, active and focus states are visibly stronger than rest. Active voice; specific button labels ("Save API key", not "Continue"); errors say how to fix; numerals for counts.
