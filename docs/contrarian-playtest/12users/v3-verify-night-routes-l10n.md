# V3 对抗性核实 · 夜间/路线/本地化/对比度

验证代理 V3 · 2026-08-17 · 基线 HEAD `c456b0b`（与 _stats.md 一致）。
方法：只读代码走查（行号均为当前 HEAD 实测）+ `ui.csv` 全量对照 + 游戏字体（`game/assets/fonts/LXGWWenKai-Regular.ttf`）PIL 独立测宽 + WCAG 相对亮度独立复算（脚本 `/tmp/v3_measure.py`）+ 2 次无头复跑（`/tmp/v3_bot_prec_d9_regular.log`、`/tmp/v3_sim_rush.log`）。未修改任何 `game/` 文件。

**判定汇总：CONFIRMED 32 项 / REFUTED 1 个子项（P12-F5 的「锁定暗卡 3.77:1」数字）/ NEEDS-FIX-SCOPE 0。**

---

## 1. [S1] P7-F1 rush 锁第三槽三处 UI 假情报 — **CONFIRMED**

独立证据（四处分母全部钉死，比原报告多确认一处调用面）：

- `game/autoload/menu_catalog.gd:6` `const FEATURED_LIMIT := 3`（常量）；`:119-120` `featured_limit()` 才是路线感知入口（转发 `LegacyRoutes.featured_slot_limit()`）；`game/autoload/legacy_routes.gd:84-85` rush 返回 **2**。
- `game/ui/menu_board_panel.gd:170-171`：`MENU_BOARD_PROGRESS` 第二实参传 `MenuCatalog.FEATURED_LIMIT` → rush 显示「2/3 槽」。
- `game/ui/menu_board_panel.gd:172` + `ui.csv:739`：`MENU_BOARD_SUBTITLE` = "Choose up to three recipes. / 最多选择三款。"（写死 three/三款）。
- `game/ui/menu_board_panel.gd:434-435` + `ui.csv:761`：`"full"` 分支反馈 `MENU_BOARD_FULL` = "All three slots are full… / 三个主推槽已满，请先移出一款。"——rush 玩家在 2 款时触发（`set_featured` 于 `menu_catalog.gd:158-159` 按 `featured_limit()`=2 判满），文案却断言「三槽已满」。
- `game/scenes/night_lab/night_lab.gd:782-784`：`NIGHT_MENU_PILL`（ui.csv:736 "主推 %d/%d"）同样传 `FEATURED_LIMIT` → 夜间常驻「主推 2/3」。
- 附带：`game/tests/campaign_strategy_sim.gd:312` 也用常量（bot 行为非 UI，不构成本条，但同修无害）。

最小修复：`menu_board_panel.gd:171` 与 `night_lab.gd:783` 的 `MenuCatalog.FEATURED_LIMIT` 改为 `MenuCatalog.featured_limit()`；`MENU_BOARD_FULL`/`MENU_BOARD_SUBTITLE` 增加路线变体（或插值 `%d` 个槽位），rush 文案点名「周转区两个主推槽是 ×0.85 到店的代价」。回归断言：rush 激活时 `MENU_BOARD_PROGRESS` 分母为 2、`MENU_BOARD_FULL` 不出现「三」字。

## 2. [S1] P7-F2 trend 无契合仍强锁 0 号槽 — **CONFIRMED**

独立证据（`menu_catalog.gd:125-147` 逐行）：

- `:133` `var best_bonus := -1`；`:134-140` 对每个 `formula_available` 项取 `event_match_bonus`（`menu_catalog.gd:472-493`，不契合恒返回 **0**），`:138` `if bonus > best_bonus` — **`0 > -1` 成立**，故菜单里第一个可用项必中选（`best_id` 非空、`best_bonus=0`）。
- `:141` 早退条件只查「best_id 为空或已在主推」；无契合时若首个可用项不在主推（例：菜单 [A,B]、主推=[B]），`:144` `GameState.featured_menu[0] = best_id` 把玩家 deliberate 的 B 换成 0 收益的 A。
- 契合判据 `:472-493`（lunch_rush ≤1 料且价≤13 / light_drinks 纯茶低糖 / 黑糖 / 招牌档 / 爆款档 / ≥2 料）——二周目早期全普通档自创时确实可能 0 契合。全仓 `apply_trend_pin` 调用点仅 `night_lab.gd:94`，无测试覆盖（grep 证实）。

最小修复：`menu_catalog.gd:141` 前加 `if best_bonus <= 0: return`（无正契合=no-op）；补单测：trend + 无契合菜单 + 手选主推 → 进夜后 `featured_menu` 不变。注意别误伤「有契合且已在主推」的幂等早退（`best_bonus>0` 路径保持原样）。

