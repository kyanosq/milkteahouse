# P1 新手首小时

- 试玩代理：P1「新手首小时」（第 1-5 天：教学、首日循环、首个升级、首个传说发现）
- 方法：13 次无头自动试玩（9 个新组合，见附表）、6 个只读运行时探针（`-s /tmp/p1_gate_probe*.gd`，日志 `/tmp/p1_probe*.log`）、2 张窗口模式教学截图 + PIL 像素检查（`/tmp/p1_tut3.png`、`/tmp/p1_tut6.png`）、代码走读。未修改任何 `game/` 文件。
- 引擎：Godot 4.6.3 headless / 1280x720 windowed。

## 发现

### F1: 教学门控「动手练习」步骤在真实输入下无法完成——键鼠/触摸全部失效，步骤 4（摇杯）对包括手柄在内的所有模态失效（S1）

- 证据:
  - `game/ui/tutorial_overlay.gd:62` — 教学覆盖层根节点 `mouse_filter = Control.MOUSE_FILTER_STOP`，尺寸铺满安全区（同文件 221-229 行），且是 `ui_frame` 的最后一个子节点（`game/scenes/day_shop/day_shop.gd:459`），绘制在最顶层。Godot GUI 语义：全屏 STOP 控件吃掉其下所有鼠标/触摸点击，被点按钮零反馈。
  - `game/scenes/day_shop/day_shop.gd:275-276` — `_input()` 中 `if not running: return`；而 `_show_tutorial()` 置 `running = false`（`day_shop.gd:703`）。教学期间数字键 1-9、`game_shake`、Q/E、鼠标甩动全部短路。
  - `game/scenes/day_shop/day_shop.gd:1175` — `_on_shake()` 首行 `if cup_sealed or not running: return`；`_can_gesture_shake()`（1196-1198）同样要求 `running`。
  - 运行时探针（`/tmp/p1_probe3.log`、`p1_gate_probe4.gd`）：
    - 门控步骤 3（index 2）期间用 `Input.parse_input_event` 注入 `KEY_1` → `cup_base=null`；教学结束后同一注入 → `cup_base` 成功设置（对照组成立，证明阻断来自教学态而非注入方式）。
    - 同步骤模拟手柄焦点 + `ui_accept` → `cup_base` 成功、`_step_completed()==true`（手柄是唯一能过步骤 3 的模态）。
    - 门控步骤 4（index 3）期间把杯子直接填满（base/milk/sugar 全就位）后连按 3 次 `_on_shake()` → `cup_sealed=false, shake_progress=0.0`——摇杯被 `not running` 硬挡，任何模态都过不去。
    - 探针实测门控按钮中心 `(450,110,386,54)`/`(840,110,386,54)` 位于聚光区内、教学卡片 `(640,248,500,273)` 无遮挡（1280x720 窗口模式，布局稳定后）——UI 看起来完全可点，实际点了没反应。
  - 失败路径实测（`/tmp/p1_probe.log`）：点两次「下一步」后 `_gate_bypassed=true`，玩家看到提示「先动手试一次——再尝试 1 次后将跳过此步」，随后强制跳过并附注「（练习步骤已跳过——可随时在暂停菜单重看教学。）」——而重看教学会再次冻结 `running`，门控依旧死锁，该建议是死循环。
  - 回归缺口：`game/tests/onboarding_check.gd:39-46` 通过直接调用 `shop._on_base()` / `_advance()` 验证门控，从未经过输入层——这解释了 25/25 全绿与真实体验相悖。
- 复现路径 / 推理链: 新档第 1 天 → 教学 → 步骤 3「跟着中央步骤制作」：鼠标点聚光区内的「1 阿萨姆」按钮无任何反应（覆盖层吞掉）；按数字键 1 也无效（`_input` 短路）；手柄玩家可焦点+确认通过；到步骤 4「摇匀、封口」时所有模态全部无效 → 每位键鼠/触摸玩家都会连点两次「下一步」触发自动放行，教学的核心交互练习（D2-B 门控）形同虚设，且失败提示文案指责玩家「先动手试一次」——玩家其实根本无法尝试。
- 期望 vs 实际: 期望门控步骤让玩家真实完成一次选茶基/摇杯封杯（时钟冻结但店铺可操作）；实际是键鼠/触摸玩家在游戏第 1 分钟内遭遇「点了没反应→被系统代为跳过练习」，移动端（无键盘、触摸被覆盖层拦截）两步门控 100% 必然跳过。
- 修复方向: 教学门控期间为练习动作开输入白名单——(a) 覆盖层对聚光矩形做鼠标透传（或整体改 PASS、只保留卡片自身 STOP），(b) `_input` 的 `not running` 早退与 `_on_shake`/`_can_gesture_shake` 的 `running` 守卫增加「教学练习中」豁免（如 `tutorial_practice_active` 标志），(c) 回归测试至少用 `Input.parse_input_event` 走一遍真实输入路径，钉住本缺陷。
- 置信度: 高（三条独立证据链：代码守卫、运行时注入对照、UI 几何；唯「真机手柄十字键能否导航到覆盖层下按钮」未实测，焦点遍历理论上可达，探针以直接 grab_focus 模拟）。

