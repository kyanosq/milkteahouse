# P11 速通/跳教学

- 试玩代理：P11「速通/跳教学玩家」（急性子、跳过所有文本、快速多周目视角，专审快节奏交互边角：跳教学后的状态一致性、快速连打、重绑定、场景快速切换、跳过演出）
- 方法：代码走读（day_shop / night_lab / tutorial_overlay / pause_panel / input_prompts / market_tests / menu_catalog / game_state / prep_batch / menu_board_panel）+ 2 个只读运行时探针（`/tmp/p11_probe.gd`、`/tmp/p11_probe2.gd`，日志 `/tmp/p11_probe_run.log`、`/tmp/p11_probe2_run.log`，`GameState.test_mode=true` 全程不落盘）+ 3 项无头检查 + 8 局 skilled bot 快节奏数据。未修改任何 `game/` 文件。
- 引擎：Godot 4.6.3 headless。
- 遵守排除清单：不重复 P1/P10 教学门控不可完成（含覆盖层吞点击与 not running 守卫）、P3 手柄焦点族、P4 文案、P5 定价/结算、P6 回暖日、P7 rush 槽位/trend pin、P8 无尽、P12 对比度；不重复已修项（暂停 z_index、重置确认跨天、简报重看教学）与外部门槛。

## 发现

### F1: 活动顾客离场后单击新队首立即送出——指针流「先看单再送」审查步在快速节奏下消失，单击即吃错单罚（S2）

- 证据:
  - `game/scenes/day_shop/day_shop.gd:2413-2426` — `_remove_customer()` 在活动顾客离场时直接 `active_customer = customers[0]`（不经 `_set_active_customer`，无任何「待审查」标记），随后 `_refresh_all_order_progress()` + `_refresh_all_order_action_hints()` 把新队首的提示切成「交付」。
  - `game/scenes/day_shop/day_shop.gd:2101-2115` — `_on_order_card_pressed()` 的双确认设计：`c == active_customer` 且 `cup_sealed` → **单击直接 `_on_deliver(c)`**；非活动卡才走一次非破坏性「看单」步（注释原文 "The focused/active card is already reviewed, so confirm it immediately."——该前提是「这杯就是为活动卡做的」）。
  - 探针（`/tmp/p11_probe2_run.log` B 系列）：3 顾客在场，为活动顾客 A 封杯（`cup_sealed=true`）→ `_remove_customer(A)`（耐心耗尽离场的核心路径）→ `active` 自动变为 B；**单击** B：`B1 single_click_delivered=true`，B 耐心 32.0 → 20.8（×0.65 错单罚），连击清零（`B4 streak_reset=true`），杯子直接弃置。对照组：持杯点击**非活动**卡 C 一次只看单不送（`B5/B6`），第二次点击才送（`B7`）——审查步只在「手动切单」时存在。
  - skilled bot（快节奏）D3 四样本怒走 0、日 1 无离场，说明速通本身不触发；触发者恰是被耐心逼到墙角的中速玩家在节奏被打断的一瞬。
- 复现路径 / 推理链: 为队首 A 封杯（摇杯动画期间 A 耐心归零离场）→ 活动权自动落到新队首 B，订单提示区/卡提示即时切换 → 玩家按肌肉记忆点 B 的卡（上一毫秒它还标着「看单」）→ 单击=立即交付 → 配方几乎必不匹配 → 耐心 ×0.65、连击归零、杯料损耗，三次打击一次点击全齐。
- 期望 vs 实际: 期望 R3 修复确立的「指针切目标先看单再送」对所有目标切换成立；实际离场晋升这条切换路径完全绕过审查步——恰是玩家最慌乱、最依赖防护的时刻。缓解项（如实说明）：晋升后 B 卡提示与配方进度徽章（"!"）确实更新为「交付/不匹配」，信息在场，但单击即罚的交互不变。
- 修复方向: (a) 离场晋升时若 `cup_sealed`，给新队首挂一次性「需看单」标记（下次点击仅激活/看单，再点才交付），与手动切单对齐；(b) 或交付判定前若杯配方与新目标显著不符，首次点击给一次可撤销确认（复用倒杯二次确认模式）；(c) 至少在晋升瞬间 `_flash` 提示「上一单的杯子还在手上」。
- 置信度: 高（代码路径 + 运行时探针双向证实；唯一裁量是严重度——若团队认为「活动卡=单击交付」语义应无条件成立，可降 S3）。

### F2: 改键冲突守卫只护 Q/E——数字键 1-9 / Enter 可被合法绑走，静默废掉订单/原料快捷键与焦点激活（R8 同类残余，S3）

