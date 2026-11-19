# Quick diagnostic

Eight yes/no checks from the Refactoring UI method (wondelai/skills `refactoring-ui`, MIT; see `../NOTICE.md`). Use it as a fast score alongside impeccable's `critique` rubric, never instead of it.

| Check | If no | Fix |
|---|---|---|
| Does the hierarchy still read when squinting or blurred? | Elements compete | Raise primary/secondary contrast in size, weight or colour |
| Does it work in grayscale? | Colour is doing hierarchy's job | Strengthen size, weight and spacing first |
| Is there enough white space? | Most designs are too dense | More space, especially between groups |
| Are labels quieter than values? | Labels compete with data | Smaller, lighter or small-caps labels |
| Does spacing follow one scale? | Arbitrary values read as noise | Stick to the project scale (e.g. 4/8/16/24/32/48/64) |
| Is text width constrained? | Long lines tire readers | Body text around 45-75ch (`max-w-prose`) |
| Does all text pass contrast? | Accessibility failure | Meet WCAG AA (4.5:1 body, 3:1 large text and UI) |
| Do shadows match elevation? | Elements float at the wrong level | Use a shadow scale tied to purpose (raised, overlay, modal) |

Score: `round(passed / 8 × 10)`. 10 = all pass; 9 = one gap; 6-8 = two or three gaps; 5 or less = four or more. Report the score and the failing rows to fix.
