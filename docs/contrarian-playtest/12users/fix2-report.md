# Fix-2 经济/系统域修复报告

日期 2026-08-17 · 修复代理 Fix-2 · 基线 HEAD `c456b0b`（V2 核实报告：v2-verify-economy.md，9+1 项 CONFIRMED）
门禁结果：**upgrade / endless_contract / menu_catalog / campaign / event / market_test / save_integrity 全绿；campaign_strategy_sim 三策略全绿（重钉后）**。附加验证（非本域但触达改动代码）：menu / onboarding / operating_cost / dark_menu / localization / night / night_resume / research_brief / staff / input / prep_batch 全绿。`release_settings_check` 当前失败于「数字键改键拒绝」断言——该文件与 `input_prompts.gd` 正被其他代理并发修改（git dirty），与本域改动无关。

---

## 1. [S1-D2] 风味定位死档守卫

**修了什么**（game/autoload/upgrade_catalog.gd）：
- `buy_positioning()`：`positioning_id == "positioning_flavor" and level("smart_sugar") >= 1` 时直接 return false（600 币买 0 效果的入口封死）。
- 新增 `positioning_redundant(id)`（面板禁购钩子）与 `smart_sugar_redundant()`（反向警告钩子：已持风味时糖台一级无新增效果；不禁购，因它是糖台二级必经前置）。

**断言**（upgrade_check.gd）：糖台≥1 时 `buy_positioning("flavor")` 拒绝 + `positioning_redundant` 为真；反向 `smart_sugar_redundant()` 在风味持有时为真、买糖台后为假。原成功用例改为先 erase smart_sugar 再买风味，末尾补 `auto_sugar_after_milk()`（糖台一级独力生效，旧注释随之变准确）。

**面板接线待办**：upgrade_panel.gd（他人文件）定位卡买键按 `positioning_redundant()` 禁用并显示新键 3；糖台卡按 `smart_sugar_redundant()` 标注新键 4。

## 2. [S1] 定价占优 → per-item 出单节奏（含 P9-2 传说过滤）

**修了什么**（game/autoload/menu_catalog.gd）：
- 删除 `pricing_traffic_multiplier()`（原 ±2%/3% 全局到店间隔乘子）——三槽饱和区该摆动 ≈±0.5-1 杯被 RNG 噪声淹没，全溢价事实占优（V2#2）。
- 新增 `pricing_spawn_slots(item)`：主推**自创饮品**按价点偏离标准价的幅度决定该款在 `featured_for_spawn` 轮转数组中的占位数——让利（≤−2）3 槽 / 标准 2 槽 / 溢价（≥+2）1 槽；**type != "custom" 一律 2 槽（P9-2：传说不参与定价，与 price_options 对齐，传说被动承受客流修正的 bug 随之消除）**。
- `featured_for_spawn` 改为槽位权重轮转；风向匹配款槽位翻倍且优先入列——标准价三款的份额与旧行为完全同比例（2:2:2 ≡ 1:1:1；匹配款 4:2:2 ≡ 2:1:1），`sequence 0 = 匹配款` 的旧序保持。
- `should_offer` 全局节奏（FRESH 4 / STALE 6）不变——定价只改"该款被点的频率"，与 tooltip 本意一致。

**断言/重钉**（menu_catalog_check.gd）：`pricing_spawn_slots` 标准=2 / 让利=3 / 溢价=1 / 传说（含 authored 价差 ±2 的 red_bean_pudding 场景）=2；定价摆动前后 `traffic_multiplier()` 相等（不再动全局间隔）；轮转分布钉：让利款 8 次出单占 6 次（3/4 槽）、溢价款占 2 次（1/4 槽）。原 `pricing_traffic_multiplier()==0.98/1.03` 三断言删除（函数已移除）。

**重钉说明**：本项 + 第 6 项共同改变三策略逐日数字，见第 15 节。

**待拍板（文案）**：菜单板 budget tip「featured arrivals +2% faster」已失义（不再有全局提速）、premium tip「+3 coins per cup」对招牌/普通高估 50%（实际 +2）——需按档位实例化并改述为「该款更常/更少被点」（menu_board_panel + ui.csv，他人域）。

## 3. [S1] 无尽高印章锁死 → 可赢包络