- 证据:
  - `game/autoload/input_prompts.gd:76-85` — `conflict_for()` 只检查三个可改绑动作互撞 + `FIXED_KEYS`（Q/E，注释明确这是 R8 修复「先到先得消费静默废掉动作」）。不检查数字键、Enter、Tab。
  - `game/scenes/day_shop/day_shop.gd:277-314` — `_input()` 的动作分支（`prep_tea`/`prep_pearl`/`game_shake`/`staff_interact`）全部排在裸数字键快捷分支（`event.keycode - KEY_1`，301-314 行）之前并 `set_input_as_handled()`。
  - 探针（`/tmp/p11_probe_run.log` C 系列）：`conflict_for("game_shake", KEY_1)` / `("staff_interact", KEY_8)` / `("game_shake", KEY_ENTER)` 全部返回 `""`（放行），`("game_shake", KEY_Q)` 正确返回 `prep_tea`（守卫本体有效）。实际绑走验证：改绑前按 `1` 正常选中茶基（`C4=true`）；把 `game_shake` 改绑到 `KEY_1` 后同一按键触发摇杯未完成闪现（`C5 cup_base==null`、`C6` 反馈文案出现）——数字快捷键被彻底遮蔽，且**无任何冲突提示**。
  - 连带面：`game_shake`→Enter 时，`_input` 在 GUI 之前消费 Enter（`set_input_as_handled`），所有按钮的键盘激活（ui_accept）一并失效；`game_pause`→数字键则每次选料都会弹暂停。`game_state.gd:597-614` 的加载端归一化同样只护 Q/E 与互撞，改绑产物可长期驻留存档。
- 复现路径 / 推理链: 暂停 → 显示设置 → 改键 → 把「摇杯」从 Space 改到 1（速通玩家把主操作挪到左手区的自然选择，守卫放行、提示「已改键」）→ 回到店里按 1 选茶基/交付 → 变成摇杯音效+「配方不完整」闪现，订单快捷键 1-3 与情境原料 1-8 全部失灵，玩家只当游戏坏了。
- 期望 vs 实际: 期望 R8 守卫的立项理由（防止先到先得消费静默废动作）对所有硬编码输入成立；实际同一类静默失效对数字快捷键（日间两大快捷系统）与 Enter（全部键盘 UI 激活）仍然敞开。
- 修复方向: `conflict_for()` 增补保留键集：`KEY_1..KEY_9`（day_shop 裸快捷键）、`KEY_ENTER/KEY_KP_ENTER/KEY_SPACE/KEY_TAB`（ui_accept/ui_focus_next 等价键，Space 本就是 shake 默认故只需护另两个）；`_normalize_key_bindings` 同步；`release_settings_check` 补断言。
- 置信度: 高（守卫源码 + 运行时遮蔽复现）；严重度 S3——需要玩家主动改绑到这些键，但受害者恰是本代理画像的重绑速通玩家。

### F3: 教学重看不重置门控状态——首轮被自动放行过（键鼠玩家必经路径）后，重看教学两步练习永久免做（S3）

- 证据:
  - `game/ui/tutorial_overlay.gd:138-143` — `start()` 只重置 `_replay`/`_step`，**不重置 `_gate_fails` 与 `_gate_bypassed`**；二者只在 `_advance()` 通过门控时清零（243-256 行），`_finish()`（跳过出口）也不清。
  - 探针（`/tmp/p11_probe_run.log` A 系列）：首轮教学在门控步连点两次 `_advance` → `_gate_bypassed=true` → `_finish()` → `_show_tutorial(true)` 重看 → `A6 replay_gate_bypassed_persists=true`，门控步 `_step_completed()` 未经任何练习直接返回 true（`A8=true`），且 `_render_step` 会常驻追加「练习步骤已跳过」附注（152-153 行）。
  - 次级残留（代码推因，未单测）：首轮只失败 1 次（`_gate_fails==1`）就点「跳过」的玩家，重看时在门控步再点一次「下一步」即 `_gate_fails>=2` 直接放行——重看的教学只剩 2 次中的 1 次尝试机会。
  - 叠加 P1/P10 的已知事实（键鼠玩家门控必然失败 2 次被放行）：**全体键鼠/触摸玩家的第一次教学都以 `_gate_bypassed=true` 收场**，于是暂停菜单里唯一的补课入口「重看教学」对所有需要补课的人都是免练习版——补课功能系统性空转（此处只报重置缺失这一状态一致性缺陷，门控本身不可完成属 P1/P10 不赘述）。
  - 相邻小项（同探针 D5）：首教学进行中打开暂停再点「重看教学」，`_show_tutorial` 因覆盖层已可见而早退（`day_shop.gd:697-699`），按钮表现为第二个「继续」——无害但语义为空。
