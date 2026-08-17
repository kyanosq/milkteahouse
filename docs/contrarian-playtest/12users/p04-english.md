# P4 英文局

试玩视角：EN-only 玩家，全流程英文体验审查。方法：4 张英文窗口截图（menu+settings / day demo D12 / campaign report / day-end D12，1280×720）+ PIL 像素/字体度量（用游戏实际字体 `game/assets/fonts/LXGWWenKai-Regular.ttf` 精确测宽）+ `localization_check.tscn` headless + `ui.csv`（899 键）与数据本地化代码全量走查。引擎 Godot 4.6.3。

headless 回归：`[LOCALIZATION] passed locales=2 static=true format=true data=true required_keys=true fallback=true`。en 列 0 个 CJK 字符；%d/%s/%f/%% 格式符双语 parity 全部一致。

## 发现（证据/复现/期望vs实际/修复方向/置信度，S0-S3）

### 1. [S1] 制杯状态行英文溢出：长配方下文字冲出面板直至屏幕外
- 证据：`game/scenes/day_shop/day_shop.gd:385-393`（status_panel 位于 (388,612)，宽 505，Label font 17，无 autowrap、无 text_overrun、无 clip）；`:1266-1283` 组串用**全名** `" + ".join(parts)`（茶底+奶基+全部小料）。按真实字体度量：
  - `Current Cup · Assam Black Tea + No Milk (Pure Tea) + Brown Sugar Jelly + Fish Mint · Full Sugar · · Standard Batch` ≈ **969px**（面板 505px；388+969=1357 > 1280，尾部直接画出屏幕）
  - 1 小料常见情形 `Roasted Oolong + Oat Milk + Sweet Red Bean + Coconut Jelly …` ≈ 851px（终点 x≈1239，贴屏幕右缘）
  - 对照 zh 最差（纯茶+2 小料+封口后缀）≈ 614px，同样超面板但尚在屏内——英文把问题放大 ~1.6 倍。
- 复现：Day 8+ 解锁折耳根后，任选 `Roasted Oolong + No Milk (Pure Tea) + 两种小料 + Full Sugar`，看中央制杯区底边状态条。
- 期望 vs 实际：期望状态行限定在 505px 面板内；实际左对齐单行向右溢出到面板外/屏幕外。
- 修复方向：join 改用 `ingredient_short_name`；或加 `text_overrun_behavior = TRIM_ELLIPSIS`（与 hud_cost 同款）；或 autowrap 两行并加高面板。zh 也应一并修。
- 置信度：高（字体度量 + 代码几何，非目测）。

### 2. [S1] 逗号缺失（机翻残留）仍是系统性问题：上轮只修了 5 处教学串，同款病还有 10 处
- 证据（`game/localization/ui.csv`，en 列原文）：
  - `PAUSE_CONTROLS_HINT`（L17）"Touch: Tap ingredients the shake button and order cards" —— 读作"点击原料[和]摇茶按钮"，缺两处逗号
  - `SETTINGS_MOTION_DESC`（L19）"Disables camera shake flying coins cup wobble and customer idle motion." —— 五个名词连排，无法断句
  - `SETTINGS_CONTROLS_MENU_GAMEPAD`（L162）/`..._KEYBOARD`（L163）"Music SFX motion haptics and language save immediately."
  - `MENU_RESET_BODY`（L153）"Your Day %d progress recipes and upgrades will be overwritten.\nAudio motion haptics and language settings will be kept."
  - `CONTRACT_INTRO_BODY`（L44）"After Day 15 sign one contract each night."（状语后缺逗号）
  - `TUTORIAL_4_BODY`（L333）"After all ingredients are ready shake the cup."
  - `TUTORIAL_5_BODY`（L336）"improve tips combos and research resources"
  - `UPGRADE_SMART_SUGAR_DESCRIPTION`（L360）"After milk is selected the current order sugar level is matched automatically."
  - `CAMPAIGN_VERDICT_S`（L434）"Service research and management now form a strong loop."
  - `CAMPAIGN_CONFIRM_BODY`（L457）"Recipes equipment and current progress reset while your best rating remains."
