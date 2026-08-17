# P7 New Shop+ 二周目

- 试玩视角：P7「New Shop+ 二周目玩家」——刚以 S 级收官首战役，带着 80 币 + 3 灵感开新店，依次试走翻台（rush）/口碑（precision）/潮流（trend）三条店招路线，审查二周目路线体验：路线差异可感知性、继承奖励、第二周事件日历、路线结构规则（rush 锁第三主推槽×0.85 到店、precision 评论家×1.25、trend 夜间自动锁槽）、3/3 收藏进度可读性。
- 方法：10 次 autoplay bot（三路线 × D1/D3/D5/D9/D12，regular+skilled，含 80 币开局；日志 `/tmp/p7_*.log`）、4 次战役策略模拟（无路线 + 三路线全 14 天，`/tmp/p7_sim*.log`）、event_check / campaign_check 无头回归、结构规则代码走读 + 一次 `-s /tmp/p7_pin_check.gd` 探针尝试（Godot `-s` 不加载 autoload，探针失败，trend pin 结论改以代码推演 + 说明）。未修改任何 `game/` 文件。
- 引擎：Godot 4.6.3 headless。

bot 数据速览（route= 路线 / route_bonus / route_triggers 为路线结算字段）：

| 路线 | 日 | 画像 | earned/goal | served | route_bonus | route_triggers |
|---|---|---|---|---|---|---|
| rush | 5 | regular | 451/184 | 23 | 12 | 6 |
| precision | 9 | regular | 436/262 | 24 | **0** | **0** |
| trend | 5 | regular | 454/184 | 24 | 9 | 3 |
| precision | 9 | skilled | 747/262 | 35 | 22 | 22 |
| rush | 12 | skilled | 659/320 | 34 | 22 | 11 |
| precision | 12 | skilled | 764/320 | 34 | 13 | 13 |
| trend | 12 | skilled | 625/320 | 35 | 15 | 5 |
| rush | 1（80币开局） | regular | 184/106 | 13 | 6 | 3 |
| none（基线） | 1 | newbie | 140/98 | 11 | 0 | 0 |

14 天模拟：无路线 gross 6838 / route_bonus 0；rush 7127/174；precision 6956/214；trend 6929/81（41/42★）。

无头回归：`[EVENT] passed rotation=6 routed_calendars=3 …`、`[CAMPAIGN] passed grades=C/A/S … new_game_plus=3routes/80/+3`。

## 发现（证据/复现/期望vs实际/修复方向/置信度，S0-S3）

### F1: rush「牺牲第三主推槽」在三处 UI 全部按 3 槽陈述——进度条、副标题、满槽报错都骗玩家还有第 3 槽（S1）

- 证据:
  - `game/autoload/legacy_routes.gd:84-85` — `featured_slot_limit()` 周转区返回 2；`game/autoload/menu_catalog.gd:119-120` 的 `featured_limit()` 是路线感知的正确入口，`ensure_normalized`/`set_featured`/`_auto_feature` 都用它。
  - 但 UI 三处全部绕过它，直接用常量 `MenuCatalog.FEATURED_LIMIT`（`menu_catalog.gd:6`，恒为 3）：
    - `game/ui/menu_board_panel.gd:170-171` — 主推面板进度 `MENU_BOARD_PROGRESS`（"％d/%d 槽"）分母传 `MenuCatalog.FEATURED_LIMIT` → rush 玩家整晚看到「2/3 槽」。
    - `game/ui/menu_board_panel.gd:172` + `ui.csv:739`（MENU_BOARD_SUBTITLE「最多选择三款」）——对 rush 是假说明。
    - `game/ui/menu_board_panel.gd:435` + `ui.csv:761`（MENU_BOARD_FULL「三个主推槽已满，请先移出一款。」）——rush 玩家尝试加入第 3 款时收到的事实错误反馈：他永远不可能有三款。
    - `game/scenes/night_lab/night_lab.gd:782-784` — 研发室顶栏药丸 `NIGHT_MENU_PILL`（"主推 %d/%d"）同样传 `FEATURED_LIMIT` → 夜间常驻显示「主推 2/3」。
  - bot 佐证槽位确实被锁死：rush 三次带 `BOT_MENU`（注册 3 个传说）的运行 `menu_hot` 恒为 2，其余路线为 3；auto_feature 在第 2 款后即拒绝。
