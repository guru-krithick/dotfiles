# Design data search

Offline BM25 search over the ui-ux-pro-max data set (MIT, see `design-data/LICENSE`). Python 3 standard library only. Results are candidates to weigh against the brief, PRODUCT.md and DESIGN.md; impeccable decides.

Run from the project root, by full path, in isolated mode so nothing from the project is imported and no cache is written:

```bash
python3 -I -B "<ui-dir>/references/design-data/scripts/search.py" "<query>" [options]
```

`<ui-dir>` is the directory containing the ui skill's SKILL.md.

## Modes

| Need | Options | Example query |
|---|---|---|
| Whole direction for a new product or page (pattern, style, palette, type, effects) | `--design-system -f markdown [-p "Name"]` | `"fintech dashboard calm"` |
| Same, as tokens | `--design-system --tokens css` or `--tokens dtcg` | |
| Dial the direction | `--variance 1-10 --motion 1-10 --density 1-10` (with `--design-system`) | |
| Palettes | `--domain color` | `"healthcare trustworthy"` |
| Font pairings | `--domain typography` | `"editorial serif modern"` |
| Single Google Fonts | `--domain google-fonts` | `"humanist sans variable"` |
| Visual styles | `--domain style` | `"brutalist dark"` |
| Product-type patterns, landing structure | `--domain product`, `--domain landing` | `"developer tool"`, `"hero social-proof"` |
| Charts | `--domain chart` | `"real-time ops dashboard"` |
| UX rules, icons | `--domain ux`, `--domain icons` | `"focus not obscured"` |
| Stack guidance | `--stack nextjs` (also react, shadcn, html-tailwind, vue, svelte, astro, swiftui, flutter, …) | `"suspense streaming"` |

Other options: `-n 1-20` results (default 3), `--json`, `--full` (no truncation).

## Rules

- One intent per query, 2-5 meaningful words. Pass `--domain` explicitly; auto-detection misroutes overlapping words such as "font".
- Check the top result actually fits the product and platform. Retry once with a narrower query; if still empty or off-topic, say no match was found and label any fallback as general guidance.
- Do not use `--persist`, `--page` or `--preview`: DESIGN.md and PRODUCT.md (impeccable) are the project's design record, not `design-system/MASTER.md`.
- A pinned brand, font or palette in the brief or DESIGN.md wins over any search result.
