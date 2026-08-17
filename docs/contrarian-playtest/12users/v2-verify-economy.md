# V2 对抗性核实 · 经济/进度域（10 组发现）

日期 2026-08-17 · 核实人：验证代理 V2 · 基线 HEAD `c456b0b`（25/25 核心 + 3/3 战役门禁全绿）
方法：只读代码 + 无头探针（`godot --headless --path game -s /tmp/v2_econ_probe*.gd`，动态 find_child 取 autoload）+ 独立 bot 矩阵 14 组（`/tmp/v2_p9_bots.log`、`/tmp/v2_p8_bots.log`）+ growth 战役仿真独立复跑（`/tmp/v2_sim_growth.log`）+ Python 独立模拟（P5-6 阶梯）。未修改任何 game/ 文件。

判定汇总：**9 项 CONFIRMED，1 项 CONFIRMED（附范围修正）**，0 项 REFUTED。多数发现给出的 file:line 与数值逐字复核无误；需要修正的只有 3 处细节（D2 文案细节、P5-6 的 17/272 应为 16/256、P8-F1/F2 的锁死边界比原报告略宽）。

---

## 1. [S1-D2] Day11「风味」定位与 smart_sugar≥1 完全重叠死档（P2-F1 / P9④）

**判定：CONFIRMED**（子断言「文案『更早生效』误导已购者」按现行本地化文案 REFUTED——见下）

独立证据：
- 效果同源：`game/autoload/upgrade_catalog.gd:162-163` `auto_sugar_after_milk() = level("smart_sugar") >= 1 or positioning() == "positioning_flavor"`。全仓 grep `positioning_flavor`：**唯一**消费点就是这一个函数（day_shop.gd:1120、shop_stage.gd:224/292 都走 `auto_sugar_after_milk()`）——风味没有任何糖步之外的隐藏效果，重叠是 100% 而非部分。
- 无购买守卫：`buy_positioning()`（upgrade_catalog.gd:136-146）只校验解锁日/互斥/金币；`upgrade_panel.gd:179-188` 买键同样只判 `coins >= 600`。已购糖台一级/二级（360/1180 币）后风味 = 600 币买 0。反向（先风味后买糖台一级）同理，糖台卡也无提示（upgrade_panel 无任何 smart_sugar×positioning 交叉文案，grep 证实）。
- 文案修正：源码常量（upgrade_catalog.gd:50）确含「且更早生效」，但 `positionings()` 用 `GameLocale.text("POSITIONING_POSITIONING_FLAVOR_EFFECT")` 覆盖，实际渲染文案（ui.csv:878）中英双语均为「全单免选糖（**等同智能糖控台一级**）」/ "matches Smart Sugar I"——**上线文案反而是诚实披露了等价性**，只是不随已购状态变化、也不构成购买拦截。P2-F1 引用的「更早生效」误导性表述从未出现在 UI。
- 探针复核：`upgrades={smart_sugar:1}` / `{positioning_flavor:1}` / 两者皆有 → `auto_sugar_after_milk()` 均 true；`total_levels` 有定位时仍只计 ITEMS（输出 1/14）。

最小修复：
1. 守卫（推荐）：`buy_positioning()` 在 `positioning_id == "positioning_flavor" and level("smart_sugar") >= 1` 时 return false；`upgrade_panel` 定位卡同条件禁用买键并显示新键 `POSITIONING_REDUNDANT`（「已拥有智能糖控台——风味无额外效果」）。反向：`_upgrade_card` 对 smart_sugar 一级在 `positioning()=="positioning_flavor"` 时加同样标注（可不禁购，因它是糖台二级的必经前置）。
2. 断言钉：upgrade_check 增加 `assert(not UpgradeCatalog.buy_positioning("positioning_flavor", false))` 前置 `GameState.upgrades["smart_sugar"]=1`（现 upgrade_check.gd:50 的成功用例在无糖台状态，不受影响）。
- 门禁影响：无数值改动，**不影响战役门禁基线**；仅 upgrade_check 增断言。

---

## 2. [S1] P9-1 全溢价事实占优（3 槽队列饱和）

**判定：CONFIRMED（附范围修正：满级树的非 rush 日处于边界态，±2-3% 客流 ≈ ±1 杯，仍在噪声带内）**