- 复现：暂停面板（设置首屏第一条帮助文字）、重开确认、签约介绍、教学 4/5、S 级结算判语、新店+确认正文。
- 期望 vs 实际：期望英文并列成分有逗号（"camera shake, flying coins, cup wobble, and customer idle motion"）；实际中文顿号被直译丢弃。设置/暂停是英文玩家最先读的两屏，机翻观感最重。
- 修复方向：对 en 列做一次全文 sweep（"名词+名词+and+名词"无逗号模式），逐条补 serial comma。
- 置信度：高。

### 3. [S2] 糖度 "Fu/No" 截断回归：语言切换路径未修
- 证据：糖度瓦片修复只落在建架路径 `game/scenes/night_lab/night_lab.gd:655`（`btn.text = short_name if kind == "sugar" else short_name.left(2)`，注释标明 P4 修复）；但运行时切语言刷新路径 `:1209` 仍是无差别 `tile["btn"].text = short_name.left(2)`（对所有无图标瓦片生效，糖度恰无图标）。
- 复现：夜间研究室 → 打开设置 → 切换语言（zh↔en）→ Sugar 架瓦片变回 "No/30/50/70/Fu"。
- 期望 vs 实际：期望语言切换后糖度瓦片仍显示完整短名（None/30%/50%/70%/Full）；实际回到两字符截断（"Fu"）。
- 修复方向：`:1209` 复用 `:655` 的 sugar 分支判断（tile 里存 kind 或 sugar 标记）。
- 置信度：高（两处代码直接对照）。

### 4. [S2] 新店+路线日历的事件名与实际事件英文名对不上
- 证据：`LEGACY_ROUTE_RUSH_CALENDAR`（L465）"Second week opens with Group Visit → Lunch Rush."；`..._PRECISION_CALENDAR`（L471）"…Critic Day → Light-Drink Trend."；`..._TREND_CALENDAR`（L477）"…Camera Visit → Brown-Sugar Trend."。而实际事件名（`EVENT_*_NAME`，简报大标题/HUD 均用）：group_day="**Friends' Day**"、critic_day="**Critic Visit**"、influencer_day="**Camera Crew**"、brown_sugar_trend="**Brown-Sugar Buzz**"。6 个名字里 4 个对不上（Lunch Rush、Light-Drink Trend 恰好一致）。
- 复现：打完首店 → "Open New Shop +" → 确认面板任一路线详情第二行；进游戏第二周对照简报标题。
- 期望 vs 实际：期望日历预报与到日实际出现的事件同名，玩家能做准备；实际是两套称呼（"Critic Day"来的是"Critic Visit"）。
- 修复方向：CALENDAR 文案改为引用 `EVENT_*_NAME`（组合键或翻译时对齐词表）。
- 置信度：高。

### 5. [S2] 周转（Rush）路线文案与数值不符：奖励写 +1 实发 +2；客流写 +12% 实为 ×0.85
- 证据：`LEGACY_ROUTE_RUSH_REWARD`（L463）"Every 3 correct cups +1 Coin"、`..._SUMMARY`（L464）同；`game/autoload/legacy_routes.gd:60` `sale_bonus` rush 分支 `return 2 if streak > 0 and streak % 3 == 0`——HUD `DAY_ROUTE_PROGRESS_RUSH` 显示的 Sign +2 与卡片承诺 +1 直接矛盾。风险行 `LEGACY_ROUTE_RUSH_RISK` "Arrivals +12%"（L462）vs `:52` `spawn_multiplier` rush=**0.85**（间隔 −15% ≈ 到店 +17.6%；D3 注释表明是有意加强，文案没跟上）。
- 复现：新店+选 Turnover District，每 3 连击看 HUD "Sign +N" 与路线卡 "+1 Coin" 对照。
- 期望 vs 实际：期望文案=规则；实际奖励虚报一半、风险少报。
- 修复方向：文案改 "+2 Coins"与"Arrivals +15% faster"（或回调数值），PRECISION（−12%↔0.88 ✓）与 TREND（+6%↔0.06 ✓）已对齐，仅 RUSH 失配。
- 置信度：高（代码与 CSV 直接对照）。

