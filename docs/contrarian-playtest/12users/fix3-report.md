# Fix-3 修复报告 · ui.csv 文案总批

修复代理 Fix-3 · 日期 2026-08-17 · 基线 HEAD `c456b0b`。
范围：`game/localization/ui.csv` 全量文案批（新键录入 + V3/P4 确认的 CSV 侧修复）+ 重生成 `ui.en.translation` / `ui.zh_CN.translation`。**未改任何 .gd/.tscn 文件**（工作区中 .gd 改动来自并行代理）。

结果：ui.csv 899 → 913 键（+14 新键、0 删、0 改名）；CSV 结构自检（3 列/无重复键/双语格式符 parity/en 列零 CJK）全过；13 个 check 全绿（见文末）。

---

## 一、录入新键（14 个，zh+en 双语，格式符与代码实测调用逐一对齐）

### Fix-1 交接的 9 键（文案按 fix1-report 建议原样录入）

| 键名 | en | zh | 格式符（代码实测） |
|---|---|---|---|
| `NIGHT_NAME_REQUIRED` | Give the drink a name before shelving it. | 先给这杯饮品起个名字，再上架送检。 | 无参（night_lab.gd:1161） |
| `MENU_BOARD_SUBTITLE_SLOTS` | Choose up to %d featured slots. Featured drinks become real customer orders and use their menu price. | 最多选择 %d 款主推。主推饮品会成为真实顾客订单，并按研发菜单价结算。 | 1×%d（menu_board_panel.gd:183 传 [slot_limit]） |
| `MENU_BOARD_FULL_SLOTS` | All %d featured slots are full. Remove one featured drink first. | %d 个主推槽已满，请先移出一款。 | 1×%d（menu_board_panel.gd:481） |
| `TUTORIAL_3_HINT_TOUCH` | Tap the highlighted ingredient buttons. | 点按高亮的原料按钮即可。 | 无参（tutorial_overlay.gd:245） |
| `TUTORIAL_SHAKE_HINT_TOUCH` | Shake your device, or tap the big shake button. | 摇晃设备，或点按大摇茶按钮。 | 无参（tutorial_overlay.gd:247） |
| `SETTINGS_CONTROLS_MENU_TOUCH` | Touch: Tap to select · Back button to exit\nMusic, SFX, motion, haptics, and language save immediately. | 触控：点按选择 · 返回键退出\n音乐、音效、动态、触觉与语言偏好会立即保存。 | 无参（pause_panel.gd:522） |
| `SETTINGS_CONTROLS_NIGHT_TOUCH` | Touch: Tap ingredients to select · Settings button in the top-right corner\nAll settings save immediately. | 触控：点按原料选择 · 设置在右上角\n所有设置会立即保存。 | 无参（pause_panel.gd:530） |
| `SETTINGS_CONTROLS_DAY_TOUCH` | Touch: Tap ingredients · Shake the device or tap the big button to shake\nTap the staff card or order cards to interact. | 触控：点按原料 · 摇晃设备或点按大按钮摇茶\n点按店员卡或订单卡进行互动。 | 无参（pause_panel.gd:538） |
| `SETTINGS_KEY_RESERVED` | %s is reserved: number keys, Enter, and Tab run shop shortcuts and menus. | %s 是保留键：数字键、Enter 与 Tab 承担店铺捷径和菜单操作。 | 1×%s（pause_panel.gd:625 传 [keycode_string]） |

注：含英文逗号的 en 值已按 CSV 规范加双引号包裹（`TUTORIAL_SHAKE_HINT_TOUCH`、`SETTINGS_CONTROLS_MENU_TOUCH`、`SETTINGS_KEY_RESERVED`）。

### Fix-2 交接的 4 新键 + 1 改键