独立证据（全部本机重跑，`/tmp/v2_p9_bots.log`）：

机制复核：
- 生成门控 `day_shop.gd:258` `spawn_timer <= 0 and customers.size() < _max_customers()`（3 槽，:1666-1667）——队满即阻塞到店，到店量 = min(需求, 吞吐)。
- `pricing_traffic_multiplier`（menu_catalog.gd:215-227）只进 `traffic_multiplier()`（:208-210），后者只乘 `_spawn_interval()`（day_shop.gd:1673）。**主推订单节奏由 spawn_number 计数**（`should_offer`/`featured_for_spawn`，menu_catalog.gd:259-279，FRESH=4/STALE=6 固定间隔）——定价确实只改全局到店间隔、不改该款出单节奏，与 P9 描述一致。
- D9-14 基础间隔触底 4.0s（`clamp(randf_range(10,14) − 1.3×day, 4, 14)`，:1671）。

需求闭式解（120s / (4.0 × event.spawn_mult×二遍弯 × 0.88(3 热推))，路线无关）：
| 天 | 事件 | 需求估算 | bot 实测 served（本机） |
|---|---|---|---|
| D10 | brown_sugar | 38.6 | 38（满级树 F：38/38/0 怒） |
| D12 | lunch_rush | **56.0** | 35（零升级 A）/ 39（满级 B）/ 21（regular E，serve_rate 95%） |
| D13 | critic_day | 37.8 | 36（满级 G） |

结论复核：skilled 零升级产能 ≈ 32-36 杯 < 需求 36-39（非 rush）≪56（rush），**每天都在队满阻塞分支**；regular 深度饱和（21/56）。客流弹性 A/B：同种子同事件（D12 lunch）仅把 traffic 0.88→0.82（trend 路线，+6.8% 到店），served 35→37（+5.7%）；P9 自己的 A/B 是 36→35（−2.8%）——两次独立 A/B 的差值都在 ±2 杯 RNG 噪声带内，单款 ±2%/3% 的定价摆动（≈±0.5-1 杯）完全淹没在噪声里。goal 端无忧（本机 tau D12=2.09、D30=2.35-2.78，星线安全边际 ≫ ±40 币）。
范围修正：满 14/14 树 + skilled 在非 rush 日 served/需求 ≈ 98-100%（38/38.6、36/37.8），属「边界需求受限」，此时让利有真实但微小的正弹性（≈+0.7-1.2 杯 ≈ +12-25 币，与溢价直接收益 +14-21 币同量级，符号之争退化为噪声）。但真实 D9-13 对局最多 10/14 级（growth 门禁终局即 10/14，本机复跑 4555 币/S/42★），产能 < 需求仍成立——「定价窗口的对局落在饱和分支」对现实进度成立。

最小修复（按 P9 方向 (a)，改动最小且直指机制）：`should_offer`/`featured_for_spawn` 的 interval 改为按款累计：预算价点的款 FRESH 3 / STALE 5、溢价款 FRESH 5 / STALE 7（或等价的 per-item spawn_number 偏移），同时 `pricing_traffic_multiplier` 从全局间隔里移除（只留 per-item 节奏）。饱和区里「这款少来单、随机单不变」成为真实取舍。
- 门禁影响：**会影响**——spawn/出单节奏变化直接改 served/earned → campaign_strategy 三条钉值（stars/cash/grade，campaign_strategy_sim.gd:379-408）与 event_check/menu_catalog_check 均需重跑重钉。若只做 P9 方向 (c)（预告栏露队列利用率）则零门禁影响。

---

## 3. [S1] P8-F1 无尽高印章 ×1.05 需求锁死

**判定：CONFIRMED（锁死边界比原报告略宽：D58 精度类在 stamps≈24 起锁死、连击类 stamps≈24-25；stamps 27+ 无条件锁死）**