- 复现路径 / 推理链: 首日键鼠教学 → 门控步连点两次被自动放行 → 跳过/完成 → 任意日暂停 → 重看教学 → 两步练习步直接点「下一步」通过，全程零操作，附注「（练习步骤已跳过……）」常驻。
- 期望 vs 实际: 期望重看教学 = 完整重走六步含两次动手练习；实际 `start()` 的半重置让重看退化为纯阅读，且把首轮的失败计数也带进来。
- 修复方向: `start()` 中补 `_gate_fails = 0`、`_gate_bypassed = false`（重看场景下 bypassed 必须归零才可能补课）；顺带在 `_show_tutorial` 对「重看但已可见」给出与「继续」不同的反馈或干脆禁用该按钮。
- 置信度: 高（`_gate_bypassed` 持久化与免练习通过均为探针实证；`_gate_fails` 残留为逐行代码推因，机制同源）。

### F4: 菜单板每次点击都做一次全量原子落盘——快速策展连点=同步磁盘风暴，与日间设置已修的防抖理由自相矛盾（S3）

- 证据:
  - `game/autoload/menu_catalog.gd:150-169`（`set_featured`，`persist` 默认 true，每次上/下架 `GameState.save_game()`）、`:238-246`（`set_item_price` 同）、`:433-448`（`install_dark_candidate` 同）、`:453-459`（`remove_dark_slot` 同）；菜单板面板四处调用全部走默认值（`game/ui/menu_board_panel.gd:407-453`）。
  - `game/autoload/game_state.gd:130-180` — 每次 `save_game()` = 临时文件写 + 回读校验 + 主档备份复制 + 回读校验 + 两次 rename（失败路径还含删除重试）。即一次点击 ≥2 次写盘 + 2 次读校验 + 2 次改名。
  - 对照组：`game/ui/pause_panel.gd:337-345` 明确注释「滑条拖动每 tick 都触发一次完整落盘会在移动端造成卡顿。内存立即生效，磁盘写入防抖合并」，日间设置因此有 0.6s 代际防抖——菜单板没有。
  - 快速策展的真实点击密度：主推 3 槽切换 + 三档价点调整 + 黑暗菜单换槽，连点 6-10 次是常态（`_toggle_item` 后的 deferred `_refresh` 不拦截下一次点击，模型层即时生效，这正是连点可行的原因）。
- 复现路径 / 推理链: 夜间 → 菜单板 → 连续调整主推与价点（每次点击同步全量落盘）→ 桌面可见偶发卡顿、移动端主线程抖动；夜间 `_on_try` 每次试做也各存一次（`night_lab.gd:1067`，属崩溃安全设计），叠加策展写盘使夜间成为全程 I/O 最密的场景。
- 期望 vs 实际: 期望与设置面板同一防抖策略（或面板关闭时一次性 persist）；实际菜单板逐点击全量原子写，移动端体验风险与已修复的设置项完全同源。
- 修复方向: 面板动作改 `persist=false` + `menu_changed` 后统一防抖（复用 pause_panel 的 generation 计数法），面板 `hide_panel()`/场景切换时强制落盘一次。
- 置信度: 高（机制与 I/O 计数逐行可数）；性能影响量级未实测（headless 无磁盘抖动可观测），故定 S3 而非 S2。

## 检查过无问题的面