| 键名 | en | zh | 格式符（代码实测） |
|---|---|---|---|
| `MENU_LEGACY_SUMMARY` | \nBest Run: %s · %d pts · Routes %d/%d | \n历史最佳：%s · %d 分 · 路线 %d/%d | %s+%d+%d+%d（main_menu.gd:322 传 4 参：grade/score/完成路线数/3） |
| `CONTRACT_RANK_DEFEND_COUNT` | Defending · %d cleared / %d failed | 守擂中 · 完成 %d · 失败 %d | 2×%d（endless_contracts.gd:298 传 completed/failed） |
| `POSITIONING_REDUNDANT` | Smart Sugar already owned — Flavor adds nothing | 已拥有智能糖控台——风味无额外效果 | 无参（upgrade_panel 接线待定，见「待接线点」） |
| `UPGRADE_SMART_SUGAR_REDUNDANT` | Flavor positioning already automates sugar — this level adds nothing (tier II still applies) | 「风味」定位已自动匹配糖度——一级无额外效果（二级仍有效） | 无参（同上） |
| `DAY_HUD_COSTS_NEXT`（改现有键） | `Stock %d · Rent D%d·%d` | `补货%d · 租金D%d·%d` | **2 参 → 3 参**（day_shop.gd:2956 现仍传 2 参，见「待接线点」#1） |

`CONTRACT_RANK_MAX`（ui.csv 原有）按 Fix-2 已接入 next_rank_text(30+)，保留不动；`CONTRACT_RANK_DEFEND` 保留为缺键回退。

### 本批新增 1 键（B.9）

| 键名 | en | zh | 说明 |
|---|---|---|---|
| `LUNCH_RUSH_PRICE_HINT` | Today's quick-serve trend: value-priced drinks (≤%d coins) get ordered more often. | 今日快手风向：让利价点（≤%d 金币）的饮品更常被点。 | 1×%d，实参=13（menu_catalog.gd:478 lunch_rush 价线）。MENU_BOARD_FORECAST 每日恒显不宜挂条件句，故另立键，接线点见下 |

---

## 二、V3 确认的 CSV 修复（逐条）

### B1. 定价 8 键中文补译 + 双语语义改写（V3 #4 / Fix-2 待拍板 #3）

zh 列原为英文原文的 8 键全部补译，且 **en+zh tooltip 一并按 Fix-2 新语义改写**（定价不再改全局到店间隔，改为该款被点的频率：让利 3 轮转位/标准 2/溢价 1；价差按价表 爆款[16,18,21]、招牌[13,15,17]、普通[10,12,14] 即让利 −2、溢价 +2~3）：

| 键 | 旧（zh=en 英文） | 新 |
|---|---|---|
| `MENU_BOARD_PRICE` | Pricing | en `Pricing` / zh `定价` |
| `MENU_BOARD_PRICE_BUDGET` | Value · %d | en `Budget · %d` / zh `让利 · %d` |
| `MENU_BOARD_PRICE_STANDARD` | Standard · %d | en `Standard · %d` / zh `标准 · %d` |
| `MENU_BOARD_PRICE_PREMIUM` | Premium · %d | en `Premium · %d` / zh `溢价 · %d` |
| `MENU_BOARD_PRICE_BUDGET_TIP` | featured arrivals +2% faster | en `−2 coins per cup · this drink is ordered more often` / zh `每杯少 2 金币 · 该款会更常被点` |
| `MENU_BOARD_PRICE_STANDARD_TIP` | no change to foot traffic | en `The tested market price · normal order frequency` / zh `市场验证价 · 点单频率不变` |
| `MENU_BOARD_PRICE_PREMIUM_TIP` | arrivals 3% slower | en `+2~3 coins per cup (by tier) · this drink is ordered less often` / zh `每杯多 2~3 金币（按档位）· 该款会更少被点` |
| `MENU_BOARD_PRICE_SET` | Price set to %d | en `Price set to %d` / zh `已定价 %d` |

### B2. 逗号缺失 11 行（V3 #6 / P4-2，en 列补 serial comma，含逗号后字段加引号）