- 复现路径 / 推理链: S 级收官 → New Shop+ 选「翻台街区」→ 随便玩到某个夜晚 → 打开「明日主推」：顶部显示「2/3 槽 · 2 款热卖」，副标题说「最多选择三款」→ 点第三款「加入明日主推」→ 红字「三个主推槽已满，请先移出一款」→ 玩家移出一款再试第三款，仍然满——结论只能是「游戏坏了」，而不是「这是本路线的代价」。
- 期望 vs 实际: 期望 rush 的结构代价（两槽换速度）在唯一展示它的界面上自洽呈现（2/2 槽、满槽文案点名路线）；实际所有文案按 3 槽写死，路线的核心取舍对玩家不可理解，只剩下「加不进去」的挫败。
- 修复方向: 三处 UI 改调 `MenuCatalog.featured_limit()`；`MENU_BOARD_FULL`/`MENU_BOARD_SUBTITLE` 增加路线感知变体（如 rush：「周转区只有两个主推槽——这是 ×0.85 到店速度的代价」），把这层取舍写成正面规则而非报错。
- 置信度: 高（静态代码 + bot 数据双证；纯展示层，行为无争议）。

### F2: trend 夜间自动锁槽在「无契合项」时仍强锁 0 号槽——把玩家手选主推换成零收益的任意款（S1）

- 证据:
  - `game/autoload/menu_catalog.gd:125-147` `apply_trend_pin()`：`best_bonus := -1` 起扫；`event_match_bonus` 对不契合项返回 0，`0 > -1` 成立 → 只要有任一 `formula_available` 的菜单项，`best_id` 就会被置为「第一个可用项」（bonus=0）。随后 `best_id in featured_menu` 不成立时执行 `GameState.featured_menu[0] = best_id`。
  - 即：当明日事件没有任何契合款（例如明日 critic_day 只契合「招牌」档，而玩家全是普通档自创）时，锁定的不是「最佳匹配」而是「菜单里第一个可用项」——一个事件收益为 0 的款，顶掉玩家 0 号槽的 deliberate 选择。
  - 契合判定见 `menu_catalog.gd:472-493`：六事件分别要求 ≤1 小料且价 ≤13 / 无奶低糖 / 黑糖 / 招牌档 / 爆款档 / ≥2 小料——二周目早期菜单（多为普通档自创）经常一个都不中。
  - 回归缺口：全仓 grep `apply_trend_pin` 仅 `night_lab.gd:94` 一个调用点，`menu_catalog_check.gd`/`event_check.gd` 均无覆盖（我尝试用 `-s /tmp/p7_pin_check.gd` 做运行时验证，Godot 4.6 `-s` 不加载 autoload 而失败；此发现为代码推演，但 12 行逻辑无歧义）。
- 复现路径 / 推理链: 选「潮流街区」→ 夜里自创两款普通档，主推只放自己想要的 B 款 → 进入研发室触发 pin：明日是探店日（只契合招牌档）→ 无契合 → pin 把 0 号槽替换成菜单第一个可用项 A（0 收益）→ 玩家次日发现主推被换成一个既不契合也不是自己选的款，且没有任何提示。
- 期望 vs 实际: 期望「自动锁定明日事件最佳匹配」在无匹配时是 no-op（保留玩家选择）；实际无匹配时锁一个任意款，净效果是「游戏随机改我的主推」。
- 修复方向: `apply_trend_pin` 增加 `if best_bonus <= 0: return`；顺手补一条单测（trend + 无契合菜单 → featured 不变）。
- 置信度: 高（逻辑推演，路径唯一；未运行时复现，已注明）。

### F3: trend 自动锁槽/手动覆盖「只当晚生效」整套规则零 UI 呈现——无锁定标记、无提示文案（S2）

