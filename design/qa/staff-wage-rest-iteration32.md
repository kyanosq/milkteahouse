# Iteration 32 — Staff Wage Integrity and One-Day Recovery

Date: 2026-08-10

## Outcome

Partial wage payment no longer preserves a permanent fully active employee. If the till cannot cover the authored daily wage, it pays the available cash, records the visible shortfall and schedules the next operating day as a rest day. The rest carries no wage and no debt; the same employee returns automatically one day later.

This is deliberately a recovery beat instead of a dismissal spiral. A player who has just failed an entire shift can still operate solo, rebuild cash and keep the staff relationship.

## Duty boundary

`StaffCatalog.is_on_duty()` is now the single gameplay gate. On a rest day:

- Xiaoman provides no rear-queue patience reduction and cannot create a slacking event.
- Taozi provides neither +20% patience nor the paired traffic increase.
- Acheng provides neither +2 coins nor the extra shake and cannot intercept a wrong cup.
- The 3D employee is absent; the fixed staff card names the shortfall, says every effect is paused and gives the exact return day.

The closing panel shows paid/due wage and scheduled rest. The night staff panel repeats the next-shift plan in both its status and wage copy. On the next night it reports rest completion and the following day's return.

## Save integrity

Save v17 adds `rest_day`, `wage_shortfall` and cumulative `wage_shortfalls` to the current staff record, plus campaign counts for shortfall and rest days. Loading no longer trusts staff-owned wage, stats or trait fields. It finds the authored candidate by ID, rebuilds static fields from `staff.json`, clamps dynamic values and rejects an unknown employee.

## Balance evidence

Regular Day 10 deterministic runs with 500 opening coins:

| State | Gross | Operating net | Served | Staff bonus | Wage |
|---|---:|---:|---:|---:|---:|
| Solo | 305 | 249 | 25 | 0 | 0 |
| Acheng on duty | 322 | 264 | 23 | 46 | 14 |
| Acheng resting | 305 | 250 | 25 | 0 | 0 |

The one-coin rest/solo cost difference is order randomization. Throughput, bonuses and action length otherwise return to the solo boundary.

## Visual QA

The 700×540 closing ledger has enough space for the wage shortfall without moving the primary CTA. Visual QA exposed a pre-existing P1 overlap: the 264×146 upper-right staff card covered the third contextual ingredient button. The accepted 272×146 card moves to the lower-right safe region, clear of contextual controls, cup/status strip, primary action and the 3D employee. It fits both localized rest messages; English wraps to two lines without clipping. The empty 3D staff position reinforces the disabled state without making color the only signal.

- `iteration32-staff-wage-rest/01-shortfall-zh.png`
- `iteration32-staff-wage-rest/02-shortfall-en.png`
- `iteration32-staff-wage-rest/03-rest-day-zh.png`
- `iteration32-staff-wage-rest/04-rest-day-en.png`
- `iteration32-staff-wage-rest/05-active-card-zh.png`
- `iteration32-staff-wage-rest/06-active-card-en.png`

## Verification

The expanded `staff_check.tscn` covers full wage, partial payment, exact shortfall, next-day duty lock, neutral trait hooks, absent 3D actor, bilingual staff-panel copy, zero rest wage, automatic return and campaign counters. `save_migration_check.tscn` proves forged wage/trait fields are replaced by authored Acheng data and clamps the shortfall. All 24 project regression scenes pass. The real player save remains unchanged at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