**修了什么**（endless_contracts.gd）：新增 `WINNABLE_TARGET_CAP := 36`（V2 bot 实测满配 skilled 杯数极限 38-42 × 0.9 折）；`target_for` 在 stamps ×1.05^N 缩放**之后**对 streak/precision 两类 `mini(base_target, 36)`。stamps 24-25（40-42）、27+（46+）不再超过任何实测出杯数。

**断言**（endless_contract_check.gd）：stamps=25 → `target_for("precision_shift", 58) == 36`；stamps=30 → `target_for("streak_stage", 100) == 36`（原 day100 封顶 40 一并重钉为 36）。stamps=22 的既有断言（31×1.05²=34 < 36）不受影响保留。

## 4. [S1] 营收冲刺收敛态不可赢 → 系数 + 棘轮双修

**修了什么**（endless_contracts.gd）：
- `SPRINT_GOAL_FACTOR` 1.35 → **1.15**：收敛态要求 = 1.15×0.85×MA5 = 0.9775×MA5，落在 V2 实测冲刺弹性带（−2.7% ~ +15.5%，混合期望 +6.4%）内可重复达成。
- stamps 缩放后的冲刺目标再钳到**最近 5 日最佳营收 ×1.10**（`roundi` 防浮点上溢多 1 币）——棘轮上限 = 自己打出的最佳成绩，赢一天不会再把下次目标顶过可达线（V2 备选方案"挂 max 而非均值"）。

**断言**（endless_contract_check.gd）：MA5=[900×5]、goal_state=765 → `target_for("revenue_sprint",58) == 880`（=1.15×0.85×900）且 < 945（MA5+5% 余量，收敛态期望可赢）；stamps=30 时 == 990（最佳×1.10 钳制）；无历史回退 D16 目标 497 → **424**（368×1.15，重钉）。

## 5. [S2] next_rank_text 负数 + CONTRACT_RANK_MAX 死键

**修了什么**（endless_contracts.gd）：嵌套三元最内层 `20` → `20 if stamps < 20 else 30`——20-29 段正确显示距不朽档枚数（旧渲染 −2/−5 负数）；stamps ≥ 30 接入死键 `CONTRACT_RANK_MAX` 并带守擂计数（完成/失败，见第 13 项）。计数键 `CONTRACT_RANK_DEFEND_COUNT` 未进 ui.csv 前回退无参数的 `CONTRACT_RANK_DEFEND`（`%` 格式化未翻译键会报错，已做 TranslationServer 守卫）。

**断言**：`next_rank_text(22) == CONTRACT_RANK_NEXT [8]`、`(25) == [5]` 且不含 "-"；`(30)` contains `CONTRACT_RANK_MAX`，计数键存在时 contains 完成数。原 `next_rank_text(30) == CONTRACT_RANK_DEFEND` 重钉。

## 6. [S2] 定位计入 upgrade_score

**修了什么**（upgrade_catalog.gd）：`total_levels()` 持定位时 +1、`total_max_levels()` = 物品树 + `POSITIONINGS.size()`（14 → **16**）。未购定位：分子不变、分母变大（买定位由"评级黑洞"变为中性偏补偿）。

**断言/重钉**：upgrade_check 补 `total_max_levels()==16`、满树+定位 `total_levels()==15`；campaign_check mid 分数 71 → **70**（7/16×15=7），终局 100 → **98**（14/16×15=13），`score_label` "98 / 100"（grade 梯度 C/A/S 不变）。

## 7. [S2] best_score/routes_cleared 上主菜单

**修了什么**（scenes/main_menu/main_menu.gd `_refresh_summary_copy`）：`campaigns_completed > 0` 时追加 `MENU_LEGACY_SUMMARY` 行（历史最佳 %s·%d 分 · 路线 %d/3，读 `GameState.legacy` + `LegacyRoutes.completed_count()`）。键未进 ui.csv 前静默跳过（防 % 格式化报错）。

**New Shop+ 路线选择卡**：选择卡代码在 scenes/campaign_summary/campaign_summary.gd（他人文件），未动——该处可直接用 `LegacyRoutes.completed_count()`/`routes_cleared` 渲染 ✓/3 徽标，记录为接线点。

**断言**：纯 UI 展示，无新数值断言（menu_check / release_settings 实例化主菜单均绿）。

## 8. [S2] NG+ 首周日历