- 证据:
  - `ui.csv` 全量 grep 无任何「锁定/自动/次夜重锁/pin」相关键（仅命中无关的 RECIPE_BOOK_TARGET_SET 等）；`menu_board_panel.gd` 的 `_menu_card()`（205-308 行）对 0 号槽与其它主推卡渲染完全一致（`MENU_BOARD_FEATURED` 一视同仁），无锁徽标、无「已按明日风向自动锁定」角标。
  - 卡片排序按 `MenuCatalog.items()` 菜单序而非槽序，「第一个主推位」这个概念在面板里根本不可见——被 pin 的款与玩家自选的款无从区分。
  - 规则只存在于代码注释：`menu_catalog.gd:123-124`「手动覆盖在当晚有效，次夜进入研发室时重新锁定」、`night_lab.gd:93`。玩家第一次得知规则的方式是：次夜打开面板发现昨晚的改动消失了。
  - 对比同作其它路线：precision 有紫色 70% 刻度 + tooltip + 「N秒 · +1」就绪标签（`day_shop.gd:1794-1804`、`ui.csv:485-486`）；rush 有店招脉动 + 周转计数；trend 的结构规则（锁槽）完全不可见，玩家能感知的只有「契合 +3」。
- 复现路径 / 推理链: trend 玩家夜里手动把 0 号槽换成自己想要的主推 → 次日夜重进研发室 pin 重锁 → 面板上无任何变化说明（叠加 F2 时换成的是零收益款）→ 玩家归因于「存档丢了」或「bug」。
- 期望 vs 实际: 期望「自动锁槽 + 覆盖只当晚生效」这条 risk/reward 规则像 precision 刻度一样有可见载体；实际是纯隐式行为。
- 修复方向: 主推面板给 0 号位加「风向锁定」徽标 + 一行说明（「潮流区每晚自动锁定契合明日风向的主推；手动调整只当晚有效」）；pin 实际发生替换时在 `_feedback` 给一次性提示。
- 置信度: 高（存在性 grep + 渲染代码走读）。

### F4: 夜间中途退出重进会重跑 trend pin——当晚的手动覆盖被清掉，违背「覆盖只在当晚有效」（S2）

- 证据:
  - `game/scenes/night_lab/night_lab.gd:94` — `_ready()` 无条件调用 `MenuCatalog.apply_trend_pin()`，不区分「新夜」与「续夜」；续夜分支（`night_lab.gd:99-100`，`night_budget_day == day`）不会走到 117 行的 `save_game`，但 pin 已改内存态 `featured_menu`，入睡/后续任一保存都会落盘。
  - 续夜路径真实存在：`game/tests/night_resume_check.gd:45` 正是「再次实例化 night_lab」的恢复场景（设置面板在夜中写盘，`GameState.save_game` 在 phase=night 时保存）。
  - 与 F3 叠加后，玩家连「我昨晚改过」这个事实都会被无声撤销——同一天夜里改的，不是次夜。
- 复现路径 / 推理链: trend 路线 → 夜里打开主推面板，把 0 号槽手动换成 C 款（`set_featured` 持久化，`menu_catalog.gd:150-170`）→ 当晚暂停退出游戏 → 重启读到 night 存档 → `_ready` 重跑 pin → 0 号槽被强制换回「最佳匹配」（或 F2 的任意款）→ 当晚的覆盖失效。
- 期望 vs 实际: 期望「手动覆盖在当晚有效」覆盖到存档恢复（当晚 = 同一 day 的同一夜）；实际重进即重锁，等于覆盖只在「不退出的当晚」有效。
- 修复方向: 给 pin 加每夜一次的门闩（如 `GameState.menu_last_pin_day != day` 才执行并记录），或恢复分支跳过 pin。
- 置信度: 高（调用点唯一且无条件；影响面需要「夜中退出重进」这一较低频操作，故定 S2 而非 S1）。

### F5: precision 路线对普通手速玩家是纯减益——展示日 0 次触发，评论家 ×1.25 又完全不可见（S2）