## 3. [S1] P5-1 市场结算卡配方行永远空料 — **CONFIRMED**

独立证据（数据→渲染→白名单三段断裂）：

- `game/autoload/market_tests.gd:37-41`：result 只有 `name/stage/score/average/trend/outcome/price/refund`，**从不拷贝** test 的 `base/milk/toppings/sugar`。
- 渲染端 `game/ui/night_settlement_panel.gd:152-155`：`RecipeJournal.formula(result)`；`game/autoload/recipe_journal.gd:63-82` 读 `item.get("base","")`（空→空名）、`toppings` 缺省 `[]` → `NIGHT_NO_TOPPINGS`「无小料」、`sugar` 缺省 `[]` → 空串。渲染模板 `RECIPE_BOOK_FORMULA`（ui.csv:661）。与 P5 探针输出「茶底 · 奶基空 / 小料 无小料 / 糖度空」逐字段对上。
- `game/autoload/game_state.gd:493-524` `_normalize_market_settlement` 白名单同样只有那 8 个字段——即使 advance() 补了字段，读档也会剥掉，修复必须两处同步。

最小修复：`market_tests.gd:37` result 构造时拷 `"base": String(test.get("base","")), "milk": …, "toppings": test.get("toppings",[]).duplicate(true), "sugar": int(test.get("sugar",50))`；`game_state.gd:509-518` 白名单加同名字段；`tests/market_test_check.gd` 断言从「含"配方："前缀」升级为「公式串包含具体茶底原料名」。

## 4. [S1-D3] 定价 UI 中文未翻译 — **CONFIRMED**（键值填错，非渲染路径问题）

独立证据：`ui.csv` L749-756 zh 列逐格复核——**8 个键** zh 列是英文原文（比两份原报告各多确认 1-2 个）：

| 行 | 键 | zh 列实际值 |
|---|---|---|
| 749 | MENU_BOARD_PRICE | `Pricing` |
| 750 | MENU_BOARD_PRICE_BUDGET | `Value · %d`（英文词；P4-11 称其「已译」不确） |
| 751 | MENU_BOARD_PRICE_STANDARD | `Standard · %d` |
| 752 | MENU_BOARD_PRICE_PREMIUM | `Premium · %d` |
| 753 | MENU_BOARD_PRICE_BUDGET_TIP | `2 coins cheaper per cup · featured arrivals 2% faster` |
| 754 | MENU_BOARD_PRICE_STANDARD_TIP | `Market-verified price · no change to foot traffic` |
| 755 | MENU_BOARD_PRICE_PREMIUM_TIP | `3 coins more expensive per cup · arrivals 3% slower` |
| 756 | MENU_BOARD_PRICE_SET | `Price set to %d` |

渲染路径无嫌疑：`menu_board_panel.gd:256/268-269` 走 `GameLocale.text()` → `tr(key)` → 同一 CSV；同面板其它键 zh 正常。根因=zh 列数据录入（且 BUDGET 的 zh 是另一个英文词 "Value"，像是英文草稿误入 zh 列）。

最小修复：zh 列补译（建议：`MENU_BOARD_PRICE=定价`、`让利 · %d / 标准 · %d / 溢价 · %d`、tips 对应「每杯少 2 币 · 主推到店 +2% 提速 / 市场验证价 · 客流不变 / 每杯多 3 币 · 到店放缓 3%」、`已定价 %d`）。防回归：localization_check 加「zh locale 下 prose 键 zh 列须含 CJK」抽查（白名单豁免纯符号/数字键）。

## 5. [S1] P4-1 制杯状态行英文溢出 — **CONFIRMED**（实测比原报告更糟）

独立证据：

- 几何：`game/scenes/day_shop/day_shop.gd:386-393` status_panel `position=(388,612)`、宽 **505**，Label font 17，仅设字号——无 autowrap、无 `text_overrun_behavior`、无 clip（对照：`menu_board_panel.gd:237` 的 name 有 TRIM_ELLIPSIS，此Label没有）。
- 组串：`day_shop.gd:1269-1283` `_refresh_cup()` 用**全名** `GameLocale.ingredient_name`（不是 `ingredient_short_name`）以 " + " 连接；小料上限 2（`day_shop.gd:1142`）；尾部还有封口/返工/批次串（ui.csv:196-199、807-809）。
- 游戏字体 PIL 实测（size 17px）：
  - en 最坏（阿萨姆+纯茶+黑糖冻+折耳根+全糖+封口·无返工+稳定批次，D8 可达）= **1112px**（P4 报 969px 还偏保守；其口径串复测 944px 同级）；终点 x=388+1112=**1500 ≫ 1280** 屏宽。
  - 换 D10 解锁的桂花冻组合 = 1169px 更长；1 小料常见串（炭焙乌龙+燕麦奶+蜜红豆+椰果）= 1036px。
  - zh 最坏 = 694px，超面板 505px 但屏内——英文放大约 1.6 倍，与 P4 结论一致。