**修了什么**（game/autoload/daily_events.gd `event_for_day`）：路线表分支条件 `day >= 9` → `day >= 9 or LegacyRoutes.is_active()`——NG+ 从 D3 即用所选路线日历（D3-8 恰好走满一轮 6 事件）；首周目（无路线）行为不变（D9+ 借 trend 表）；**二遍强度弯仍只从 D9 起**，D1-2 保持 CALM。

**断言**（event_check.gd）：新增三路线 D3-8 序列 == 路线表、D3-8 无 `second_pass`、D1-2 CALM；无路线的 D3-8 教学轮换与 D9-14 trend 借表断言原样保留（默认门禁不受影响）。

## 9. [S2] P5-3 市场退款死分支 → 失败线 62 → 76（有界修，已实现）

**修了什么**（market_tests.gd）：`TIER_REGULAR` 62 → **76**。实现中发现 V2 独立方差假设不成立的深层事实：`deterministic_score` 的键共享长前缀，同名三晚偏移强相关（实测三晚偏移和取值于粗粒度集合，下界 **−14**，≈5.9% 概率）→ 上架最低 80 分杯的**可达**最差均分 = 75.33，不是理论独立的 72。62 线不可达；74 线仍不可达（需和 ≤ −19）；**76 线使最低品质上架杯有 ≈6% 真实落败率**（82 分杯不可败），regular 档收窄为 [76,78)。

**断言**（market_test_check.gd）：`TIER_REGULAR == 76`；4000 样本搜索和=−14 的 80 分杯 → 三晚结算 `outcome=="failed"`、`refund==3`（失败可达性从"注入 30 分假杯"变为真实可达路径）；面板副标题披露 76 线。

## 10. [S2] P5-6 品质阶梯首战役不可见 → **待拍板**（不动代码）

research_briefs.gd / research_brief_check.gd 均不在本代理文件权限内。V2 有界建议二选一，供拍板：
- (a) mastery 池条件 `level < 3` 放宽到 `level < 2`（全 Lv2 总量 256→128 xp，约 6-7 晚可清，balanced 首战役可见）；
- (b) D10+ 直接插入 balanced 轮换。
任一方案落地需同步重钉 research_brief_check 的 pair/mastery/balanced 生成顺序断言。

## 11. [S2] P6-F3 周租金额白天可见 → helper 已做，接线点在 day_shop

**修了什么**（operating_costs.gd）：新增 `rent_preview(day := -1) -> {day, amount, due_today}`——下一次租金的天数+金额+是否今日到期（rent_base(next_rent_day(d))，探针值 D6→{7,40}、D7→{7,40,due}、D8→{14,60}）。

**接线点（主会话接一行）**：day_shop.gd:2858-2859 HUD 成本胶囊改为 `GameLocale.text("DAY_HUD_COSTS_NEXT", [stock_cost, preview.day, preview.amount])`，ui.csv 的 `DAY_HUD_COSTS_NEXT` 增加第三个参数（"补货%d · 租金D%d·%d"）。operating_cost_check 复跑绿（helper 为纯增量）。

## 12. [S3] lunch_rush 读基准价 → 维持现状 + 文案标注（按 V2 推荐）

按 V2 判定实施**文案方案**：`event_match_bonus` 维持读价点字段（定价口径），代码不改。待办（menu board/ui.csv 域）：匹配行预告注明「按定价 ≤13（不含热度 +2）」，消除"卡面 14 币仍拿加成"的口径困惑。改读 `sale_price` 的方案会改变 strategy sim 的 `_menu_value` 选品与 D3/D12 菜单决策（三策略大重钉），V2 明示不推荐。

## 13. [S2] P8-F4 费用×7.3 奖励恒定 / P8-F5 30 后真空

**修了什么**（endless_contracts.gd）：
- P8-F4：新增 `refund_ratio_for(data, day) = min(0.55, 基础 + 0.002×(day−16))`——day16 锚点（0.35/0.34/0.36、退款 42）不变；D58 streak 退款 876×0.434=**380**（原 306，净成本 888 → 496 币/印章，回落到约日净入一半）。
- P8-F5：守擂机制最小实现 = next_rank_text(30+) 带完成/失败计数（数据 `endless.completed/failed` 结算时已在写）；CONTRACT_RANK_MAX 死键接入（见第 5 项）。

**断言**：`refund_ratio_for` D16==0.35、D58==0.434；`available_for_day(58)[0].refund == roundi(876×0.434)`；D16 `refund==42` 原钉保留。
**待拍板**：每 5 印章星章计数、更多守擂玩法为产品级，未实施。