- 证据:
  - bot（regular，24 杯 / 96% 完美）：precision D9（该路线第二周开场日 critic_day）`route_bonus=0 route_triggers=0`——整日路线反馈为零；同日 skilled 画像 22/34 触发。触发条件 `patience_ratio > 0.70`（`legacy_routes.gd:72`）在 D9 耐心下限 16s×0.88=14.1s（`day_shop.gd:1676-1679`）下要求约 9.9s 内完成含排队的服务，regular 节奏全日军达不到一次。
  - ×1.25 无任何文案载体：`ui.csv:466-471` 路线卡 risk/reward/summary 只写「耐心 -12% / 高耐心交付 +1 金币」；评论家提示 `ORDER_HINT_CRITIC`（`ui.csv:106`）写死「+8 金币 +1 灵感」（precision 实发 10）；`day_shop.gd:2240-2242` 把 ×1.25 折进 `event_reward["coins"]` 计入 `event_bonus_earned`，日结算 `DAY_RESULT_ROUTE_BONUS`（`day_shop.gd:2655`）只在 `route_bonus_earned > 0` 时出现——regular 的 precision 日常整行消失。
  - 净体验：能感到的是耐心 -12%（更难），拿不到的是 +1 快交（0 次）、看不见的是评论家 ×1.25（无归因）。「高风险高回报」只兑现了前半。
- 复现路径 / 推理链: 选「口碑街区」→ 以正常手速打 D9 探店日 → HUD 全天显示「店招 +0 · 快交 0」→ 结算无路线行 → 玩家对路线的认知 = 「耐心变短了，别的没了」。
- 期望 vs 实际: 期望路线 risk/reward 两侧都可感知；实际 reward 侧对 regular 画像近似不存在（0 触发 + 隐形倍率）。
- 修复方向: (a) 路线卡/详情补「评论家接待 ×1.25」并让评论家提示/结算行按实际数值显示（precision 显示 +10）；(b) 阈值按排队位或日数放缓（如队首 0.70 / 后排 0.60），或给快交计数一个「今日最佳耐心比」让进度可见；(c) ×1.25 的增量并入 route_bonus 归因（如「店招 +2（口碑·主编待遇）」）。
- 置信度: 高（bot 对照 + 文案 grep + 结算代码；严重度判断基于 regular 画像代表性，skilled 玩家可正常触发）。

### F6: rush 的 ×0.85 到店速度被 3 槽队列饱和基本抵消——路线的头号风险/收益杠杆近乎空转（S2）

- 证据:
  - `game/scenes/day_shop/day_shop.gd:257-260` — `spawn_timer -= delta` 在队列满（`customers.size() >= _max_customers()==3`，D3 起）时持续透支为负；一旦有空位，下一顾客**立即**生成并才重置计时。饱和态下有效到店率 = 出杯率，`LegacyRoutes.spawn_multiplier()`（0.85，`legacy_routes.gd:54-56`，乘在间隔上）无从起作用。
  - bot 佐证（skilled D12）：rush（间隔 ×0.85）served=34 与 precision（无到店加成）served=34 完全持平；trend D12 在 lunch_rush 事件（间隔 ×0.72×0.94≈0.68，远快于 rush 的 0.85）也只 35——到店速度差异对服务量/压力的边际贡献 ≈0。
  - 结果：rush 的实际身份只剩「2 主推槽 + 每 3 杯 +2」（14 天 route_bonus 174，gross 7127 为三路线最高，补偿本身是够的）；「×0.85 到店」作为 risk（更多压力）与 reward（更多客人）双向不可感知。
- 复现路径 / 推理链: 任选 rush 的一天，只要玩家跟上节奏让 3 槽常满，×0.85 与 1.0 的玩家体验无差别；只有队列见底的空窗期它才短暂生效。
- 期望 vs 实际: 期望 ×0.85 是 rush 玩家能感到的「队列转得更快 / 更忙」；实际多数时间是常数。
- 修复方向: 让杠杆落到实处——例如 rush 将 `_max_customers()` 提到 4（队列更深 = 翻台感），或把饱和期的「到店尝试」转化为可见计数（门外来客潮），或直接放大每 3 杯奖励并明示「到店提速仅在空槽时生效」。
- 置信度: 中高（机制推理 + served 持平的对照数据；未逐帧测间隔分布，「多数时间饱和」基于 bot 出杯节奏推断）。

### F7: 战役策略模拟的路线断言未按路线校准——三路线全红（S3，工具链）