最小修复（任一）：`day_shop.gd:1273-1276` 改用 `GameLocale.ingredient_short_name`；或 `status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS`（一行）；或 autowrap 两行+面板加高。建议 trim+短名双管（zh 694px 也超面板）。

## 6. [S1] P4-2 逗号缺失 10 处 — **CONFIRMED**（11 行逐条复核）

`ui.csv` en 列原文（行号+缺逗号处）：

1. L17 `PAUSE_CONTROLS_HINT`："Tap ingredients the shake button and order cards"（ingredients 后缺）
2. L19 `SETTINGS_MOTION_DESC`："camera shake flying coins cup wobble and customer idle motion"（连排 4 处）
3. L44 `CONTRACT_INTRO_BODY`："After Day 15 sign one contract…"（Day 15 后缺）
4. L153 `MENU_RESET_BODY`："progress recipes and upgrades" + "Audio motion haptics and language"（两处）
5. L162 `SETTINGS_CONTROLS_MENU_GAMEPAD`："Music SFX motion haptics and language save immediately."
6. L163 `SETTINGS_CONTROLS_MENU_KEYBOARD`：同上句式
7. L333 `TUTORIAL_4_BODY`："After all ingredients are ready shake the cup."
8. L336 `TUTORIAL_5_BODY`："improve tips combos and research resources"
9. L360 `UPGRADE_SMART_SUGAR_DESCRIPTION`："After milk is selected the current order sugar level…"（selected 后缺）
10. L434 `CAMPAIGN_VERDICT_S`："Service research and management now form…"
11. L457 `CAMPAIGN_CONFIRM_BODY`："Recipes equipment and current progress reset…"

（P4 把 5/6 记作一处，共 10 项 11 行——全部在案，无一条误报。）

最小修复：对上述行 en 列补 serial comma（例：L19 → "Disables camera shake, flying coins, cup wobble, and customer idle motion."）；可加一次性 sweep 脚本查「名词 名词 and 名词」无逗号模式。

## 7. [S2] P7-F3 trend 规则零 UI 载体 — **CONFIRMED**

- `ui.csv` 全量 grep `lock/锁定/pin/自动锁`：仅命中无关键（RECIPE_BOOK_TARGET_SET、NIGHT_STAFF_LOCKED、MARKET_SETTLEMENT_*、POSITIONING_LOCKED 等）；MENU_BOARD/DARK_BOARD 全部 46 键（L737-782）无锁定徽标/说明键。
- `menu_board_panel.gd:205-308` `_menu_card` 对 0 号槽与其余主推卡渲染完全一致（`MENU_BOARD_FEATURED` 一视同仁，`:230-231`）；卡片按 `MenuCatalog.items()` 菜单序排列，「第一个主推位」概念在面板不可见。
- 规则只存在于注释（`menu_catalog.gd:123-124`、`night_lab.gd:93`）。

最小修复：加键 `MENU_BOARD_PIN_BADGE`（如「风向锁定」），`_menu_card` 对 `GameState.featured_menu[0]`（trend 激活时）渲染角标 + subtitle 追加一行规则说明；pin 实际发生替换时（`apply_trend_pin` 的 `:144` 路径）经 `menu_changed` 在面板 `_feedback` 给一次性提示。

## 8. [S2] P7-F4 夜间重进重跑 pin — **CONFIRMED**

- `night_lab.gd:90-94`：`_ready()` **无条件**调用 `apply_trend_pin()`，先于 `:99` 的续夜分支判断；无任何「本夜已 pin」门闩（全仓 grep `menu_last_pin_day` 零命中）。
- 续夜路径真实且被官方测试钉住：`game/tests/night_resume_check.gd:44-46` 正是「夜中重新 instantiate night_lab」的场景；续夜分支虽不走 `:117` 的 save，但 `:1128` `_on_sleep()` 的 `GameState.save_game()` 与菜单板任何 `set_featured(persist=true)` 都会把 pin 结果落盘。
- 影响链：当晚手改 0 号槽（`set_featured` 持久化）→ 退出重进 → pin 无条件重锁 → 覆盖被清，「覆盖只在当晚有效」违背。

最小修复：`GameState` 加 `menu_last_pin_day`（或复用 `menu_last_hype_day` 模式），`apply_trend_pin` 入口 `if GameState.menu_last_pin_day == GameState.day: return` 并在执行后记录；`night_resume_check` 补断言「重进后 featured_menu 不变」。

