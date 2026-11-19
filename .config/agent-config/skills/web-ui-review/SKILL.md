---
name: web-ui-review
description: Verify a running web interface after UI changes or when asked for a visual or interaction review, using the repository's browser workflow and design references.
---

Read the applicable repository instructions and its skills catalog before selecting browser or design tools. Use an existing repository browser skill and pinned command when present; do not replace them with a global browser dependency.

Find the requested screen, relevant UI specification or reference, and the app's actual start command. Reuse an existing development server when suitable. Keep the review focused on changed behavior and nearby interactions; an inspection does not imply authorization for a redesign.

Inspect the running page at a representative desktop and narrow viewport, unless the product or request specifies another target. Exercise the changed controls and the relevant loading, empty, error, or success states where available. Check overflow, legibility, focus, keyboard access, and browser errors in the affected flow.

Capture useful evidence with the available browser tooling. Use the repository's artifact location, or a temporary directory when none is defined. Do not record credentials or sensitive page content in committed artifacts. Identify whether data and authentication are real, local, or mocked.

Report reproducible findings with route, viewport or state, expected and observed behavior, and evidence paths. Separate confirmed runtime observations from code-based suspicions. If the app cannot run, report the blocker and the checks that were possible; do not claim a visual pass.