独立证据：
- 公式复核（endless_contracts.gd:84-99）：D58 基础 28+2+3=33、D100 封顶 40；×1.05^min(stamps,30)−20。探针注入 stamps 实测：**D58: 22→36, 24→40, 25→42, 27→46, 30→54；D100: 24→49, 25→51, 27→56, 30→65**（与 P8 报告数字逐一相符）。
- 出杯上限独立复测（满配 14/14 + skilled，`/tmp/v2_p8_bots.log`）：D58 brown 日：基线 H 36 杯；连击合约（×0.92）K 39 杯；**精度合约（×0.96/耐心0.88）J：served=38, perfect=38, angry=0**——即合约自己的修饰下全天极限 38 完美杯 < stamps24 目标 40。冲刺合约（×0.82）I 给到 42 杯（41 完美）是全矩阵最高，说明绝对物理上限 ≈42-44，但精度/连击类拿不到 0.82 的密度。
- 判定语义复核：零差评 = `angry==0 && perfect >= target`（:202）；连击 = `best_streak >= target`（:200，全天连续无返工）。bot 3% 返工率下 D30/D58 有 1-4 次返工（L/M/N reworks=4），连击类在 stamps≥22（目标 36）即基本不可赢。
- 无预警：`available_for_day`（:62-74）对目标可行性零校验，`available_for_day`/panel 照常出卡，费用照涨（见第 7 条探针数据）。

结论：stamps 24 起（D58 精度目标 40 > 实测同修饰极限 38；连击 40 > 39-返工），stamps 25+（42+）超过任何实测出杯数，stamps 27+（46+）在任何日型/任何玩家水平下不可达；D100 基础 40 × 1.63 = 65 更是空谈。原报告「专家级上限 45」略保守但结论方向与边界均成立。

最小修复：target_for 里对 streak/precision 两类加可赢性包络钳制：`base_target = mini(base_target, 36)`（= 实测极限 38-42 的 0.9 折，或由 `120/(4.0×0.72×0.94×0.90)×0.75` 之类的 spawn 地板推导常量），超出部分转为难度修饰（patience_mult 再 ×0.97/级）；面板卡片在 `target > 本店历史最高出杯×1.1` 时显示警示键并允许不签。
- 门禁影响：**不影响战役门禁**（合约 D16+）；影响 endless_contract_check 现有 stamps=22 断言（:71-74，22→×1.05²=36 > 钳制 36 恰好相等需确认）与需新增 `target_for stamps∈[24,30] ≤ 包络` 断言——按本方案 22→36 未超 36 钳制，原断言可保留；autoplay 合约 runs（BOT_CONTRACT）在 stamps=0 不受影响。

---

## 4. [S1] P8-F2 营收冲刺收敛态不可赢

**判定：CONFIRMED（范围修正：收敛态并非单日绝对不可赢，而是「结构性不可持续、越赢越输」——单次赢仍可能在非饱和日 + MA5 回落后出现，但每次赢都会把下次目标顶过可达线）**

独立复算：
- 不等式：`target = ceili(adaptive × 1.35)`（endless_contracts.gd:94），收敛态 `adaptive = max(base, 0.85×MA5) = 0.85×MA5`（:123）。探针注入 MA5=[900×5]、goal_state=765：adaptive=765，**sprint_target=1033 = 1.1478×MA5** ✓；MA5=850 → 975 ✓。
- 营收弹性独立复测（满配 skilled）：D58 brown 日 base 977 vs sprint 1128（**+15.5%**，出杯 36→42）；D30 lunch 日 base 894 vs sprint 870（**−2.7%**——饱和日 ×0.82 客流换不来杯量，rush 类日子弹性≈0）。两日均值 +6.4%，与 P8 的 +6~9% 一致；混合日历的期望弹性 < 不等式要求的 +14.75%。
- bot 2/2 success 是假阳性：autoplay.gd:61 每次 `GameState.endless = _new_endless_state()` → history 空 → 回退 base=380×1.35=513 < earned 1128/870。I/M 的 success 印章全部来自回退目标，收敛态从未被端到端跑过（本机复核确认 RESULT 中 contract target 未打印但 goal=380 回退链与 P8-F6 描述一致）。
- 棘轮：赢的一天 earned（1128）写入 MA5（record_day_performance 记 earned 无关成败，day_shop.gd:2548-2549）→ MA5 1001 → 下次目标 1149 > 任何可重复 earn（≈1128）→ 需 ~4 个正常日 decay 才回到可赢线。可持续赢率 ≤ ~20%，D58 每次净成本 = 费 1387 − 退款 499 ≈ **888 币/印章**——不是挑战而是金币泵。