## 9. [S2] P7-F5 precision 对 regular 纯减益 — **CONFIRMED**（bot 独立复跑）

- 复跑：`BOT_PROFILE=regular BOT_DAY=9 BOT_ROUTE=precision`（日志 `/tmp/v3_bot_prec_d9_regular.log`）→ `[RESULT] … perfect_rate=100% event=critic_day … route=precision route_bonus=0 route_triggers=0`——**100% 完美手速的 regular 全天 0 触发**，与 P7 原数据完全一致。
- 阈值：`legacy_routes.gd:72` `patience_ratio > 0.70`；`day_shop.gd:1676-1679` D9 耐心基数 clamp 到 16s，×0.88（`legacy_routes.gd:59-60`）≈14.1s，需 ~4.2s 内完成含排队读单的服务，regular（act_delay 0.60 / read_delay 1.4）不可达。
- ×1.25 隐形：`day_shop.gd:2239-2242` 把 `critic_bonus_multiplier()`（`legacy_routes.gd:79-80`，precision=1.25）折进 `event_reward["coins"]` 计入 `event_bonus_earned`，无归因到路线；`ORDER_HINT_CRITIC`（ui.csv:106）写死「+8 金币」（precision 实发 roundi(8×1.25)=10）；路线卡 risk/reward（ui.csv:468-469）只写「耐心 -12% / 高耐心交付 +1 金币」，无评论家条目。

最小修复：(a) `LEGACY_ROUTE_PRECISION_REWARD/SUMMARY` 补「评论家接待 ×1.25」；`ORDER_HINT_CRITIC` 在 precision 激活时用参数化变体显示实际值；(b) `:2242` 的增量另计为 route 归因（如 `route_bonus_earned += roundi(coins*0.25)`）或在结算行注明；(c)（可选）阈值按排队位放宽。

## 10. [S2] P7-F6 rush ×0.85 被 3 槽饱和抵消 — **CONFIRMED**（机制+呈现面）

- 机制：`day_shop.gd:257-260` `spawn_timer -= delta` 无条件执行，队列满（`_max_customers()`=`:1666-1667`，D3 起 **3**）时计时持续透支为负；一有空位立即生成并才重置。饱和期有效到店率=出杯率，`LegacyRoutes.spawn_multiplier()`（`legacy_routes.gd:54-56` rush=0.85）确已接入 `_spawn_interval()`（`day_shop.gd:1670-1673`）但只在非饱和时起作用。P7 的 served 持平对照（rush 34 = precision 34）与该机制自洽。
- 呈现面：×0.85 无任何 UI 载体——HUD 只有 `DAY_ROUTE_PROGRESS_RUSH`「店招 +N · 周转 N/3」（ui.csv:482）；路线卡风险行写「Arrivals +12%」（见 P4-5，数值本身也是错的）；无「到店提速仅在空槽时生效」类说明。

最小修复（任选）：rush 将 `_max_customers()` 提到 4（队列更深，×0.85 有感）；或饱和期把「门外客潮」做成可见计数；同时与 P4-5 一并修文案。注：「多数时间饱和」的普遍性基于 bot 节奏推断，属合理推断而非逐帧实测——不影响定性。

## 11. [S2] P4-3 糖度 Fu/No 语言切换回归 — **CONFIRMED**

- 建架路径已修：`night_lab.gd:655` `btn.text = short_name if kind == "sugar" else short_name.left(2)`（注释自证 P4 修复）。
- 切语言刷新路径未修：`night_lab.gd:1209` `tile["btn"].text = short_name.left(2)`——无差别截断；糖度瓦片恰无图标（`has_icon=false` 走此行），zh↔en 切换后 "Full"→"Fu"、"None"→"No"。两行代码直接对照，成立。

最小修复：`_tiles` 建架时存 `tile["kind"]`（或用 `tile["item"].has("value")` 判糖度），`:1209` 改 `short_name if tile["item"].has("value") else short_name.left(2)`；night_check 加「切语言后 sugar 瓦片文本 == SUGAR_100_SHORT」断言。

## 12. [S2] P4-4 路线日历事件名不符 — **CONFIRMED**（重要修正：**zh 列全对，仅 en 列错**）

对照 `ui.csv`（CALENDAR 键 L465/471/477 vs `EVENT_*_NAME` L82-102）：