- 证据:
  - `game/tests/campaign_strategy_sim.gd:51-53` 支持 `CAMPAIGN_ROUTE=rush|precision|trend`，但 `_validate_campaign`（379-408 行）的期望表按无路线基线钉死：balanced 现金带 2350..2450、stars=42、angry=0。
  - 实测三路线全部断言失败（`/tmp/p7_sim_rush|prec|trend.log`）：rush 现金 2713（超带 +363，含 route_bonus 174）且 1 怒客；precision 2572；trend 2532 且 41/42★。无路线基线（`/tmp/p7_sim.log`）通过 `[STRATEGY_ASSERT] … grade=S … cash=2377`。
  - 即： sanctioned 的路线验证入口对三条路线 100% 报 ERROR——门禁失去区分力（真回归会被同样淹没）。
- 复现路径 / 推理链: `CAMPAIGN_STRATEGY=balanced CAMPAIGN_ROUTE=rush godot --headless … res://tests/campaign_strategy_sim.tscn` → `[STRATEGY_ASSERT] balanced: cash 2713 outside 2350..2450` 等 ERROR。
- 期望 vs 实际: 期望设了路线入口就有对应路线的期望带；实际要么路线断言按 route_bonus 上浮带宽/放宽 star·angry，要么路线模式下跳过无路线基线项。
- 修复方向: 期望表按 `LegacyRoutes.active_id()` 参数化（现金带 + route_bonus 中位数，angry/star 允许 ±1），保持无路线基线不变。
- 置信度: 高（三路线 + 基线四次运行复现）。

### F8: 3/3 路线收藏进度在选择界面上不可见——被 900×520 确认层盖住，选卡 ✓ 只表示「当前选中」（S3）

- 证据:
  - 唯一显示 `路线通关 X/3` 的是收官报告底部 `legacy_line`（`campaign_summary.gd:158-163`，`ui.csv:452`）；而路线选择确认层尺寸 900×520 居中（`campaign_summary.gd:332-334`），完全覆盖该行——玩家站在三选一面前时看不到自己已通关几条。
  - 选卡文本 `LEGACY_ROUTE_CARD`（`campaign_summary.gd:503-505`，`ui.csv:459`）的「✓/○」只跟随 `selected`（选中态），不表示历史通关；`routes_cleared` 数据存在（`game_state.gd:766-770`，幂等已由 campaign_check 钉住）却无第二个展示位（主菜单只显示当前路线名，`main_menu.gd:315-316`）。
  - 标题写「通关三条路线完成店招荣誉」（`ui.csv:458`）却不在同屏告诉玩家还差哪几条。
- 复现路径 / 推理链: 二周目收官 → 点「新店+」→ 三张卡都无已通关标记，背后的 X/3 被盖住 → 想集齐 3/3 的玩家必须取消确认、瞄一眼底部小字、再重开确认层。
- 期望 vs 实际: 期望选择界面直接标注已通关路线（如卡角「已通关」徽标 + 标题处 X/3）；实际需要玩家记忆或往返操作。
- 修复方向: `_refresh_route_selection` 里给 `route_id in routes_cleared` 的卡加徽标文案（如「★ 已通关」），并把 X/3 复制进 `LEGACY_ROUTE_SELECT_TITLE` 同屏。
- 置信度: 高（布局与渲染代码；严重度低，因信息一处可达）。

### F9: New Shop+ 头两天（calm）无事件简报，路线宣言「新店+ · 路线名 —— 摘要」D1-2 不出现（S3）

- 证据:
  - `game/scenes/day_shop/day_shop.gd:667-669` — `_show_event_briefing()` 对 `calm` 直接 return；`DAY_ROUTE_ACTIVE`（`ui.csv:487`）只挂在简报的 `event_route_label`（676-679 行）。D1-2 是 calm → 路线完整摘要在新店头两天零呈现，首次见到是 D3。
  - HUD 事件药丸虽有路线短名 + 进度（`day_shop.gd:2902-2908`），但路线 risk/reward 全文（选完路线后第一次"我签了什么约"的确认）只存在于被跳过的简报里。