## 14. P5-1 结算卡配方行（V3 域，一并修复）

**修了什么**：
- market_tests.gd `advance()`：result 增 `base/milk/toppings/sugar`（源自 night_lab 上架时写入的检验卡字段；`_string_array` 辅助）。
- game_state.gd `_normalize_market_settlement`：白名单同步保留四字段（base/milk `left(24)`、toppings 逐项 `left(24)` 上限 4、sugar clamp 0-100）——重进夜间结算卡配方不再丢失。
- ui/night_settlement_panel.gd：配方行在 `base` 非空时渲染（旧内存字典缺配方时整行隐藏，不再渲染空原料名）。

**断言**：market_test_check——advance 结果携带 base=="black_tea"/milk/toppings/sugar；面板卡片 contains 阿萨姆红茶真实配方文本（新增 `_panel_contains`）。save_integrity_check——24 卡压力存取后 `results[5]` 配方字段完整往返。

## 15. 三策略仿真重钉（campaign_strategy_sim.gd）

改动来源叠加：定价 per-item 化（第 2 项，含 P9-2 传说客流修正移除）+ 分母 14→16（第 6 项）+ 失败线 76（第 9 项，仿真不自创检验卡，无直接效应）。逐项精确钉定改为：

| 策略 | 旧钉 | 新钉 |
|---|---|---|
| careful | A · 10/14 · 34★ · 30-60 币 | A · 10/16 · **35★ · 90-150 币**（实测 118） |
| balanced | S · 10/14 · 42★ · 2350-2450 | S · 10/16 · 42★ · **2250-2350**（实测 2295） |
| growth | S · 10/14 · 42★ · 4500-4610 | S · 10/16 · 42★ · **4430-4530**（实测 4478） |

`_validate_campaign` 已加 2026-08-17 带日期迁移注释（仓库惯例）。careful 升 1★/现金翻倍主要为 jasmine_pure（价差 −2）不再给全局 ×0.98 提速的二阶效应；balanced/growth 现金回落 ~1% 为 red_bean_pudding ×1.03 拖速移除后的二阶效应。A/S/S 梯度与 angry 配额不变。

---

## 新键清单（ui.csv 由键 owner 添加；代码侧均已做缺键安全回退）

| 键名 | 英文 | 中文 | 状态 |
|---|---|---|---|
| `MENU_LEGACY_SUMMARY` | `\nBest Run: %s · %d pts · Routes %d/%d` | `\n历史最佳：%s · %d 分 · 路线 %d/%d` | 已接 main_menu；缺键时整行跳过 |
| `CONTRACT_RANK_DEFEND_COUNT` | `Defending · %d cleared / %d failed` | `守擂中 · 完成 %d · 失败 %d` | 已接 next_rank_text(30+)；缺键时回退 `CONTRACT_RANK_DEFEND` |
| `POSITIONING_REDUNDANT` | `Smart Sugar already owned — Flavor adds nothing` | `已拥有智能糖控台——风味无额外效果` | 待 upgrade_panel 接线（守卫已在 buy_positioning 生效） |
| `UPGRADE_SMART_SUGAR_REDUNDANT` | `Flavor positioning already automates sugar — this level adds nothing (tier II still applies)` | `「风味」定位已自动匹配糖度——一级无额外效果（二级仍有效）` | 待 upgrade_panel 接线 |
| `DAY_HUD_COSTS_NEXT`（改现有键） | `Stock%d · Rent D%d·%d` | `补货%d · 租金D%d·%d` | 待 day_shop.gd:2858 接 `OperatingCosts.rent_preview()` |

另：`CONTRACT_RANK_DEFEND`（ui.csv:895）降级为缺键回退文案，可保留或由 ui.csv owner 移除；菜单板两个定价 tip（budget/premium）需按第 2 节待拍板改写。

## 待拍板项汇总

1. **P5-6 品质阶梯**（第 10 节，二选一有界方案，需动 research_briefs.gd）。
2. **lunch_rush 口径文案**（第 12 节，menu board 匹配行标注"按定价 ≤13"）。
3. **定价 tooltip 改写**（第 2 节，+3 高估与全局提速措辞）。
4. **P8-F5 星章计数/守擂扩展**（产品级）。
5. **P2-F3 终局黑洞**高价荣誉出口、**P6-F2** 0★ 追赶指引 verdict 变体（内容级，非本次范围）。