### 6. [S2] 战役报告底部汇总单行：二周目最坏 ~1072px，超 1040px 可用宽度且无 autowrap
- 证据：`game/scenes/campaign_summary/campaign_summary.gd:158-183`：`legacy_line` 为单行 Label（font 15、居中、无 autowrap），拼接 `CAMPAIGN_TEAM`+`CAMPAIGN_LEGACY`+`CAMPAIGN_ROUTES_CLEARED`+路线统计+`CAMPAIGN_POSITIONING`+回暖日。面板 1100 宽、左右各 30 边距。度量最坏组合 "Team · Xiaoman on Duty 12 Days · Sign Legacy · 1 Runs · Best S / 92 · Routes 1/3 · Event-matched serves: 24 · Positioning: Flavor · Recovery days: 2" = **1072px > 1040px**，居中文字会两边探出报告面板。本次 SHOT_CAMPAIGN 截图场景无店员/路线/定位（实测 mint 行 662px 居中无溢出），故截图不显——需二周目条件才触发。
- 复现：新店+第二轮带店员+选定定位+路线通关≥1 的收官报告。
- 期望 vs 实际：期望汇总行在面板内；实际长配置溢出面板边框。
- 修复方向：给 `legacy_line` 加 `autowrap_mode = WORD_SMART`（宽 1040、两行）或拆两行。
- 置信度：高（组合路径代码可证，宽度字体度量）。

### 7. [S3] HUD 成本条 "Stock12" 缺空格（上轮已报，仍未修）
- 证据：`DAY_HUD_COSTS_NEXT`（L190）`Stock%d · Rent D%d` → 渲染 "Stock12 · Rent D7"；`DAY_HUD_COSTS_TODAY`（L191）`Stock%d · Rent≤%d` → "Stock12 · Rent≤7"（两处 label 与数字间无空格）。zh "补货12" 合法，英文不行。截图 /tmp/p4_b.png 顶栏金币药丸下方可见。修复："Stock %d · Rent day %d" / "Rent ≤%d"。

### 8. [S3] `RECIPE_BOOK_TIER` 英文用 «» 角引号
- 证据：L668 `«%s»` → 图鉴详情渲染 «Signature»。全项目英文其余处用 “ ”（如 NIGHT_TEST_HIT "priced at…“%s”"），«» 是法/俄式排印，语境错误。修复：英文改 “%s” 或直接去引号（zh 保留《》）。

### 9. [S3] 复数与格式一致性（coins 大小写、"1 Runs"、"New Shop+" 空格、分隔符）
- `%d Coins` 17 处 vs `%d coins` 14 处混用，且同屏出现（订单卡 `ORDER_HINT_MENU` "Featured · 15 coins" vs 奖励弹 `DAY_REWARD_COINS` "+15 Coins"）。
- `CAMPAIGN_LEGACY` "%d Runs" → "1 Runs"；`MENU_SIGN_SUMMARY`/`ENDLESS_SIGN_RANK` "%d Stamps" → "1 Stamps"。英文需复数分支或改 "Runs: %d"。
- "New Shop+"（DAY_ROUTE_ACTIVE、MENU_ROUTE_SUMMARY）vs "New Shop +"（CAMPAIGN_NEW_SHOP、CAMPAIGN_CONFIRM）空格不统一。
- 分隔符混用：`|`（ENDLESS_SIGN_RANK、NIGHT_HUD、NIGHT_BOOK）vs `·`（其余全部）；连字符 " - "（CONTRACT_REVENUE_SPRINT_DESCRIPTION）vs 破折号 "—"（DAY_HUD_GOAL_TIP、NIGHT_TRY_LOW）。修复：定一份标点规范后 sweep。

### 10. [S3] 措辞打磨（机翻腔轻微残留/歧义）
- `STAFF_HIRE_BODY`（L42）"Traits reveal through real events after hiring." → "Traits are revealed through real events"。
- `UPGRADE_RESERVE_RISK`（L373）"Buying leaves %d coins below…" —— "Buying leaves" 易误读成名词短语；改 "This purchase leaves you %d coins below…"。
- `LEGACY_ROUTE_TREND_SUMMARY`（L476）"hot features attract 6% traffic each and every matching featured sale earns +3 coins" —— "each and every" 断句歧义；改 "each, and every matching featured sale…" 或拆句。
- `TUTORIAL_GATE_HINT`（L899）"attempt(s)" 是开发写法；改 "more attempts" 或按数分支。
- `INGREDIENT_BROWN_SUGAR_SHORT`（L629）"Brown" 单独出现在杯状态/订单卡小料位（"Boba; Brown"）语义不足；建议 "Br. Sugar"/"B. Sugar"。
- `DAY_STAFF_SLACKER_IDLE`（L232）"Slacking · Back Queue Support Paused" 句中 Title Case；改 "Back-queue support paused"。

