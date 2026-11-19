---
name: debug
description: Systematic debugging of a bug, failing test, build error or unexpected behavior - reproduce, isolate, hypothesise, fix, add a regression test, verify. Use before proposing any fix, especially when a first fix failed or the cause is unclear.
---

Find the root cause before changing code. Work the steps in order.

1. **Reproduce.** Get an exact, repeatable trigger (command, input, test). Read the full error and stack trace. If it is intermittent, gather evidence until you can trigger it or explain why not.
2. **Isolate.** Check recent changes (`git log`, `git diff`). Trace the bad value or state backward through callers to where it originates. In multi-component systems, log or inspect at each boundary to see which one breaks. Compare with similar working code.
3. **Hypothesise.** State one specific cause: "X is wrong because Y". Test it with the smallest change or probe, one variable at a time. If wrong, form a new hypothesis rather than stacking fixes.
4. **Fix.** Change the cause, not the symptom. One change.
5. **Regression test.** Write a test that fails without the fix and passes with it (do this before the fix when practical). Use the repo's existing test setup.
6. **Verify.** Re-run the original reproduction, the new test and the repo's wider checks. Report the evidence.

If three fixes have failed, stop and question the design or your assumptions instead of trying a fourth.

Adapted from the systematic-debugging skill in obra/superpowers.