最小修复（保号）：1.35 降到 1.15（收敛态要求 = 1.15×0.85 = 0.9775×MA5，落在 +6~15% 弹性带内可重复达成），或目标改挂 `1.05×max(MA5)`（5 日最佳而非均值，棘轮上限=历史最佳本身）；同时把 ×0.82 换成饱和日也有效的杠杆（每杯 +1 币联名补贴）。
- 门禁影响：**不影响战役门禁**；endless_contract_check:55 `offers[2]["target"]==497`（D16 回退 380×1.35）会随系数重钉，autoplay `BOT_CONTRACT=revenue_sprint` 的成败断言（p2 类用例）需重验。

---

## 5. [S2] P2-F2 定位不计分 / P2-F3 终局黑洞 / P2-F4 best_score 无处展示 / P2-F5 NS+ 首周日历

**P2-F2 判定：CONFIRMED。** `upgrade_score = total_levels/total_max_levels×15`（game_state.gd:715），`total_levels` 只遍历 ITEMS（upgrade_catalog.gd:179-190，14 级）；买定位写入 `upgrades[positioning_id]=1` 但不计入（探针：smart_sugar1+flavor → total_levels=1/14）。报告四维明细「设备 %d/%d」分母=14 同源（campaign_summary.gd:138-139）。craft 定位 +1/杯在 D11-14 ≈149 杯 ≈ +149 币 < 600 成本、评分无补偿——「不买最优」成立。
- 最小修复：`total_max_levels()` 计入 POSITIONINGS 各 1 级（14→16）并让 `total_levels()` 同步累加——但**会改变 campaign_check 满配 100 分断言与 strategy sim 的 craft 分/grade 钉值（careful A 线最危险）**，需三策略重钉；零风险替代：定位卡标「不计入评级 · 纯经营风格」纯文案。

**P2-F3 判定：CONFIRMED。** growth 仿真独立复跑：D11-14 夜间动作只剩 feature 轮换、**D14 actions=hold、终局 4555 币、10/14 级、score=96/S、42/42★**（`/tmp/v2_sim_growth.log`，与 P2 引用的数字逐位一致）。分母披露核查：craft 明细有「设备 %d/%d」（/14）但完美无 /140、momentum「结余 %d · 话题 %d」无 /900、/36（ui.csv:439-443）——900/36/140 三上限全 UI 零披露属实（P2 措辞未包含设备 /14，无冲突）。
- 最小修复：文案加分母（CAMPAIGN_DIM_*_DETAIL 补 `/900``/36``/140`）零门禁影响；高价荣誉出口（D13-14 sink）是新增内容、无门禁影响。

**P2-F4 判定：CONFIRMED。** 全仓 grep `best_score|best_grade|routes_cleared`：UI 消费点仅 campaign_summary.gd:162（报告页脚一次性）；main_menu `_refresh_summary_copy`（main_menu.gd:301-318）只显示当前 run + 无尽段位 + 当前路线，无任何历史成绩；New Shop+ 路线卡无已通关徽标。
- 最小修复：主菜单进度卡追加一行 `MENU_LEGACY_SUMMARY`（历史最佳 %s·%d · 路线 %d/3）+ 路线卡对 routes_cleared 加✓；纯 UI，零门禁影响。

**P2-F5 判定：CONFIRMED。** `event_for_day`（daily_events.gd:111-127）：day≤2 CALM；day 3-8 **无条件** `ROTATION[slot]`，只有 `day >= 9` 才查 `ROUTE_ROTATIONS`。探针对照：route-less 与 rush NG+ 的 D3-8 事件 id 序列完全一致（`d1-8 identical: true`），D9 起才分叉。继承数值 80 币+3 灵感（game_state.gd:787-810，start_new_shop_plus S 档）属实。
- 最小修复：`event_for_day` 的重排分支条件从 `day >= 9` 改为 `day >= 3`（或 `LegacyRoutes.is_active() and day >= 3`）。**门禁影响**：event_check.gd:12-25 钉的是无路线日历（route-less D9-14 借 trend 表），D3-8 断言在无路线下不变——默认门禁不受影响；但 NG+ 起步 bot（p2 的 ngp_*）与任何 CAMPAIGN_ROUTE 仿真的逐日事件将变化，若 CI 有路线档钉值需重钉。