`PAUSE_CONTROLS_HINT`、`SETTINGS_MOTION_DESC`、`CONTRACT_INTRO_BODY`、`MENU_RESET_BODY`（2 处）、`SETTINGS_CONTROLS_MENU_GAMEPAD`、`SETTINGS_CONTROLS_MENU_KEYBOARD`、`TUTORIAL_4_BODY`、`TUTORIAL_5_BODY`、`UPGRADE_SMART_SUGAR_DESCRIPTION`、`CAMPAIGN_VERDICT_S`、`CAMPAIGN_CONFIRM_BODY`。另顺手修了同行未被清单点名的两处同款连排（TUTORIAL_4 尾句 "Once sealed review…then confirm"、TUTORIAL_5 "After closing use…"）。

### B3. 路线日历事件名 en 对齐（V3 #12 / P4-4，en 列 3 键 4 处，zh 原本正确）

- `LEGACY_ROUTE_RUSH_CALENDAR`：Group Visit → **Friends' Day**
- `LEGACY_ROUTE_PRECISION_CALENDAR`：Critic Day → **Critic Visit**
- `LEGACY_ROUTE_TREND_CALENDAR`：Camera Visit → **Camera Crew**；Brown-Sugar Trend → **Brown-Sugar Buzz**

### B4. 教学第 6 步星级纠正（V3/P4 均未列、任务指定；代码实核 day_shop.gd:2604-2611：<70% = **0★**，≥70% = 1★，≥100% = 2★，≥1.4x = 3★）

- `TUTORIAL_6_BODY` en：旧 "Miss 70% of it and the day lands at 1 star"（错）→ "Reaching 70% of the goal gives 1 star, the goal itself 2 stars, and 1.4x the goal 3 stars with +3 inspiration. Below 70% the day scores no stars — stars decide your final report."
- zh：旧「不足七成只有 1 星」→「达到目标七成得 1 星，达到目标得 2 星，1.4 倍得 3 星并奖励 3 灵感；不足七成则没有星。」

### B5. HUD "Stock12" 加空格（V3 #21/P4-7）

- `DAY_HUD_COSTS_TODAY`：`Stock%d · Rent≤%d` → `Stock %d · Rent ≤%d`（zh 合法不动）
- `DAY_HUD_COSTS_NEXT`：并入三参改键 `Stock %d · Rent D%d·%d` / `补货%d · 租金D%d·%d`

### B6. `RECIPE_BOOK_TIER` en 角引号

`«%s»` → `“%s”`（zh 保留《%s》）。

### B7. 复数与格式一致性批次（V3 #21/P4-9）

- **coins 大小写**：en 列 25 处 `Coins`/`Coin` 全部统一小写 `coins`/`coin`（含 `DAY_RESULT_CONTRACT_FAILED` 的 `%d-coin fee not refunded` 句式调整）。
- **"1 Runs"/"1 Stamps"**：改措辞规避单复数——`CAMPAIGN_LEGACY` `%d Runs`→`Runs: %d`；`MENU_SIGN_SUMMARY`、`ENDLESS_SIGN_RANK`、`DAY_RESULT_ENDLESS_HINT` `%d Stamps`→`Stamps: %d`（zh 本无此问题，不动）。
- **"New Shop+" 空格**：统一为无空格 `New Shop+`——`CAMPAIGN_NEW_SHOP`（en+zh「新店+」）、`CAMPAIGN_CONFIRM`（en+zh）；`MENU_ROUTE_SUMMARY`/`DAY_ROUTE_ACTIVE` 原本已是。
- **分隔符统一 `·`**：`ENDLESS_SIGN_RANK`、`NIGHT_HUD`、`NIGHT_BOOK` 的 `|`/`｜` → `·`（en+zh 同步）；`CONTRACT_REVENUE_SPRINT_DESCRIPTION` 连字符 `" - "` → `" — "`（em dash，与 zh ——对齐）。

### B8. rush 路线数值与客流措辞（V3 #13/P4-5；代码实核 legacy_routes.gd sale_bonus +2/每 3 杯、spawn_multiplier 0.85）