| CALENDAR 写的(en) | 实际 EVENT_*_NAME(en) | 符合？ | zh 侧 |
|---|---|---|---|
| Group Visit | **Friends' Day** | ✗ | 结伴到店 ✓ |
| Lunch Rush | Lunch Rush | ✓ | 午间热浪 ✓ |
| Critic Day | **Critic Visit** | ✗ | 探店日 ✓ |
| Light-Drink Trend | Light-Drink Trend | ✓ | 轻饮风向 ✓ |
| Camera Visit | **Camera Crew** | ✗ | 镜头来访 ✓ |
| Brown-Sugar Trend | **Brown-Sugar Buzz** | ✗ | 黑糖热搜 ✓ |

en 侧 4/6 不符，与 P4 一致；zh 列六个全部一致——修复面比原报告小：**只改 en 列三个键**（L465/471/477）即可，如 "opens with Friends' Day → Lunch Rush." / "…Critic Visit → Light-Drink Trend." / "…Camera Crew → Brown-Sugar Buzz."。防回归：localization_check 加「CALENDAR 键中的事件词须为 EVENT_*_NAME 子串」断言（双语）。

## 13. [S2] P4-5 rush 文案 +1 vs 实发 +2；+12% vs ×0.85 — **CONFIRMED**

- `legacy_routes.gd:70`（P4 引 :60，当前 HEAD 行号已移）：`return 2 if streak > 0 and streak % 3 == 0 else 0` — 实发 **+2**；`ui.csv:463` `LEGACY_ROUTE_RUSH_REWARD` "Every 3 correct cups +1 Coin"、`:464` SUMMARY 同（zh「每 3 杯正确出杯 +1 金币」）——虚报一半。HUD `DAY_ROUTE_PROGRESS_RUSH` 实时显示「店招 +2」与卡片承诺直接矛盾。
- `legacy_routes.gd:54-56` rush `spawn_multiplier`=**0.85**（间隔 −15% ≈ 到店 +17.6%）；`ui.csv:462` RISK "Arrivals +12% / 到店速度 +12%"、`:464` SUMMARY "refill 12% faster"——少报。PRECISION（−12% ↔ 0.88）与 TREND（+6% ↔ 0.06）核对无误，仅 RUSH 失配，与 P4 一致。

最小修复：三键文案改 "+2 Coins" 与 "Arrivals +15% faster"（zh「+2 金币」「到店速度 +15%」），或回调数值——文案对齐代码成本最低。

## 14. [S2] P4-6 报告汇总行溢出 — **CONFIRMED**（实测 1084px）

- `campaign_summary.gd:158-190`：`legacy_line` 单行 Label、font 15、居中、**无 autowrap**；面板 1100 宽（`:58`）左右边距 30（`:62-63`）= 可用 **1040px**。
- 游戏字体实测（font 15）：
  - en 最坏真实组合（Team + Legacy + Routes + rush 统计 + 定位 + 回暖日）= **1084px > 1040px** 溢出；注意定位名实际渲染为 "Positioning: Positioning · Flavor"（`upgrade_catalog.gd:118` 名称键 `POSITIONING_*_NAME`，`ui.csv:876` en="Positioning · Flavor"），比 P4 假设的 "Positioning: Flavor" 更长——P4 的 1072px 估算方向正确且偏保守。
  - zh 最坏 ≈ 1001px，恰好收在 1040 内——**此条主要是 en 侧问题**（P4 未区分，补充修正）。

最小修复：`legacy_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART`（一行）或拆两行。

## 15. [S2] P5-4 lunch_rush 咬合不可发现 — **CONFIRMED**

- 规则本体：`menu_catalog.gd:478-479` lunch_rush 契合 = `toppings ≤ 1 且 price ≤ 13`。
- 全 CSV 检索无任何载体：`EVENT_LUNCH_RUSH_CHALLENGE`（ui.csv:84）只讲「到店间隔缩短 28%」；BENEFIT（:85）只讲客流/三星；三条定价 tooltip（:753-755）只讲 ±2%/3% 客流；卡片契合行 `MENU_BOARD_EVENT_MATCH/NEUTRAL`（:742-743）是二元结果（「契合明日风向 +N / 明日常规需求」），不契合无原因。爆款档价点下限 16（`menu_catalog.gd:13-18`）> 13 → 结构性永不契合，与 P5 结论一致。

最小修复：`MENU_BOARD_EVENT_NEUTRAL` 拆出「差一点」变体（如 `MENU_BOARD_EVENT_NEAR_PRICE`「距契合线还差 %d 币」/`_NEAR_TOPS`「小料多一味」），`_menu_card` 按 `event_match_bonus==0` 且差距类型选择；EVENT_LUNCH_RUSH_BENEFIT 补一句「平价少料款今日每杯 +4」。

## 16. [S2] P5-5 预告栏 "+-9%" — **CONFIRMED**

