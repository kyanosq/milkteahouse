# Iteration 29 — Persistent Lab Briefs

Date: 2026-08-10

## Outcome

The new affinity and mastery collections now have a short-horizon objective. One visible lab brief tells the player what to try next, pays back the cost of one directed experiment, and persists instead of silently rerolling when left unfinished.

## Rules and economy

- Odd-day generation prefers an unlocked unseen tea/milk pair.
- Even-day generation prefers the highest-XP unlocked ingredient still below Lv3 and requests two trial uses.
- Once all 12 pairs are seen and all usable ingredients reach Lv3, the fallback asks for a quality-75 cup.
- An incomplete brief persists across nights, including its exact progress.
- Completion immediately adds two inspiration. `completed_day` prevents a second issue or payout on the same operating day, including scene reloads.
- The payout is a refund of one real trial, not passive income; a player must spend the trial and satisfy the objective first.

## Visual QA and defects found

The brief card occupies the unused 390 × 66 region below the current-recipe summary. Gold communicates active work; mint communicates completion. Chinese and English objectives remain one line at 1280 × 720, while exact progress and reward are readable without opening another panel.

The first capture exposed two older night-lab regressions:

1. Journal and featured-menu pills inherited light text from flat buttons and disappeared against cream panels. Their normal/focus copy now explicitly uses cocoa, with coral hover/press feedback.
2. Multi-line trial results expanded below their panel and covered Close Lab. Feedback now lives in a fixed 316 × 76 scroll viewport and automatically reveals the newest result.

Accepted evidence:

- `iteration29-research-briefs/01-active-zh.png`
- `iteration29-research-briefs/02-active-en.png`
- `iteration29-research-briefs/03-complete-zh.png`

## Verification

`research_brief_check.tscn` covers all three brief types, unlock safety, mismatch behavior, two-step progress, cross-night persistence, one-per-day issuance, exact reward and bilingual copy. Night smoke covers a real legendary trial that completes a pair brief and finishes with the same budget it started with. Save migration accepts a valid v14 pair brief, forces the reward back to two and rejects invalid pair IDs.

All 22 project regression scenes passed. Godot import/compile passed. The real player save remained byte-for-byte unchanged at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

## Remaining evidence limit

Automation proves pacing bounds and state integrity but not whether players enjoy following the prompt. The next human campaign sessions should measure brief completion rate, voluntary off-brief experimentation and whether the two-point refund feels encouraging without making inspiration irrelevant.
