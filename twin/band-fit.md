# The dkk twin fit — v1.0 against v1.1, Phase 1b

> **Historical fit:** the local `whole_image.py` and `check_binding_law.py`
> readings below belong to the dated experiment. Those diagnostics are retired;
> their manifest, binding-join and comparison-domain limits are preserved in the
> [migration record](../../../goldbox-wiki/wiki/games/dkk/legacy-diagnostics.md).
> Current verification is `.venv/bin/python -m goldbox.repo gate --repo .`.
> The fit data and its operand-masking limits remain unchanged.
> Current source calls the corresponding `anchor`/`ufc` slot `EmptyMod`;
> historical labels below and in `pair-matrix.json` preserve this experiment.
> [Native initializer and linkage evidence](../../../goldbox-wiki/wiki/climb/dkk/empty-module.md).


Measured 2026-09-20 at HEAD `2772b682`, `goldbox` 0.9.49.

⛔ **Guardrail, restated because it binds everything below.** Nothing in this directory
seeds a `dsNNNN` binding, a name, a type or a band declaration. `twin_finder` masks
operands by construction and is blind to DGROUP. These numbers order work and price a
port. `runtime-and-twin-evidence.md` owns the rule.

## What was run

    .venv/bin/python -m goldbox.twin_finder --selftest
    .venv/bin/python -m goldbox.twin_finder \
        --title-a dkk10:drive_c/DKK.V10/EXE-UNP/START.EXE,drive_c/DKK.V10/EXE-UNP/GAME.OVR \
        --title-b dkk11:drive_c/DKK.V11/EXE-UNC/START.EXE,drive_c/DKK.V11/EXE-UNC/GAME.OVR \
        --out v11/twin/dkk10-v-dkk11.json --md v11/twin/dkk10-v-dkk11.md

`--selftest` passes. Both sides are the **unpacked, pristine** images — a packed image
compares compressed noise. `EXE-UNC`'s `STATE.txt` records the patch reversion and its
WizWorx witness; `EXE-UNP` is the v1.0 unpacked load module, OVR unchanged.

Both sides: 19 resident segments (18 units + DGROUP) and 35 overlay records.

`dkk10-v-dkk11.json` / `.md` are that run verbatim. `pair-matrix.json` is the evidence for
the fit: **all 1,586 role-matched pairs** (19×19 resident + 35×35 overlay) re-scored with
`score_pair()` and labelled with the unit each segment belongs to, so every figure below
is recomputable from it without re-reading a binary.

## The independent attribution — what makes a fit possible here

`class` can only be fitted against pairs whose class is known *without* the tool.
Two joins give that, and neither passes through Capstone.

**Residents.** `whole_image.py`'s per-unit reference byte counts are ground truth on the
v1.0 side (that tree reproduces both shipped files whole, 0 of 346,116 bytes differing).
`twin_finder`'s resident segments come back in ascending paragraph order, and their
lengths reproduce `whole_image`'s unit list **in order, 18 of 18 on each side**, the only
slack being `rootmain`'s paragraph rounding (647→656, 642→656).

**Overlays.** For every record, `code + fixup` equals `whole_image`'s reference size for
the unit at the same index: **35 of 35 on v1.0, 35 of 35 on v1.1.** Control: re-run the
same test against the unit list shifted by one — **0 of 34 on each side**, so the test
discriminates and the index→unit join is not a coincidence.

⚠ On the v1.1 side the *name* attached to an index comes from our own link, not from SSI.
What corroborates it is that v1.0 (ground truth) and v1.1 name the same 35 overlay units
in the same order — and the same 18 resident units, `anchor`→`ufc` being a rename of the
same 16-byte slot in our two trees.

⇒ That yields **54 same-unit pairs** (independently known RELATED) and **1,532 cross-unit
pairs** (independently known UNRELATED).

## Known-class pairs, read off the bytes

Four pairs classed by direct byte comparison with no disassembler in the loop:

| pair | direct reading | independent class | tool printed |
|---|---|---|---|
| `dos` ↔ `dos` | 704 B both sides; **2 differing bytes**, one 2-byte run, word delta **exactly +0x728** | offset-shifted | `offset-shifted` ✔ |
| `crt` ↔ `crt` | 1,568 B both sides; 1,518 of 1,568 bytes differ (3.19% identical) | structural, not identical | `structural` ✔ |
| `diskbrk` ↔ `diskbrk` | 272 B both sides; 198 of 272 differ, 4 of 5 readable word deltas are +0x728 | related — structural at minimum | `none` ✘ |
| `dos`(v1.0) ↔ `crt`(v1.1) | 695 of 704 bytes differ (1.28% identical) | none | `none` ✔ |

★ **`dos` is the pair the fleet has never had.** Two bytes apart, and the single word they
disagree on is a DGROUP offset shifted by the exact constant `check_binding_law.py`
carries as `LAW = (0x740, 0x734, 0x728)` and measures at +0x728 on 38 of 38 tested
bindings. Two instruments that fail differently, agreeing on the constant.

`diskbrk` is the counterexample, and it is the whole story of the fit: a pair that is
demonstrably related in the bytes and that the packaged bands reject.

## The fit — the bands SEPARATE, and one of them is wrong for this title

| population | byte-identical | offset-shifted | structural | none | pruned |
|---|---|---|---|---|---|
| same-unit (known RELATED), n=54 | 1 | 2 | 33 | 18 | 0 |
| cross-unit (known UNRELATED), n=1,532 | 0 | 0 | 0 | 821 | 711 |

★ **Precision is perfect and the populations do not overlap.**

- Every twin call the tool makes is correct: **36 of 36**, and `crossmap`'s best-scoring
  partner is the right unit for **36 of 54** A segments, **wrong for 0**.
- **0 of 1,532** known-unrelated pairs got any twin class. Positive control on that zero:
  the identical predicate over the same-unit population returns 36, so it is not a broken
  test.
- Maximum coverage among the 821 *scored* unrelated pairs is **0.485**. The lowest
  coverage among the 54 related pairs is **0.647** (`copyinit`), setting aside the
  16-byte `anchor`/`ufc` pair, which is too short to yield a single matchable token run
  and scores 0.000. The gap `[0.485, 0.647]` is empty, and `COV_STRUCT = 0.60` sits
  inside it.

⇒ The plan's kill condition — *"the dkk fit cannot separate pairs of known class"* — **is
not met.** `class` is usable on this title. What the fit also shows is which band is
carrying the separation and which is only suppressing.

### Every one of the 18 misses is bound by RAW_STRUCT

All 17 scored misses fail on `raw < 0.30`; the 18th (`anchor`/`ufc`, 16 bytes) has too few
tokens to score at all. `COV_STRUCT` rejects nothing that `RAW_STRUCT` does not.

| RAW_STRUCT | same-unit called a twin | cross-unit called a twin |
|---|---|---|
| **0.30** (packaged) | 36 of 54 | 0 of 1,532 |
| 0.25 | 41 of 54 | 0 of 1,532 |
| **0.20** | 46 of 54 | 0 of 1,532 |
| 0.15 | 46 of 54 | 0 of 1,532 |
| 0.10 | 47 of 54 | 0 of 1,532 |
| 0.05 | 49 of 54 | 0 of 1,532 |

Lowering `COV_STRUCT` from 0.60 to 0.30 changes nothing at all: 36 of 54 throughout.

The reason `RAW_STRUCT` costs so much and buys so little here: **the highest raw-byte
coverage anywhere in the unrelated population is 0.041**, and no unrelated pair clears
`COV_STRUCT` at all. `raw` was fitted to reject shared RTL idiom between two *different
titles* (`kbd670` vs `waitKey`, cov 0.81 / raw 0.19). A same-title, two-release run has no
such impostor: `cov` alone already separates the classes completely.