- `menu_board_panel.gd:173-175`：实参 `roundi((1.0 - MenuCatalog.traffic_multiplier()) * 100.0)`；`pricing_traffic_multiplier()`（`menu_catalog.gd:215-227`）clamp 上限 **1.09**（三款主推全溢价即达）→ 值 = roundi(−9.0) = **−9**。
- 模板 `MENU_BOARD_FORECAST`（ui.csv:741）en/zh 双列都硬编码 `到店速度 +%d%%` / `Arrival speed +%d%%` → 渲染「+-9%」。`MENU_BOARD_TRAFFIC`（:740）同款硬编码 `+%d%%`（另一呈现面，同修）。roundi 本身无异常（Godot 四舍五入离零），问题纯在格式符。

最小修复：格式按符号分支——GDScript `%+d` 对 −9 产生 "-9"（已含符号），把模板改为 `到店速度 %+.0f%%`-style 或在 gd 侧 `("+%d%%" if v>=0 else "-%d%%") % [absi(v)]` 组装后作为整串插值；两个键同修。防回归：menu_catalog_check 加断言 `MENU_BOARD_FORECAST` 渲染串不含 "+-"。

## 17. [S2] P12-F1 耐心秒数对比度 — **CONFIRMED**（数字逐位复现）

- 代码：`day_shop.gd:24` `PATIENCE_BAND_COLORS := [E5484D, D99A43, 27B9A7]`；`:250` 直接作 `patience_label` font_color；`:1782` 字号 16，无描边。卡底 `:2153/2162` `Color(1.0,0.973,0.929,0.97)` ≈ (255,248,237)。
- WCAG 独立复算：红 E5484D = **3.71:1**、琥珀 D99A43 = **2.30:1**、薄荷 27B9A7 = **2.32:1**——16px 常规字需 4.5:1，三档全不达；与 P12 报告三位小数级一致。

最小修复：秒数文字固定 COCOA（14.74:1），档位信息改前置色点/图标；或加深档位色（如 #B3261E ≈6.3:1、#8A5A00、#0E7A6C 需 ≥4.5 验证）。断言：day_check 或新检查项以常量表钉「band 色 on 卡底 ≥4.5」。

## 18. [S2] P12-F4 结算 accent — **CONFIRMED**（含对 P12 卡底口径的修正）

- 代码：`night_settlement_panel.gd:141-145` 分数 22px 用 outcome accent；`:147-151` 阶段 13px 同色；`:49-52` 摘要 16px MINT。**卡底实为 `Color.WHITE`（`:118`），非 P12 所述 MINT 7% 混 CREAM**——但结论不变且更差：
- 独立复算（on 白卡）：GOLD **2.43:1**、MINT **2.45:1**、CORAL **2.94:1**（P12 口径卡底 2.17/2.19/2.63 同样全不达 3:1）；22px 非粗体按 WCAG 不属大字（需 ≥18pt≈24px 或 14pt 粗体），13px 阶段标签更需 4.5:1。摘要 MINT on CREAM = 2.32:1。PLUM 12.28:1 达标（failed 分支无问题）。

最小修复：分数/摘要文字改 COCOA（或 PLUM 类深色），accent 保留在卡描边/进度条；`:150` 阶段标签必须换深色（13px）。

## 19. [S2] P12-F5 13px GOLD/MINT — **CONFIRMED**（一个子项 REFUTED，见末）

独立复算（菜单卡底 `Color(1.0,0.985,0.955)`=(255,251,243)，`menu_board_panel.gd:216`）：

- `menu_board_panel.gd:284-285` event_fit GOLD 13px = **2.35:1**（与 P12 一致）；`:258` 价格说明 COCOA@0.62 混合后 = **4.44:1**（差 0.06 到 4.5，一致）。
- `recipe_book_panel.gd:262/284-285` 搭配等级名 16px accent on seen 格 (255,251,243)：CORAL **2.85** / MINT **2.37** / GOLD **2.35** / 冲突紫 8C67B5 **4.31**（P12 报 2.79/2.32/2.30/4.21，同判：紫除外全不达）。
- `tutorial_overlay.gd:104` 教学进度 MINT 15px on CREAM = **2.32:1**。
- **REFUTED 子项**：「`menu_board_panel.gd:372,393` 锁定暗卡 body 白 0.78 混底后 3.77:1」不可复现——按代码（`:372` 暗底 `Color(0.18,0.15,0.18,0.72)`、`:393` 文字白@0.68-0.78，其下是 `:30` 的深色遮罩 0.055/0.05/0.075@0.94），有效底色 L≈0.015、混后文字 L≈0.58，对比 **≈9.5-9.7:1**，远超 4.5。该子项应从修复清单剔除；其余 F5 项全部成立。