---

## 6. [S2] P6-F2 新手二周营收墙（缺追赶指引）/ P6-F3 周租金额白天不可见

**P6-F2 判定：CONFIRMED（定性部分）。** bot 数据（D9 五样本 4×0★、中位怒走 5、tau 0.46-0.77）按任务书采信为已知输入；本机独立核对定性断言：全 ui.csv 无任何「落后/追赶/差距/catch up」类键（grep 证实）；0★ 判词 `DAY_RESULT_VERDICT_0`「还在热身，明天再来」（ui.csv:280）、夜间提示 `DAY_RESULT_UPGRADE_HINT`「现有 %d 金币 · 研发室可购买店铺升级」（:319，day_shop.gd:2698 引用）——两者都是通用文案，不指向具体解压升级（shaker/smart_sugar），「缺追赶指引」成立。P6 自己已核实墙可爬（净入恒正、dd=1-3），修复不应削 goal 曲线。
- 最小修复：stars==0 结算日 verdict 换定向变体（如 `DAY_RESULT_VERDICT_0_CATCHUP`：「营收落后目标 %d%%——自动摇茶机能减少每杯操作」按缺口%与未购 shaker 动态选）；零数值改动、零门禁影响。

**P6-F3 判定：CONFIRMED。** day_shop.gd:2858-2859：非租金日 HUD 药丸 = `DAY_HUD_COSTS_NEXT`「补货%d · 租金D%d」（ui.csv:190）——只有天数无金额；租金日当天才切 `DAY_HUD_COSTS_TODAY`「租金≤%d」（:191）。金额仅存夜间两处（账本注脚 :2790-2791、升级面板预留行）。探针：rent_base(7)=40、(14)=60、(21)=80、next_rent_day(3)=7 ✓。
- 最小修复：`DAY_HUD_COSTS_NEXT` 加金额参数（「租金D%d·%d」），距租金日 ≤2 时药丸换琥珀色；纯文案+着色，零门禁影响。

---

## 7. [S2] P8-F3 next_rank 负数 / P8-F4 签约费×7.3 奖励恒定 / P8-F5 30 印章后真空

**P8-F3 判定：CONFIRMED（探针直证）。** `next_rank_text`（endless_contracts.gd:256-260）嵌套三元最内层封死 20。注入实测：stamps=20 →「再获 **0** 枚印章升级店招」、22 →「-2」、24 →「-4」、25 →「**-5**」、27 →「-7」；30+ 才切「传奇守擂中」（CONTRACT_RANK_DEFEND, ui.csv:895）。CONTRACT_RANK_NEXT（:137）`%d` 直接吃负数，无分支。真实下一档 30（不朽，rank_name :241-242 证实）。
- 最小修复：最内层补 `20 if stamps < 20 else 30`；endless_contract_check 增 `next_rank_text(25).contains("5") 且不含 "-"` 断言（现只测 13/30）。零数值改动，不影响战役门禁。

**P8-F4 判定：CONFIRMED（探针直证）。** 费用 `base×(1+0.15×(day−16))`（:77-81）实测锚点 streak **120/372/876**、sprint **190/589/1387**（D16/D30/D58，与 endless_contract_check:52/59 钉值一致）。奖励侧恒定：成功 = +2/2/3 灵感 + 1 印章 + 退款 0.35/0.34/0.36（ITEMS :8-48 与 resolve :220-229），与天数无关；满配店日净 720-790（本机 operating_net 721-927），费用日增 +18-28 追不上存钱速度——「×7.3 价格买 D16 同款商品」成立。
- 最小修复：退款比例随 growth 上调使净成本 ≈ 日净入 25-35%（如 refund_ratio += 0.002×(day−16) 封顶 0.55）；或费用封顶 ~日净入 1.2×。**门禁影响**：endless_contract_check:53 `refund==42`（D16 锚点）在封顶/微调方案下 D16 不变可保留，D58 类断言需新增；不影响战役门禁。