★ **The fit for a version-to-version run: `RAW_STRUCT = 0.20`.** It recovers 10 of the 18
misses, admits none of 1,532 impostors, and keeps a ~5× margin over the 0.041 ceiling the
unrelated population actually reaches. `COV_STRUCT = 0.60` and `SIZE_RATIO = 4.0` need no
change — nothing same-unit was pruned (0 of 54).

⚠ **This does not license lowering `RAW_STRUCT` for a cross-TITLE run.** It was measured
against dkk v1.0↔v1.1, where the unrelated population is 35 overlays of one game against
35 of the same game. The Curse↔PoR impostor population is a different one, and `raw` is
the band that guards it. The honest statement is narrower than "the band was too high":
**`raw` is a cross-title guard, and in a version-to-version run it is inapplicable.**

⇒ No `[twin_finder]` override is written in `goldbox.toml` by this work. The fit is
recorded here; changing the classifier the whole fleet reads is a separate decision.

### Two further readings of the output

- **The top row of the default table is not a code twin.** `0xd7b ↔ 0xbce` is DGROUP
  against DGROUP — `whole_image`'s header names both paragraphs, and the segment lengths
  are the `initialized data` rows, 32,128 and 33,984. `twin_finder` runs it through a
  16-bit code tokeniser, so its `cov 0.98` is an artifact of disassembling data. Its
  `raw 0.963` remains a valid byte-run measurement and is the more interesting number.
- **`delta` corroborates the layout law from the code side.** 30 of 54 same-unit pairs
  recover a modal shift of exactly **+0x728**. Control: 14 of 821 scored cross-unit pairs
  do (1.7%). A code-level statistic over masked immediates lands on the constant the
  DGROUP binding front derived from source, having failed differently to get there.

## The six overlays that carry no record in our link

At the HEAD above, `whole_image.py` reported these as `not overlaid in our link`. The later converged v1.1 link contains all 35 records; the diagnostic
command is historical. Sizes are record code
bytes; *unmatched* is `(1 − raw) × v1.0 size`, the v1.0 bytes with no run in v1.1.

| unit | v1.0 | v1.1 | cov | raw | delta | class | unmatched | v1.0 traps |
|---|---|---|---|---|---|---|---|---|
| party | 24,214 | 23,785 | 0.9691 | 0.5689 | +0x728 | structural | 10,439 (43.1%) | 22 |
| charview | 14,022 | 14,070 | 0.9528 | 0.4871 | +0x728 | structural | 7,192 (51.3%) | 31 |
| camp | 13,514 | 13,069 | 0.9321 | 0.4390 | +0x728 | structural | 7,581 (56.1%) | 37 |
| effects | 13,014 | 12,073 | 0.9005 | 0.3516 | +0x728 | structural | 8,438 (64.8%) | 110 |
| spells | 25,540 | 23,656 | 0.9174 | **0.2794** | +0x728 | **none** | 18,404 (72.1%) | 120 |
| eclcmds | 12,926 | 12,635 | 0.9138 | **0.2545** | +0x728 | **none** | 9,636 (74.5%) | 67 |

All six clear `COV_STRUCT` comfortably; `spells` and `eclcmds` are the two that fall below
`RAW_STRUCT` and print `none`. Under the fitted `RAW_STRUCT = 0.20` all six are
`structural`. Every one of the six recovers +0x728, so all six are genuine ports of the
v1.0 unit rather than rewrites.

★ **Ranked by port cost, cheapest first:**

1. **party** — the most mechanical of the six by both readings (cov 0.969, raw 0.569) and
   the lowest divergence rate at 43.1%, despite being the largest. Structure carries.
2. **charview** — cov 0.953, raw 0.487, and the *smallest absolute* unmatched volume of
   the six at 7,192 bytes. Nearly the same size in both releases (14,022 → 14,070).
3. **camp** — cov 0.932, raw 0.439, 7,581 unmatched. Still clearly mechanical.
4. **effects** — the divergence rate jumps to 64.8% and the coverage is the lowest of the
   six. 110 traps in v1.0 means the wiring cost is high on top of the port cost.