最小修复：`menu_board_panel.gd:285`、`recipe_book_panel.gd:262/284`、`tutorial_overlay.gd:104` 文字色改 COCOA（等级/事件旁留小色标），GOLD/MINT/CORAL 只用于描边与图标。

## 20. [S2] P11-F1 离场晋升单击交付 — **CONFIRMED**

独立证据（三段代码闭环，与 P11 探针结论互证）：

- 双确认守卫本体：`day_shop.gd:2101-2115` `_on_order_card_pressed` — `cup_sealed` 且 `c == active_customer` → **单击直接 `_on_deliver(c)`**（`:2110-2111`）；只有点**非活动卡**才走非破坏性 `_set_active_customer(c)`（`:2113`，即「先看单」步）。守卫的隐含前提（注释原文 "The focused/active card is already reviewed"）只对「主动切单后」成立。
- 自动晋升绕过：`day_shop.gd:2413-2426` `_remove_customer` — 活动顾客离场时 `:2419` 直接 `active_customer = customers[0]`（不经 `_set_active_customer`、无「需复审」标记），`:2426` `_refresh_all_order_action_hints()` 立即把新队首提示切成交付态。此时玩家手中 sealed 杯是为**已离场顾客**做的。
- 罚则一次全齐：错配方路径 `:2337-2355` — `waste_cost += consumed_cost`（料损）、`:2349` `patience *= 0.65`、`:2350` `streak = 0`。三次打击一次单击，与 P11 探针（B1/B4）一致。

最小修复：`_remove_customer` 的晋升分支（`:2419-2421`）在 `cup_sealed` 时给新队首挂一次性 `needs_review` 标记（存 customer dict 或成员变量），`_on_order_card_pressed` 见标记则先 `_set_active_customer` 再清标记——与手动切单行为对齐；配 day_check 断言「离场晋升后首次单击不触发 _on_deliver」。

## 21. [S3] P4-7/8/9/10 — **全部 CONFIRMED**

- **P4-7**：`ui.csv:190` `DAY_HUD_COSTS_NEXT` "Stock%d · Rent D%d"、`:191` "Stock%d · Rent≤%d" → 渲染 "Stock12"。修：`Stock %d · Rent day %d` / `Rent ≤%d`（zh 不动）。
- **P4-8**：`:668` `RECIPE_BOOK_TIER` en `«%s»` — 法/俄式角引号，全库 en 其余用 “ ”。修：en 改 `“%s”`，zh 保留《%s》。
- **P4-9**：`%d Coins` 17 行 vs `%d coins` 14 行（逐行 grep 复核一致）；`CAMPAIGN_LEGACY`（:451）"%d Runs"、`MENU_SIGN_SUMMARY`（:142）/`ENDLESS_SIGN_RANK`（:414）"%d Stamps" → "1 Runs"/"1 Stamps"；"New Shop+"（:487/143）vs "New Shop +"（:454/480）各 3 处并存；分隔符 ` · ` 245 行 vs ` | / ｜` 3 行、连字符 " - "（:122 CONTRACT_REVENUE_SPRINT_DESCRIPTION）。全部在案。
- **P4-10**：`:42` STAFF_HIRE_BODY "Traits reveal through real events…"、`:373` UPGRADE_RESERVE_RISK "Buying leaves %d coins below…"、`:476` TREND_SUMMARY "each and every"（原句在案）、`:899` TUTORIAL_GATE_HINT "%d more attempt(s)"、`:629` INGREDIENT_BROWN_SUGAR_SHORT en="Brown"（zh 却是「黑糖冻」）、`:232` DAY_STAFF_SLACKER_IDLE "Slacking · Back Queue Support Paused"。六项原文逐一核实。

## 22. [S3] P5-7/8/9 — **全部 CONFIRMED**

- **P5-7**：`menu_catalog.gd:215-227` `pricing_traffic_multiplier` 只遍历 `featured_items()`；而 `menu_board_panel.gd:250-280` 对**每张**自创卡渲染定价行且 `_on_price_pressed` 成功反馈不分主推（`:446-449`）。非主推调价 traffic 无变化。修：非主推卡定价行 `modulate` 置灰 + `MENU_BOARD_PRICE_INACTIVE` 提示键（「加入主推后生效」）。
- **P5-8**：`night_lab.gd:1046-1052` 装槽失败先 `_append_result("NIGHT_DARK_MENU_DISCARD")` 再 `_offer_dark_candidate(dark_entry)`（`:1073-1079` 仅把候选交给菜单板暂存）；关闭面板（`hide_panel` 只隐藏）候选即永久丢失，重做得再花 2 灵感。修：交换顺序（先面板、确认放弃才 append discard），面板加「放弃候选」按钮。
- **P5-9**：`night_lab.gd:19-21` `ATTEMPT_COST=2 / INSP_BASE=8 / ACTIVE_BUDGET_CAP=16` + `:109-115` `free_budget = mini(16, 8 + 2×主推(≤3) + 研究加成)` → 16 封顶、8 次试做，与 P5 数字推导一致（严重度属设计裁量，事实无误）。