**P8-F5 判定：CONFIRMED。** 三重封顶代码直证：rank_name 最高 30（:241-242）、需求缩放 `mini(stamps,30)`（:98）、next_rank_text ≥30 静态守擂文案（:257-258 无数字）；`resolve` 失败只清 streak（:230-233）不掉段——「守擂」无任何机制背书。`CONTRACT_RANK_MAX`「最高店招已达成」（ui.csv:136）全仓 grep 零引用，死键属实。叠加第 3 条：stamps 30+ 时三张卡目标 54+/65+ vs 实测极限 42，「守擂期实际可玩合约数为零」成立。
- 最小修复：DEFEND 文案带计数（「守擂中 · 完成 %d · 失败 %d」数据已有 completed/failed）；中期可加每 5 印章星章计数；清理或启用 RANK_MAX 死键。文案级，零门禁影响。

---

## 8. [S2] P9-2 传说击穿定价 / P9-3 溢价 tooltip +3 高估

**P9-2 判定：CONFIRMED（探针直证）。** `pricing_traffic_multiplier`（menu_catalog.gd:215-227）遍历全部 `featured_items()` 按 `tier` 查 PRICE_STANDARD、按 `price` 差值计 Δ，**无 `type=="custom"` 过滤**；对照 `price_options`（:231-235）有过滤——两者不一致，与 P9 描述完全一致。探针（注册传说并主推）：`legend:jasmine_pure`（普通/10，差−2）→ **mult=0.98**；`legend:red_bean_pudding`（普通/14，差+2）→ **mult=1.03**；三传说全主推 → 1.01（理论应 1.00）；两者 `price_options().size()==0`（不可调价却被动承受客流修正）。data/recipes.json 复核：10 张作者配方恰只有这两张价差 ≥2（其余 ±1/0），与 P9 一致。
- 最小修复：`pricing_traffic_multiplier` 循环内加 `if String(item_data.get("type","")) != "custom": continue`（与 price_options 对齐）；menu_catalog_check 增「纯传说主推 pricing_traffic_multiplier()==1.0」断言。**门禁影响**：strategy sim 的 research_plan 注册的传说价差全在 ±1 内（classic 12/brown 18/taro 16/jasmine_coco 15/oat 13/oolong 13/red_bean 14——**red_bean_pudding 差 +2 会触发**：balanced 策略 research 含 red_bean_pudding，若被主推则全局间隔 ×1.03 → served/earned 微降 → 三策略钉值可能漂移 1-2 币内，需重跑重钉）。

**P9-3 判定：CONFIRMED（探针直证）。** tip 文案静态「+3 coins per cup」（ui.csv:755，zh 同文英文未译属另一条）；价表实测（menu_catalog.gd:13-18）：爆款 21−18=**+3**、招牌 17−15=**+2**、普通 14−12=**+2**——招牌/普通被高估 50%。附带：budget tip「featured arrivals +2% faster」实际是全局到店间隔（见第 2 条），语义含糊属实。
- 最小修复：tip 按档位实例化（按钮组已知 delta：`MENU_BOARD_PRICE_PREMIUM_TIP_%s` 或带 %d 参数「+%d coins per cup」）；「featured arrivals」改为「到店间隔」（与实现一致）。纯文案，零门禁影响。

---

## 9. [S2] P5-3 市场退款死分支 / P5-6 品质阶梯首战役不可见

**P5-3 判定：CONFIRMED。** 写入路径穷举：`GameState.tests.append` 全仓唯一在 `night_lab._on_shelf`（night_lab.gd:1108），而 `pending_quality` 仅当 `score >= RecipeLab.SHELF_SCORE`（=80，探针直证）时设置（:1034-1036）→ 所有受检杯 quality ≥ 80。结算：每档得分 = quality + posmod(hash,17) − 8 ∈ [q−8, q+8]（market_tests.gd:69-77），三晚均分下界 = 80−8 = **72 > TIER_REGULAR 62**（:9）；均分 < 62 需 3(q−8) < 186 → **q ≤ 69**——与 80 上架闸门的不等式死区 [70,79+] 完整成立，`outcome=="failed"`（+3 灵感退款，:56-58）正常游玩不可达。market_test_check 用手工注入 quality=30 测退款，掩盖不可达性（P5 附注属实）。
- 最小修复（三选一，推荐 b）：失败线 62 → 74（quality 80 的最差均分 72 落败、82 均分 74 边缘），使「上架即保底」变成「80 分杯仍有 ~三成失败风险、退款成为真实安全网」，配套 market_test_check 改注入 quality=72 断言 failed。数值改动不触战役门禁（market_check 独立）。