- `LEGACY_ROUTE_RUSH_REWARD`：+1 Coin → **+2 coins** / 「+2 金币」
- `LEGACY_ROUTE_RUSH_SUMMARY`：pays +1 coin / refill 12% faster → **+2 coins / 15% faster**；zh 同步（「补位速度提高 15%」）
- `LEGACY_ROUTE_RUSH_RISK`：Arrivals +12% → **Arrivals +15%** / 「到店速度 +15%」（按 V3 建议口径，= 到店间隔 ×0.85）

### B9. lunch_rush 咬合提示

新增 `LUNCH_RUSH_PRICE_HINT`（见上表）。`EVENT_LUNCH_RUSH_BENEFIT` 等事件简报键保持不动（Fix-2 §12 只要求匹配行/预告侧标注）。

---

## 三、待接线点（主会话接，均为 .gd 侧一行级改动）

1. **[必接] day_shop.gd:2955-2956**：`DAY_HUD_COSTS_NEXT` CSV 已改 3 参，代码仍传 2 参 → 当前期（租期外日）HUD 刷新会打 `String formatting error: not enough arguments` 并显示原始模板（onboarding_check 仍绿，但日志有 5 次该错误）。接法（Fix-2 §11）：`var preview := OperatingCosts.rent_preview(GameState.day)` 后传 `[stock_cost, preview.day, preview.amount]`。
2. **LUNCH_RUSH_PRICE_HINT**：建议在 menu_board_panel.gd:185（`MENU_BOARD_FORECAST` 渲染处）当 `DailyEvents.next_event(...).id == "lunch_rush"` 时追加一行，或 day_shop `_show_event_briefing`；实参 13（menu_catalog lunch_rush 价线）。
3. **POSITIONING_REDUNDANT / UPGRADE_SMART_SUGAR_REDUNDANT**：upgrade_panel 定位卡/糖台卡警告文案（Fix-2 §1 已留钩子 `positioning_redundant()` / `smart_sugar_redundant()`）。
4. **MENU_BOARD_FORECAST/MENU_BOARD_TRAFFIC "+-9%"**（V3 #16）：格式串 `+%d%%` 在负值时渲染 "+-9"，纯 CSV 无法分支——需 gd 侧按符号组装整串或换 `%+d`（本次未动格式串）。
5. **P4-10 措辞打磨 6 处**（STAFF_HIRE_BODY/UPGRADE_RESERVE_RISK/TREND_SUMMARY "each and every"/TUTORIAL_GATE_HINT "attempt(s)"/INGREDIENT_BROWN_SUGAR_SHORT "Brown"/DAY_STAFF_SLACKER_IDLE Title Case）：不在本次 B 清单内，未动，留待下一批。

---

## 四、验证记录（全部绿色）

CSV 自检（python csv 解析）：913 行全 3 列、无重复键、en/zh 格式符逐键 parity 一致、en 列零 CJK、批后零残留（大写 Coins/「|」/「New Shop +」/«»/「%d Runs|Stamps」均无）。翻译已用 `--headless --import` 重生成。

| check | 结果 |
|---|---|
| localization_check | `[LOCALIZATION] passed locales=2 static=true format=true data=true required_keys=true fallback=true` |
| menu_check | `[MENU] passed …` |
| onboarding_check | `[ONBOARDING] passed …`（日志含 5 次待接线点 #1 的格式错误，非断言失败） |
| input_check / release_settings_check | passed（触屏三键 + SETTINGS_KEY_RESERVED 路径） |
| endless_contract_check / operating_cost_check | passed（COSTS_NEXT 双语断言 bilingual=true） |
| night_check | 跑完 T1/T2/T3 全程零错误（SUBTITLE_SLOTS/药丸断言过） |
| upgrade_check / campaign_check / staff_check | passed |
| menu_catalog_check / dark_menu_check | passed |

改动文件：`game/localization/ui.csv`（+75/−61 行）及再生成的 `game/localization/ui.en.translation`、`game/localization/ui.zh_CN.translation`。未提交 git。