5. **eclcmds** — 74.5% of the unit has no counterpart, the worst rate of the six, and the
   raw score sits below the packaged band. ⚠ Carrying v1.0's structure across here would
   be wrong for three quarters of the unit.
6. **spells** — worst on both axes that matter: 18,404 unmatched bytes, nearly twice the
   next-worst, at a 72.1% divergence rate, with 120 traps in v1.0. Largest of the six and
   the most diverged. ⛔ Do this one last, and treat v1.0's `spells` as a reference to
   consult rather than a source to port.

⚠ **The low scores are the output that matters.** `spells` and `eclcmds` are the warning
this run exists to produce. The gradient is real and monotone in the numbers: the top
three share roughly half their bytes with v1.0, the bottom three roughly a quarter.

⚠ The v1.1 reference trap counts for these six read `2/0`, `3/0`, `4/0`, `97/0`, `18/0`
and `101/0` — the left figure is not a like-for-like count while the unit is unlinked, so
the table quotes v1.0's, which are ground truth.

## The TPOV → FBOV redistribution

⛔ **The shipped run cannot answer this question.** `crossmap()` opens with
`if sb.role != sa.role: continue`, so a resident↔overlay pair is never scored. The claim
in `runtime-and-twin-evidence.md` that the tool "maps that redistribution systematically"
does not hold for the tool as it stands.

Scored separately for this report — all 19×35 resident↔overlay pairs each way, 596 scored
and 734 pruned by `SIZE_RATIO`:

- **0 of 596 cross-role pairs reach any twin class.** Highest coverage anywhere in that
  population is 0.400, below even the 0.485 within-role impostor ceiling. Positive control
  on the zero: the same scorer returns 36 twins over the same-unit population.
- Both trees carry **18 resident units and 35 overlay records, with the same names in the
  same order**.

⇒ **No unit changed tier across TPOV→FBOV.** The partition is identical; what moved is
volume inside it.

| tier | v1.0 | v1.1 | change |
|---|---|---|---|
| resident code | 49,680 | 44,640 | −5,040 (−10.1%) |
| DGROUP (initialized data) | 32,128 | 33,984 | **+1,856 = +0x740** |
| overlay code (35 records) | 248,784 | 242,893 | −5,891 (−2.4%) |
| load image | 87,344 | 82,336 | −5,008 |
| DGROUP paragraph | 0x0d7b | 0x0bce | −0x1ad |

★ **`sound` is 3,872 of the 5,040 bytes the resident tier lost** (9,840 → 5,968, 77% of
the shrink), and it carries the lowest coverage of any resident pair at 0.737. The
remaining 1,168 are spread thin: `gameini1` −592, `joystick` −128, `textrend` −112,
`daxio` −96, `system` −80, `blit` −64, `mouse` −48, `border` −32, `coreinp` −16 — which
sums to the 5,040 exactly. **Seven resident units are the same size in both releases**:
`ufc`, `diskswap`, `diskbrk`, `copyinit`, `crt`, `dos`, `overlay`. `rootmain` is 656 in
both at paragraph granularity and 647 → 642 in `whole_image`'s reference sizes, so its
−5 sits inside the rounding and outside the 5,040.

⚠ And the DGROUP growth is **+0x740**, the top value in `check_binding_law`'s
`LAW = (0x740, 0x734, 0x728)`. Stated as an observation, not a derivation — the peel front
owns that arithmetic and this file seeds nothing into it.

⇒ The Q2 finding in `whole-image-conversion.md` — a *string* living in v1.0's `GAME.OVR`
and v1.1's `START.EXE` — is not contradicted by any of this. This scan works at segment
granularity and can only answer whether a whole unit changed tier. An individual datum
moving between tiers is invisible to a tool that masks operands, and always will be.

## Files

- `dkk10-v-dkk11.json`, `dkk10-v-dkk11.md` — the `twin_finder` run, verbatim
- `pair-matrix.json` — all 1,586 role-matched pairs, unit-labelled; the fit's evidence
- `band-fit.md` — this file
