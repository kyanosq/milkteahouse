# Gameplay Playability Review — MilkTeaHouse (Iteration 56)

Date: 2026-08-15 · Method: deterministic player-model bots across the full
arc with a realistic-affordability upgrade path, plus an 8-screen visual
playability sweep of the current build (all post-iteration-53 UI changes).

## Playability criteria and verdicts

| # | Criterion | Evidence | Verdict |
| --- | --- | --- | --- |
| 1 | 首小时有胜利感（新手前 3 天 ≥2★，100% 服务率） | bots: D1 119/2★/100%, D3 185/2★/100%, D5(upg) 273/3★/100% | PASS |
| 2 | 压力公平：中位玩家（28% 返工画像+现实升级路径）无死亡螺旋 | D7 1★/93%（首个租金日，唯一怒客）→ D9 2★/100% → D12 1★/100% → D13/D14 1★/100%；服务率全程 ≥93% | PASS |
| 3 | 无升级惩罚引导升级而非不公平（升级墙是信号不是陷阱） | 无升级 D12 0★/69% vs 同日四件中级升级 1★/100%（291 vs 目标 296，差 5 币达 2★） | PASS |
| 4 | 精通回报显著（终章高潮感） | D14：熟练 702/3★（2.1× 目标）vs 新手 282/1★；campaign 门禁 growth 42/42·S | PASS |
| 5 | 日内节奏无长空档 | 14-24 单/120s ≈ 每 5-8 秒一次服务决策；备料双时钟并行填补间隙 | PASS |
| 6 | 信息高密度下仍可读（后期屏） | 08-day10-upgraded.png：三顾客无重叠、升级模型可见、耐心色带/目标拉伸行可读 | PASS |
| 7 | 每日目标与回报透明 | 04-settlement.png：2★徽章、"目标达成 · 净入 186"、"186/206 · 3★需288"、指标卡与账目齐全 | PASS |
| 8 | 事件可预习、可准备 | 03-event-briefing.png：挑战/机会双卡+明日预告+单一开店 CTA；事件 HUD 徽章全天在场 | PASS |
| 9 | 夜间循环可操作不拥挤 | 05-night-lab.png：四组货架完整在框内（SafeFrame 预算缩放生效）、任务卡/配方复述/明日预告齐全 | PASS |
| 10 | 成长系统可读可及 | 06-upgrade-store.png：四卡等级/价格/效果/余额/买不起态齐全；08 显示升级实体模型在店内可见 | PASS |
| 11 | 教学不阻挡上手 | 01-tutorial.png：5 步聚光灯式教学、跳过/下一步可达、文字无裁剪 | PASS（交互化仍为记录的延后项） |
| 12 | 全自动化质量门 | 25/25 核心检查 + 3/3 campaign 路线（本迭代后复跑） | PASS |

## Bot matrix (this review, deterministic seeds)

| Profile | Day | Upgrades | Earned | Goal | Stars | Serve | Angry |
| --- | --- | --- | --- | --- | --- | --- | --- |
| newbie | 5 | comfort1+shaker1 | 273 | 170 | 3 | 100% | 0 |
| newbie | 7 | comfort2+shaker1 | 204 | 206 | 1 | 93% | 1 |
| newbie | 9 | +tip1+shaker2 | 248 | 242 | 2 | 100% | 0 |
| newbie | 12 | +smart_sugar | 291 | 296 | 1 | 100% | 0 |
| newbie | 13 | late tree | 298 | 314 | 1 | 100% | 0 |
| newbie | 14 | late tree | 282 | 332 | 1 | 100% | 0 |
| skilled | 14 | late tree | 702 | 332 | 3 | 100% | 0 |

The intended arc reads as designed: early wins, one fair pressure beat at
first rent (D7), recovery, and a mastery-gated finale — the median player
never loses the queue (≥93% serve) and the no-upgrade collapse previously
measured is the game's upgrade-engagement signal, not unfairness.

## Visual sweep (8 screens, current build)

`design/qa/iteration56-playability/01-tutorial.png` … `08-day10-upgraded.png`
— tutorial step card, D7 pressure day (patience bands amber+mint, gold
golden-window fill, event chip), D3 event briefing, D7 settlement (star
badge, net-income verdict, 3★ stretch row), D9 night lab (shelf fit inside
frame), upgrade store, menu board, D10 fully-upgraded density. All pass
inspection: no clipping, overlap, or stale UI.

## Residual playability notes (recorded, unchanged)

- Tutorial remains read-only (interactive gating is a recorded product item).
- Reset-cup has no misclick grace (recorded).
- Week-2 (D9-14) event identity repeats week 1's cycle for the first
  campaign — the recorded depth item (needs art/gate decisions).
- Catch-up goal relief remains a recorded product decision (evidence in the
  contrarian-loop progress notes).

## Verdict

**High playability confirmed** across fairness, pacing, legibility,
progression and mastery payoff; no new playability defect surfaced by this
review. All quality gates green.