## 23. [S3] P7-F7/8/9 — **全部 CONFIRMED**

- **P7-F7**（独立复跑）：`CAMPAIGN_STRATEGY=balanced CAMPAIGN_ROUTE=rush` 无头复跑（`/tmp/v3_sim_rush.log`）→ `ERROR: [STRATEGY_ASSERT] balanced: cash 2713 outside 2350..2450`——与 P7 原日志**同号复现**（cash 2713）。静态：`campaign_strategy_sim.gd:51-53` 接受 `CAMPAIGN_ROUTE`，但 `:67-71` 期望表按无路线基线钉死、`:379-408` 校验无路线分支。修：期望表按 `LegacyRoutes.active_id()` 参数化（现金带 + route_bonus 中位数、stars/angry 放宽 ±1），保持无路线基线不变。
- **P7-F8**：`campaign_summary.gd:333-334` 确认层 panel `custom_minimum_size = Vector2(900, 520)` 居中全屏遮罩，盖住底部 `legacy_line`（X/3 唯一展示位，`:158-163` + ui.csv:452）；`:503-506` 选卡 "✓/○" 仅跟随 `selected`；`main_menu.gd:315-316` 主菜单只显示当前路线名（MENU_ROUTE_SUMMARY），`routes_cleared` 无第二展示位。修：`_refresh_route_selection` 给 `route_id in routes_cleared` 的卡加「★ 已通关」角标，并把 X/3 并入 `LEGACY_ROUTE_SELECT_TITLE` 同屏。
- **P7-F9**：`day_shop.gd:660-667` `_show_event_briefing()` 对 `calm` 直接 return，`DAY_ROUTE_ACTIVE`（ui.csv:487）只挂在简报的 `event_route_label`（`:676-679`）→ 新店 D1-2（calm）路线全文零呈现。修：calm + `LegacyRoutes.is_active()` 时也弹精简简报（仅路线行+开始按钮）。

## 24. [S3] P12-F7/F8 — **CONFIRMED**（F8 一个子项维持原判、一个补充）

- **P12-F7**：L(D99A43)=**0.3827** vs L(27B9A7)=**0.3792**（逐位复现）——琥珀/薄荷档亮度近乎相同，红绿 CVD 难分；0.4 档线普通路线无标记。维持 S3（已有秒数+条长+音效冗余）。
- **P12-F8**：结算空状态 COCOA@0.62 独立复算 = **4.29:1**（20px，P12 报 4.40，口径差异但同判「差一点到 4.5」）；`flavor_radar.gd` 网格白@0.22 on 靛(25324A) 复算 = **2.00:1**、薄荷填充@0.45 = **2.20:1**（P12 报 2.03/2.24，一致；装饰性参考线可豁免）；`ui/customer_avatar.gd` 全仓 grep 零引用——**死代码确认**，一旦复用即违反减弱动态门控，建议加门控或删除。

---

## 与原报告的偏差记录（供合并时参考）

1. **P4-1 低估**：实际最坏 1112px（P4 报 969px）——含封口+无返工+批次尾串的完整状态行更长；结论方向不变。
2. **P4-6 补充**：zh 最坏 1001px 在 1040 内不溢出，此条为 en 侧问题；en 实测 1084px（定位名实际渲染 "Positioning: Positioning · Flavor" 比 P4 假设更长）。
3. **P4-4 修正**：zh 列六个事件名全部正确，仅 en 列 3 键 4 处错——修复面缩小为 en-only。
4. **P12-F4 修正**：结算卡底实为 `Color.WHITE`（night_settlement_panel.gd:118），非 P12 所述 MINT 混色；对比度结论反而更差（GOLD 2.43 vs 2.17 口径反转无关紧要，均 <3）。
5. **P12-F5 子项 REFUTED**：「锁定暗卡 body 3.77:1」不可复现（实算 ≈9.5:1），应从修复清单剔除。
6. **P4-11（=D3 细节）修正**：`MENU_BOARD_PRICE_BUDGET` zh 列 "Value · %d" 并非「已译」而是英文草稿误入；D3 实际未译键共 **8 个**（含两报告都漏掉的 `MENU_BOARD_PRICE_SET`）。
7. **P7-F5/P7-F7 独立复跑**：bot（regular D9 precision：0/0 触发）与 sim（rush cash 2713）均与原报告逐字复现。
