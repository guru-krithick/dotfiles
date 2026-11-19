# Motion details

Supplements impeccable's `animate` playbook (which owns purpose, duration bands, reduced motion and capture/review). Sources: Emil Kowalski's design-engineering skill (MIT) and Motion's AI-kit best practices (rewritten, not copied). See `../NOTICE.md`.

## Should it animate?

| How often the user sees it | Decision |
|---|---|
| 100+ times a day (shortcuts, command palette) | No animation |
| Tens of times a day (hover, list navigation) | Remove or cut to the minimum |
| Occasionally (modals, drawers, toasts) | Standard animation |
| Rarely (onboarding, celebrations) | Room for delight |

Never animate keyboard-initiated actions. Every animation needs a purpose: spatial consistency, state change, explanation, feedback, or avoiding a jarring jump.

## Easing and duration

- Entering or exiting: ease-out. Moving on screen: ease-in-out. Hover/colour: `ease`. Constant motion: linear. Never ease-in for UI; it delays the moment the user is watching.
- Built-in curves are weak. Defaults: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`, `--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`, drawer `cubic-bezier(0.32, 0.72, 0, 1)`.
- Press 100-160 ms; tooltip/small popover 125-200 ms; dropdown 150-250 ms; modal/drawer 200-500 ms. Exit faster than enter. Slow where the user decides (hold-to-delete 2 s linear), fast where the system responds (release 200 ms ease-out).
- Match the product: crisp and no overshoot for finance/ops tools; softer and slightly longer for expressive brands.

## Component rules

- Pressables: `:active { transform: scale(0.97) }` (0.95-0.98) with a ~160 ms ease-out transition.
- Never enter from `scale(0)`; use `scale(0.95)` plus `opacity: 0`.
- Popovers, menus and tooltips scale from their trigger (`transform-origin: var(--transform-origin)` in Base UI/Radix). Modals stay centred.
- Tooltips: delay the first, then open adjacent ones instantly with no animation.
- Rapidly retriggered UI (toasts, toggles): CSS transitions, which retarget, not keyframes, which restart.
- Mount animation without JS: `@starting-style`. Hover effects only inside `@media (hover: hover) and (pointer: fine)`.
- A crossfade that still looks like two objects: add `filter: blur(2px)` during the swap (keep blur small; it is costly in Safari).
- Move by the element's own size with percentage translates (`translateY(100%)`).
- `clip-path: inset(...)` animates reveals, tab highlight colour swaps, hold-to-confirm fills and comparison sliders without extra layout.
- Stagger groups 30-80 ms per item, non-uniform; never block interaction while it plays.

## Gestures

- Dismiss on velocity as well as distance (e.g. `distance / ms > 0.11`), so a flick works.
- Past a boundary, add increasing friction instead of a hard stop.
- Capture the pointer once a drag starts; ignore extra touch points during a drag.
- Every drag/swipe action also needs a click/tap and keyboard path (`Reorder` is pointer-only).

## CSS or Motion (motion/react)

| Effect | Use |
|---|---|
| Colour, shadow, opacity on a class change; spinners and shimmer | CSS transition / keyframes |
| Fade or slide in on mount, nothing interrupts it | CSS `@starting-style` |
| Exit before unmount | Motion `AnimatePresence` + `exit` (React removes the node at once) |
| Layout change (reorder, expand, grid change) | Motion `layout`; one element moving between places: shared `layoutId`, unique per instance (`useId()`) |
| Height to/from `auto` | Motion `height: "auto"` with `overflow: hidden`; small content only |
| Drag, swipe, interruptible toggles, momentum | Motion springs (`{ type: "spring", duration/visualDuration, bounce: 0.1-0.3 }`); springs keep velocity when interrupted |
| Scroll-linked, in-view entrances | Motion `useScroll` / `whileInView` |

- Import from `motion/react` (never `framer-motion`; never both installed). Server components: `import * as motion from "motion/react-client"`; hooks and `AnimatePresence` need a client component.
- Reduced motion: one `<MotionConfig reducedMotion="user">` at the app root keeps opacity/colour and drops transform/layout animation. In CSS, keep opacity fades and remove movement under `prefers-reduced-motion: reduce`.
- `AnimatePresence` stays mounted with the condition inside and a stable `key` per child; `mode="wait"` for in-place swaps, `mode="popLayout"` when siblings use `layout` (parent must be positioned).
- Radix: animate via `asChild` + a `motion` child, hoist open state, put the `forceMount` component inside `AnimatePresence`. Base UI: pass the `motion` element through `render`; for self-managed popups hoist state and use `Portal keepMounted`.
- Do not read a MotionValue during render; use `value.on("change", …)`, not `onChange`; prefer `useTransform(value, input, output)`.

## Performance

- Animate `transform`, `opacity`, `clip-path`, `filter`. Not width, height, padding, margin, top/left.
- CSS transform/opacity animations run on the compositor and stay smooth while the page loads; main-thread JS (Motion layout animations, `onUpdate`, inertia, per-frame motion values) can drop frames. Prefer CSS for predetermined motion, JS for dynamic, interruptible motion; WAAPI (`element.animate`) for programmatic CSS-speed animation.
- Do not drive per-frame changes through an inherited CSS variable on a container; set `transform` on the element itself.
- `will-change` only on elements whose animation falls off the compositor, and remove it afterwards. In per-frame callbacks avoid allocation.

## Debugging

Slow animations to 2-5x or step frames in DevTools: check that properties stay in sync, origin is right, and crossfades read as one object. Test gestures on a real touch device. Review the next day with fresh eyes.
