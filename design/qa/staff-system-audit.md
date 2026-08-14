# First Employee Slot Audit

Date: 2026-08-09  
Viewport: 1280 × 720  
Result: passed for the first-shop employee slice

## Gameplay contract

The Day 8 night lab opens one employee slot with three candidates. Candidate cards reveal functional stats, exact daily wage, and an introduction that hints at personality; the trait name and rules stay hidden until the first live trigger.

| Candidate | Trait | Benefit | Visible cost / management |
| --- | --- | --- | --- |
| Xiaoman | Slacker | Working state reduces rear-queue patience drain by 30%; wage 6 | Falls idle every 20–28 seconds; benefit stops until the player clicks the 3D actor or presses F |
| Taozi | Social Butterfly | All customers receive 20% more patience | Arrival interval is 12% shorter, increasing opportunity and workload; wage 12 |
| Acheng | Perfectionist | Correct cups gain 2 coins and the first wrong cup each day is intercepted without patience/combo loss | Every cup needs one additional shake; wage 14 |

The three choices are intentionally not linear upgrades. A managed Xiaoman produces the best tested net outcome, while ignoring the event is worse than operating alone. Taozi is the steady throughput choice. Acheng is a safety choice whose value is underestimated by a bot that never misreads an order.

Hiring costs 45 coins. Contract termination costs 20 and requires a second press. Wages are deducted and attributed at day settlement. If the till cannot cover the full authored wage, the shortfall schedules one debt-free rest day: all trait benefits and costs pause, no wage is charged, and the employee returns the following day. The title screen shows the current employee; the campaign ledger records staff days, wages, shortfalls, rest days, wake-ups, and rescues.

## Blender asset evidence

- Editable source: `assets_src/blend/staff_barista.blend`.
- Runtime asset: `game/assets/glb/staff_barista.glb`.
- Acceptance render: `assets_src/renders/staff_barista_preview.png`.
- Role-readable accessories: cream apron, mint pocket/straps, coral visor, name badge, headset, service towel, legs and shoes.
- Final budget: approximately 3,210 triangles and 173,740 bytes. The first pass was 7,596 triangles; targeted decimation retained the face and silhouette while bringing the asset inside the GDD's 2,000–3,500 character budget.

## Visual evidence

- `iteration12-staff/01-recruit-candidates.png` — three readable candidates, stats, wages, clues, hidden traits, and exact hire price.
- `iteration12-staff/02-hired-revealed.png` — in-role detail, revealed two-sided effect, days worked, and two-step dismissal entry.
- `iteration12-staff/03-social-staff-active.png` — Blender-authored actor in the live shop plus textual Social Butterfly state.
- `iteration12-staff/04-slacker-interaction.png` — tilted idle pose and persistent `拍醒 · F` recovery action.
- `iteration12-staff/05-staff-settlement.png` — wage and wake-up count attributed in settlement.
- `iteration12-staff/06-staff-resume.png` — employee identity persisted in the title-screen summary.

All captures fit at 1280 × 720. The employee status card now occupies the lower-right safe region. Iteration 32 moved it out of the upper-right after visual QA proved that position could cover the third contextual ingredient button; it now leaves contextual controls, the cup/status strip, order cards, primary action and the 3D employee operable.

## Automated evidence

`staff_check.tscn` verifies Day 8 unlock, all three hires, exact costs/wages, stat-hook multipliers, trait reveal, Slacker idle/wake state, Perfectionist extra shake/quality bonus, first wrong-cup rescue, full/partial wage settlement, one-day hook suspension, automatic return, bilingual rest messaging, campaign counters, and runtime GLB presence. Save migration also rebuilds wage/stats/trait identity from the authored candidate table instead of trusting dynamic save fields.

Day 8 Group Visit, newbie bot:

| Choice | Gross / net coins | Serve rate | Stars | Interpretation |
| --- | ---: | ---: | ---: | --- |
| No employee | 194 / 194 | 93% | 1★ | Baseline |
| Xiaoman, ignored | 195 / 189 | 93% | 1★ | Low wage does not pay for inattentive management |
| Xiaoman, actively woken | 214 / 208 | 100% | 1★ | Five wake-ups convert attention into the best result |
| Taozi | 208 / 196 | 100% | 1★ | Stable higher throughput with matching wage |
| Acheng, perfect bot | 193 / 179 | 85% | 1★ | Pays for safety the perfect bot never needs; unit test proves rescue behavior |

Day 14 with all shop upgrades remains 100% service for No Employee, Xiaoman, Taozi, and Acheng; Acheng finishes fewer cups because the extra shake remains a real late-game cost.

## Evidence limits and next gate

The deterministic bot can quantify throughput but cannot measure whether trait clues feel fair, whether waking Xiaoman is delightful or distracting, or the human value of Acheng's rescue. Include all three candidates in five human 14-day sessions and record hire share, wake response time, wrong-cup rescues, dismissals, and post-report replay choice.

The remaining rare traits should not be implemented as labels alone: Big Eater needs inventory, Pure Fool needs a research-clue queue, and Night Owl needs a multi-shift schedule. The next employee gate is human validation of whether wage reserve and the recovery day feel fair rather than merely legible.