### 11. [S3·跨语言注] 菜单板定价标签 zh 列仍是英文
- 证据：`MENU_BOARD_PRICE`（L749）"Pricing,Pricing"、`..._STANDARD`（L751）与 `..._PREMIUM`（L752）zh 列均为英文原文，而同组 `..._BUDGET` zh 已译 "Value · %d"——同一面板中英混排。英文玩家不受影响，但属 CSV 卫生问题，顺手记录。

## 检查过无问题的面

- **回归**：`localization_check` headless 全绿（899 键、双语表、静态 Control 自动翻译、fallback）。en 列零 CJK；`.gd` 内 100 处 CJK 字面量全部是数据 fallback（经 `GameLocale._data_text`→tr() 或仅 zh 用的 sugar 缩写替换），英文路径无泄漏。
- **52 个显式键质量**：`TITLE_*`（"Coral & Mint · Ready for another day"、"Serve by day. Turn wild ideas into new drinks by night."）、`PAUSE_MENU_STAY` "Stay Here"、`MENU_RESTART_KEEP` "Keep Progress"、`LAB_GROUP_*`（"Tea Base/Milk/Toppings (≤2)/Sugar"）、`NIGHT_*` 均自然；除发现 2/7 所列各别串外无新机翻。
- **货币统一**：全库已无 ¥/￥，统一 coins（上轮问题已修，仅剩大小写混用见发现 9）。
- **事件简报与结算语境**：`EVENT_*` EN 语境自然（"Anonymous critics are hiding in the queue."、"The magazine editor leads this round of critics"）；二遍修饰词（Editor/Live Marathon/Office Party/Delivery Rush）命名有味道且 challenge/benefit 表述与 daily_events.gd 参数一致。布局安全：简报面板 680、效果卡 314/正文 282 均 autowrap（`day_shop.gd:588-625`），长挑战行（Office Party 80 字符）自动换行撑高不溢出。
- **市场检验结算**：`MARKET_SETTLEMENT_*`（920 面板、416 卡片、outcome autowrap，`night_settlement_panel.gd`）；截图注入的测试名（"Starlit Osmanthus" 等）已按 locale 分流，无 zh 泄漏。
- **委托面板**：1096 宽、328 卡、description/pressure/reward 全 autowrap（`endless_contract_panel.gd:139-196`），169 字符的 Revenue Sprint 描述安全换行。
- **路线按钮宽度**（新店+确认面板，276px/字15）：最长 "Trend-match sales earn +3 Coins" 235px、"Each hot feature adds 6% traffic" 233px，含默认内边距仍留 ~20px 余量，实测不溢出。
- **3D 短名标签**：`shop_stage.gd` 世界标签仅悬停/焦点单项显示（非常驻），最宽 "Cheese Foam" ≈0.247 world（≈罐距 0.24）不会与相邻标签同帧碰撞；奶基 28px/糖泵 26px（"None/30%/50%/70%/Full"）宽度安全。
- **HUD 数字格式**："Day 12 · 87s"、"0/98 · 3★ at 137"、"Best combo ≥ x3"、"Patience +18%"、"Perfect 12" 全库一致；截图边缘扫描（四边 3px）4 张均无文字贴边/出界像素。
- **组合键拼接**：`CAMPAIGN_TEAM`(尾"· ") + `CAMPAIGN_LEGACY` + `CAMPAIGN_ROUTES_CLEARED`(首" · ") 拼接无双分隔符；`DAY_CUP_STATUS` 的 batch/封口前缀组合无双 "··"；`MENU_SAVE_SUMMARY`+`MENU_SIGN_SUMMARY`+`MENU_ROUTE_SUMMARY` 换行拼接正确。
- **教程**：1-6 步正文/提示（含 456px 正文 autowrap、gamepad 提示变体）长度与语义 OK；TUTORIAL_GATE 两键自然。
- **战役报告正文**：verdict 760px 宽 autowrap（最长 S 级判语 745px 单行可容）；四维卡片 13px 明细（"Perfect 196 · Equipment 7/10" 183px）不溢出；本次截图 mint 汇总行 662px 居中在界内（最坏组合见发现 6）。
- **暂停/设置布局**：540 面板、480 控件提示 autowrap、240 宽开关、重绑行（"Pause / Settings · Click to Rebind" ~280px）均安全；`SETTINGS_DISPLAY_NOTE`（109 字符）在面板内正常换行。