- **教学中暂停 → 跳教学 → 恢复的时钟（探针 D1-D6 全绿）**：`_toggle_pause` 会用 `running=false` 覆盖 `_resume_after_pause`（`day_shop.gd:729`），但 `_on_tutorial_finished` 不依赖该标志、直接按 `time_left>0 && !overlay.visible` 重算（718-720），全程暂停/恢复/重看循环后时钟严格恢复；教学期间 `get_tree().paused` 确实生效（D2），暂停中恢复不偷跑一帧（D3）。
- **跳过教学瞬间的 cup/tea_batch 状态**：所有制作入口被 `_on_ingredient`/`_on_shake`/`_input` 的 `running`/`cup_sealed` 守卫挡住，任何步骤点「跳过」都留下空杯、未启动的批次、原样的糖度档；`_finish` 只写 `tutorial_completed` + 一次存档，重看路径不重复标记不重复改档（`tutorial_overlay.gd:259-264`）。
- **教学中 spawn 的顾客**：`_show_tutorial` 冻结 `running` → `_process` 早退，耐心/生成计时全部停摆，教学期间不会有顾客掉耐心离场；跳过后该顾客从满耐心正常开始，无遗留、无白送（`day_shop.gd:195-197, 697-706`）。
- **结算 → 夜间 → 开店的重入幂等（探针 F0-F4 全绿）**：`_end_day` 单发（`_process` 顶部 `not running` 早退，2493 行先置 false）；`_on_sleep` 连点两次结算字典逐字节相等、灵感不重复入账（`_bank_unspent_performance` 先清记录的幂等设计 + `MarketTests.advance` 的 `has_settlement` 缓存，`market_tests.gd:20-66`）；`_next_day` 双击守卫 `_next_day_started` 生效（day 3→4 不跳 5）；`record_campaign_day` 按 `recorded_days` 去重；日中退出重进走 `day_open` 快照回滚（`game_state.gd:344-353`），`_start_day` 的重标记检查（2434-2435）保证重开当天不重拍快照——重玩当天无法重复赚取已入账收入。
- **MarketTests 并发边界**：评分由 `name|quality|day|stage` 哈希决定（`deterministic_score`），退出重进不可刷新；`advance()` 全程同步无 await，无双入中间态；加载端 `_normalize_market_settlement` 丢弃非当夜/超界数据。
- **快速连打交付其余路径**：对刚被服务/离场（queue_free 中）订单卡的重复点击被 `_set_active_customer` 的 `customers.has(c)` 挡住；错单交付不移除顾客（无双移除）；团票二连杯交付后立刻再点命中 `not cup_sealed` 守卫只闪提示（探针 B8-B10）；数字键 1-3 在封杯态映射订单卡、且 `not running` 在结算/简报/教学/暂停四态全部短路（`day_shop.gd:266-314`）。
- **Q/E 备料连打**：`PrepBatchModel.collect()` 在 brewing 态返回空（`prep_batch.gd:59-81`），煮制中狂按 Q/E 不产生空收集/双份库存；变质批次收集后第二击落回「开始」分支。
- **日结算界面连点「下一步」**：单步面板无逐步信息可跳；双击=同帧两次 `change_scene_to_file` 同目标，Godot 去重无副作用；结算 overlay 期间 `game_pause` 被 `_input` 的 `not overlay.visible` 拦截，暂停态不会叠在结算上偷输入（269-274 行）。
- **快速 ESC 开关暂停面板的输入泄漏**：树暂停即停 `day_shop._input`/3D 舞台事件；改键等待态下 `PausePanel._input` 先 `set_input_as_handled` 再处理（ESC=取消、修饰键拒绝），任意键不会漏到底层场景；夜间 `game_pause` 在结算 overlay 上被显式吞掉（`night_lab.gd:139-140,143`）。
- **菜单板快速开关面板**：模型层 `set_featured` 每次调用独立执行「最少保留一款」守卫，连点三次下架最终剩 1 款（探针 E0）；`_refresh` 用即时 `free()` + deferred 调度，快速「点两下→立刻关面板」后卡片重建正常、`_restore_focus` 有可见性检查（`menu_board_panel.gd:456-464`）；动作先改模型再延迟刷新，连点间状态累积正确。
- **无头检查**：`onboarding_check` passed（tutorial=true）、`release_settings_check` passed（rebind/conflict_guard/reset_preserves 全 true，Q/E 守卫本体有效）、`input_check` passed（actions=5 families=4 prep_shoulders=true …）。
- **skilled bot 快节奏经济稳定性**：D1 四样本全同（earned 150 / goal 98 / 3★ / tau 1.53 / 服务 11 杯 100% / 怒走 0）；D3（lunch_rush）四样本 earned 279-300、tau 2.08-2.24、返工 ≤1、怒走 0——速通节奏下收入、库存消耗（stock 22-55）、耐心系统均无异常跳变或资源错账。
- **改键守卫本体与加载端归一化**：Q/E 双向防护（改绑到 Q/E 被拒 + 存档含 Q/E 冲突时整组回默认，`input_prompts.gd:80-84`、`game_state.gd:604-613`）与 `release_settings_check` 断言一致（F2 只针对未覆盖的保留键集）。

## 附：探针与数据

- 探针：`/tmp/p11_probe.gd`（A 教学重看门控泄漏 / C 改键遮蔽 / E 菜单板连点）、`/tmp/p11_probe2.gd`（B 交付单击即罚 / D 教学暂停时钟 / F 结算重入幂等）；运行日志 `/tmp/p11_probe_run.log`、`/tmp/p11_probe2_run.log`。
- 无头检查日志：`/tmp/p11_onboarding.log`、`/tmp/p11_settings.log`、`/tmp/p11_input.log`。
- bot 日志：`/tmp/p11_bot_d1_s0..3.log`、`/tmp/p11_bot_d3_s0..3.log`。