**P5-6 判定：CONFIRMED（数值修正：16 种原料/256 xp，非 17/272）。** 生成条件复核（research_briefs.gd:89-120）：balanced 是最后一档，需 `unseen pairs 空` 且 `practice 空`（= 全部已解锁原料 `level>=3`，:139）；`level_of = xp/8+1`（game_state.gd:84-85）→ **Lv3 = 16 xp**；原料数 = 3 底+3 奶+10 料 = **16**（排除 none），全 Lv3 = **256 xp**（P5 写 17/272 系把 none 计入，结论不变）。独立模拟（Python，最优打包：每晚 8 试、每杯双小料全打未满料、优先未见相性）：**D14 结束 12/12 相性全见但仅 13/16 原料到 Lv3，balanced 全程未出现**——与 P5 探针结论一致。结构性下界：10 料 ×16 xp ÷ 每杯 2 料位 = **≥80 杯最优打包**，D12 才解锁的 cheese_foam 只剩 3 晚 ×16 料位；14 夜总试做 ≈ 103-112 杯且早期料池受限——首战役 14 天数学上不够。
- 最小修复：mastery 池条件从 `level < 3` 放宽到 `level < 2`（Lv2=8xp，总量 128 xp，约 6-7 晚可清），或 D10+ 直接插入 balanced 轮换。**门禁影响**：research_brief_check 断言 pair/mastery/balanced 顺序与 QUALITY_LADDER 常量（若改档位需重钉）；不影响战役门禁数值。

---

## 10. [S3] P9 lunch_rush 读基准价不读实收价 / P11 无经济项

**lunch_rush 判定：CONFIRMED（探针直证）。** `event_match_bonus` lunch 分支 `int(item_data.get("price", 99)) <= 13`（menu_catalog.gd:479）读价点字段；`sale_price = price + (2 if hype_remaining>0)`（:504-505）。探针：classic_boba 价点 12 + 热卖 → sale_price=14 但 lunch bonus=4（匹配）；价点 14 → bonus=0。即卡面显示 14 币的杯仍拿「≤13」加成，与卡面口径不一致。量级（D12 前夜调 13 的价值 ≈ +20-25 币/天 > 全溢价本身）与 P9-6 一致，未独立复跑拆账但 A/B 实测 event_bonus=55-57（D12）与机制吻合。
- 最小修复（零门禁影响的口径方案）：匹配行文案标注「按定价 ≤13」；或改读 `sale_price(item_data) <= 13`——**后者会改匹配结果**（热卖中价点 12 的款从匹配变不匹配）→ strategy sim 的 `_menu_value`（campaign_strategy_sim.gd:336-346）用它选主推 → D3/D12 等午餐日菜单选择变化 → **三策略钉值大概率重钉**。推荐先做文案方案。

**P11 判定：CONFIRMED（无经济项，无可核实对象）。** p11-speedrun.md 四条发现（F1 离场单击交付、F2 改键守卫、F3 教学门控、F4 菜单板落盘 IO）全部为输入/门控/IO 类，无经济发现——任务书此条仅为记录，无需修复。

---

## 附：本机独立证据索引

- 探针：`/tmp/v2_econ_probe.gd`（无尽目标/next_rank/定位/日历/租金/收敛目标）、`/tmp/v2_econ_probe2.gd`（传说定价/午餐匹配/价点差）——输出已在文中引用
- bot：`/tmp/v2_p9_bots.log`（A-G：D10/D12/D13 饱和矩阵）、`/tmp/v2_p8_bots.log`（H-N：D30/D58 满配合约矩阵，含 42 杯物理上限与 +15.5%/−2.7% 弹性两极）
- 仿真：`/tmp/v2_sim_growth.log`（growth 独立复跑，STRATEGY_ASSERT 全绿 4555/S/42★，D14 hold 复证 P2-F3）
- 关键复算：需求闭式解 36-39（非 rush）/56（rush）vs 产能 21(regular)/32-36(skilled 零升级)/38-42(skilled 满配)；冲刺不等式 1.1478×MA5 vs +6.4% 实测弹性；退款死区 q∈[70,79]；阶梯下界 80 杯最优打包 vs 14 夜 ≈103-112 杯