### F2: 教学第 6 步星级规则文案与结算代码相反——低于七成实为 0★，文案写成「只有 1 星」（S3）

- 证据:
  - `game/localization/ui.csv:830`（TUTORIAL_6_BODY）中/英双语文案：「营收达到目标得 2 星，1.4 倍得 3 星并奖励 3 灵感；**不足七成只有 1 星**」/ "Miss 70% of it and the day lands at **1 star**"。
  - `game/scenes/day_shop/day_shop.gd:2507-2513`：`earned >= 1.4×goal → 3★；>= goal → 2★；>= 0.7×goal → 1★；否则 0★`。即 1★ 的条件是「达到七成」，不足七成是 **0★**。
  - 0★ 结局真实存在且有专属文案：`ui.csv:280` `DAY_RESULT_VERDICT_0,Still Warming Up · Try Again Tomorrow,还在热身，明天再来`。
- 复现路径 / 推理链: 教学第 6 步是全游戏唯一讲解星级规则的地方（HUD 目标条也只标 100% 刻度与 1.4× 条尾）；新手据此会认为「再差也有 1★ 保底」。当天崩盘（<70%）时结算屏给出 0★「还在热身」，与教学承诺直接矛盾，玩家会认为结算错了而不是自己理解错了。
- 期望 vs 实际: 期望文案为「达到七成可得 1 星，不足则 0 星」之类与代码一致的表述；实际双语文案都把 1★ 描述成 <70% 的结果。
- 修复方向: 改 TUTORIAL_6_BODY 两个语言的行为键（如「达到七成也有 1 星保底，再低则颗粒无收」/ "70% of the goal still earns 1 star — below that, none"），并可顺手在 `_update_info` 的 3★ 披露旁补 0★ 档位。
- 置信度: 高（文案与阈值函数逐行对照，双语文义一致地错）。

### 假设（未定级，供后续代理验证）

- 假设 A（S3，未验证）: HUD 术语药丸的说明只走 `tooltip_text`（`day_shop.gd:2849-2855`），触屏无悬停，「完美0 / x0 / 店铺0/10」在移动端永远无解释。教学第 5 步只覆盖了概念一次。若移动端为首发平台，需要长按或首次浮现式说明。
- 假设 B（S3，未验证）: 真机手柄在教学门控期间能否用十字键把焦点移到覆盖层下方的原料按钮（探针用 grab_focus 模拟成功；Godot 焦点遍历不 respect 鼠标遮挡，理论上可达，但未在实机上确认）。

## 检查过无问题的面