- 复现路径 / 推理链: 选完路线立刻进 D1 → 无任何界面复述本路线规则（HUD 只有「平稳营业 · 翻台 / 店招 +0 · 周转 0/3」一行小字）。
- 期望 vs 实际: 期望新店第一天给一次路线规则回顾（尤其玩家从收官页到开新店隔了一屏转场）；实际最早 D3 才见全文。
- 修复方向: calm 日简报在 `LegacyRoutes.is_active()` 时也展示（只放路线行 + 开始按钮），或 D1 的 `event_route_label` 移入 HUD 提示。
- 置信度: 高（代码路径确定；严重度最低）。

## 检查过无问题的面

- **第二周事件日历（Day9+ 路线重排）**：三路线 D9-14 各自按 `ROUTE_ROTATIONS`（`daily_events.gd:81-85`）重排且每 6 天六事件各出现一次；event_check 钉住 `routed_calendars=3`；bot D12 实测 rush=critic_day / precision=brown_sugar_trend / trend=lunch_rush，与 `LEGACY_ROUTE_*_CALENDAR` 文案（"第二周从结伴到店→午间热浪开场"等，`ui.csv:465/471/477`）逐条一致；二遍强度弯 + 修饰词（spawn×0.94、patience×0.96、主编 ×2 等）按规格「再乘」不覆盖（`daily_events.gd:131-144`）。
- **继承奖励实现与呈现一致性**：`start_new_shop_plus`（`game_state.gd:787-807`）与 `campaign_summary._legacy_bonus`（398-404 行）两处 S/A/B/C 档（80/3、60/2、40/1、20/0）完全一致；campaign_check 断言 `new_game_plus=3routes/80/+3`；`tutorial_completed=true` 跳过二周目教学；起步奖金先 `mark_day_open()` 重快照，不能被「重玩当天」回滚。
- **继承后 D1-5 难度**：80 币 + 3 灵感开局下 regular D1 earned 184 / goal 106（tau 1.74）、D3 389/145，模拟 D1-5 全 3★ 无现金流断裂；目标 ×1.08 从 D1 生效（106 vs 基线 98）且直接显示在 HUD 目标行。新手画像基线 140/98 也无悬崖。无问题。
- **rush 触发节奏与结算归因**：+2 精确落在每第 3 杯完美连击（D12 skilled 34 完美 → 11 次 ×2=22；HUD「周转 %d/3」用 `posmod(streak,3)` 实时倒数）；触发时店招 3D 模型脉动（`shop_stage.gd:180-192`，三只 route_*.glb 齐备）+ 飞字 `DAY_REWARD_ROUTE` 归因到路线短名 + 日结算 `DAY_RESULT_ROUTE_BONUS` 汇总——rush 的收入侧可感知性是三路线中最好的。
- **precision 的规则可见载体（非奖励侧）**：每张订单卡耐心条上有紫色 70% 刻度 + tooltip（`day_shop.gd:1791-1804`）、就绪时秒数变「N秒 · +1」（243-249 行）——若阈值可达，这套呈现是合格的（问题在 F5 的可达性与 ×1.25 隐形）。
- **trend 的风向预告链路**：白天简报/药丸预告明日事件（`day_shop.gd:680-682`），夜间研发室预览明日事件名 + 挑战（`night_lab.gd:285-292`），主推面板显示「明日：事件 · N 款主推契合 · 到店速度 +X%」与每卡「契合明日风向 · +N 金币」（`menu_board_panel.gd:173-175, 281-286`）；契合 +3 与事件匹配奖励叠加可见（menu_catalog_check 钉住）。
- **路线数值接线**：×0.85 到店间隔、×0.88 耐心、0.06/0.04 客流步进、目标 ×1.08 全部真实接入 `_spawn_interval`/`_patience_for_day`/`traffic_multiplier`/goal（`day_shop.gd:1670-1679, 2465`）；路线存档字段加载时清洗、`routes_cleared` 幂等（save_integrity_check / campaign_check）。
- **路线选择确认层交互卫生**：同帧双击守卫 `_transition_started` 防 S 奖金降级重放（`campaign_summary.gd:453-484`），手柄焦点路由与 ui_cancel 关闭齐备。