- **首日目标可达性（bot 数据）**: 13 次试玩（9 个新组合）：D1 goal=98，newbie tau=1.40-1.52 / earned 140-162（3★ 线 137，全员 3★ 但余量薄 2-25 币）；D2 tau=1.40-1.47；D3 tau=1.73；D4 tau=1.61；1★ 线 0.7×98=69，即使按新手画像（28% 返工率）也有 2 倍余量，无「第一天就失败」风险。regular D1 tau=1.50 作对照。
- **D5 升级压力曲线**: 无升级 newbie D5（goal=170，brown_sugar_trend）tau=1.25-1.34 → 2★；仅买 comfort:1 → tau=1.25 → 2★；模拟累计购入 comfort2+tip_jar2+shaker1（约 670 币，D1-D4 累计净入 ~645 币量级）→ tau=1.72 → 3★。2★ 仍是「达成目标」，且昨日 ≤1★ 时有 goal_relief 回暖（`day_shop.gd:2514-2516` 封顶 2★ 并在 HUD 透明披露，`ui.csv` DAY_GOAL_RELIEF_BADGE）。属于设计内张力而非缺陷。
- **首个升级价格 vs 首日收入**: 首级 60/70/80（comfort/tip_jar/shaker，`upgrade_catalog.gd:12/20/36`，注释明示「首级维持新手首日可买」）；D1 净入 118-132 → 买 1 件稳、买 2 件看运气，bot `dd=3`（三档均可负担其一）。购买入口在夜间研发室（HUD 药丸 tooltip 明示），余额不足按钮禁用并有 UPGRADE_NOT_ENOUGH 反馈（`upgrade_panel.gd:188/204`）。
- **教学 6 步文案其余部分**: 步骤 1-5 的按钮/快捷键描述与实现一致（数字键 1-9 前缀见 `day_shop.gd:1428`；Q/E 备料 action 存在；教学卡/聚光无重叠——步骤 4 卡片在 (36,330)，P3 修复保持；截图像素检查 mint 边框实测 x426-1248/y64-232 与声明矩形吻合，卡片奶油区 y252-516 不压按钮 y110-164）。门控计数提示「再尝试 %d 次后将跳过此步」的算术（2-_gate_fails）正确。
- **HUD 术语药丸 tooltip（教学跳过后）**: `_update_info` 无条件为 goal/cost/insp/perfect/streak/shop 六个药丸设置 tooltip（`day_shop.gd:2849-2855`），`onboarding_check.gd:92-95` 有断言钉住；语言切换会随缓存失效重译。
- **暂停面板新手可达性**: 教学期间可暂停且面板盖在教学之上（`onboarding_check.gd:55-66` 断言，`pause_panel.gd` z_index 处理）；面板含音量/减动效/触觉/语言/显示与改键/重看教学/回主菜单（二次确认 `SETTINGS_CONFIRM_DAY`），打开即焦点在「继续」，Esc 循环关闭各层（`pause_panel.gd:621-633`）；720p 下 660px 高度面板（y55-715）不出屏。
- **错误操作反馈可理解性**: 返工 `DAY_FEEDBACK_REWORK`「返工 ×N · 仍可售出，但本杯不再计完美」、倒杯 `DAY_FEEDBACK_DISCARDED`「已倒杯 · 原料损耗 N 金币」、≥3 币倒杯二次确认 `DAY_RESET_CONFIRM`、送错 `DAY_FEEDBACK_WRONG` 指名错件「做错了：%s · 已倒杯（−N）——顾客皱着眉再给你一次机会……连击中断」（`_wrong_component_names` 拆解到组件级，`day_shop.gd:2352-2360`）、缺料提示 `DAY_FEEDBACK_INCOMPLETE`/`DAY_PREP_TEA_EMPTY` 均为双语可读文案且 bot 数据中实际触发（reworks 1-8/天）。
- **首个传说发现链路**: D1 灵感 13-20 → 夜间预算装载（`night_lab.gd:99-116`，每次试作 2 点 ≈ 7-10 次尝试）→ 试作命中即 `NIGHT_RECIPE_DISCOVERED` + 音效/触觉/图鉴（`night_lab.gd:971-986`），与 GDD 4.6「1~2 天首个传说配方引导发现」的节奏匹配；重复发现降级为 `NIGHT_RECIPE_REPEAT` 不误导。
- **教学跳过按钮**: 已是次级样式（奶油底+可可描边）且文案来自翻译表（`tutorial_overlay.gd:122-127`，已知项复核无回归）。

## 附：本次 bot 组合明细（新跑 9 组 + 复用同仓前会话样本 4 组）

| 组合 | goal | earned | tau | stars | net | 备注 |
|---|---|---|---|---|---|---|
| newbie D1 s0 | 98 | 140 | 1.43 | 3 | 118 | 3★ 余量 +2.8 币 |
| newbie D2 s0 | 116 | 162 | 1.40 | 3 | 132 | 3★ 线贴边（int 取整 162≥162） |
| newbie D3 s0 | 134 | 232 | 1.73 | 3 | 189 | lunch_rush |
| newbie D4 s0 | 152 | 244 | 1.61 | 3 | 206 | light_drinks |
| newbie D5 s0 | 170 | 227 | 1.34 | 2 | 156 | 无升级首个 2★ 日 |
| newbie D5 s1 | 170 | 223 | 1.31 | 2 | 155 | 同上 |
| newbie D5 s3+comfort1 | 170 | 213 | 1.25 | 2 | 149 | angry=1，serve 93% |
| regular D1 s0 | 98 | 147 | 1.50 | 3 | 125 | 对照 |
| newbie D1 s1-s4 / D5 s2 / D5 prog / D2 prog | — | — | 1.31-2.00 | 2-3 | — | 同仓前会话日志复用 |
