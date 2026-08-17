# P12 无障碍

视角：动效敏感（前庭/光敏）、听力受限、低视力（需大字/高对比）、色弱。审查面：减弱动态、音量独立控制、触觉开关、色盲冗余、文字对比度、最小字号。引擎 Godot 4.6.3；对比度按 WCAG 2.x 相对亮度公式计算，截图实测用 PIL 采样（`tools/.venv`）。

复现环境：`SHOT_DEMO=1 SHOT_DAY=9`（日间，/tmp/p12_day9.png）、`SHOT_LOCALE=en SHOT_NIGHT=1`（夜间，/tmp/p12_night_en.png）、`SHOT_TUTORIAL=1`（教学，/tmp/p12_tutorial.png），均 1280x720；无头跑 `release_settings_check.tscn`、`input_check.tscn` 双绿。

## 发现（证据含对比度计算/复现/期望vs实际/修复方向/置信度，S0-S3）

### F1 (S1) 耐心秒数标签三档色文字对比全面低于 WCAG AA

- 证据：`game/scenes/day_shop/day_shop.gd:24` `PATIENCE_BAND_COLORS := [E5484D, D99A43, 27B9A7]`，`:250` 直接把档位色设为 `patience_label` 的 font_color，字号 16px（`:1782`），无描边。
- 计算（前景/卡底 F8F6EB≈FFF8ED）：红 E5484D = 3.71:1，琥珀 D99A43 = 2.30:1，薄荷 27B9A7 = 2.32:1。16px 常规字属"正常文字"，AA 需 4.5:1，三档全不达标；连大字下限 3:1 也只有红档勉强过。
- 截图实测：day9 订单卡秒数区（(140,116)-(225,142)）渲染笔画最深 0.1% 对卡底 2.84:1（抗锯齿混色），印证。
- 期望 vs 实际：秒数倒计时是耐心紧迫度的首要视觉通道（掉档音效对听障玩家无效），期望 ≥4.5:1；实际薄荷/琥珀档不到 2.4:1，弱光/低视力下接近不可读。
- 修复方向：数字保持 COCOA（14.74:1），档位改用前置色点/图标 + 加深档位色（如深红 #B3261E、深琥珀 #8A5A00、深薄荷 #0E7A6C 这类 ≥4.5:1 的变体）；或给秒数字加 2px 深描边。
- 置信度：高（代码+公式+实测三重）。

### F2 (S1) 教学聚光灯不还原亮度：被讲解的 HUD 文字对比从 ~11:1 掉到 ~3.6:1，且焦点描边 <3:1

- 证据：`game/ui/tutorial_overlay.gd:60` 整屏 ColorRect `Color(0.06,0.055,0.07,0.58)`；`:77` 聚焦框仅是叠在暗层之上的 `bg_color = 白 0.04` + 4px 薄荷描边（`:79-82`）——子节点画在 ColorRect 填充之上，只会再提亮 4%，**不会把聚焦区打回原亮度**。
- 计算+实测：可可为文字在暗层下 = 3.60:1（tutorial 截图外区实测 3.56:1；正常日间同 HUD 区实测 11.21:1）；聚焦框内部实测最深笔画仅 2.36:1（混入目标条区域）。薄荷描边 (89,186,174) 对暗化背景 (114,111,109) = 2.15:1，低于 WCAG 1.4.11 图形对象 3:1。
- 复现：新档第 1 天自动教学（或暂停菜单重看教学），第 1 步聚焦左上"今日目标"行——低视力视角下要看清"游戏正在讲什么"反而比平时更费眼，与教学目的相悖。
- 期望 vs 实际：期望聚光灯让焦点区保持原始对比（真正"开洞"）；实际全屏一律压暗 58%，焦点区只多 4% 白。
- 修复方向：改成真开洞（上/下两块 ColorRect 夹出矩形 + 四边补条），或暗层降到 ~0.30 并把描边换 COCOA/加宽到 5px 以上；顺带 `:104` 进度标签 MINT 15px on CREAM = 2.32:1 也应换 COCOA。
- 置信度：高。

### F3 (S2) 减弱动态是"创建时"门控：日内开启后存量循环动画不停止

- 证据：所有门控都在动画创建点读一次 `GameState.reduced_motion()`。`game/ui/shop_stage.gd:526-529` 店员 bob 为无限 loop 且 tween 引用未保存、无 kill 路径；`:609-629` 顾客呼吸/张望/小跳三个 loop 同理（顾客离场才随节点销毁）。`set_staff_state`（`:538`）只处理位移动画，不动 bob loop。
- 复现：进入某日（已有顾客+店员待机）→ 暂停 → 设置勾选"减弱动态" → 继续 → 已在场的顾客继续呼吸/摆头/小跳、店员继续上下浮动，直到他们自然离场/场景重建；同日后新来的顾客则是静止的——同屏两种行为并存。
- 期望 vs 实际：开关语义应是"从此刻起减少动态"；实际只对"此后创建"的动画生效。对前庭敏感玩家，最刺眼的恰恰是持续性的循环浮动。
- 修复方向：toggle 时统一 kill 存量 loop（把 loop tween 存到节点 meta，或用一个待机组扫描 `Node.get_meta("idle_loop_tween")` 后 kill）；顾客/店员 loop 改为每帧检查也可但成本高。
- 置信度：高（代码路径明确；未做窗口模式动态复现，靠推演+grep 全量核对）。

### F4 (S2) 结算面板 accent 色数字/摘要低于大字 3:1 与正常 4.5:1

- 证据：`game/ui/night_settlement_panel.gd:141-150` 分数标签 22px、阶段标签 13px 用 outcome accent；`:49-51` 摘要 16px 用 MINT。
- 计算（卡底 = MINT 7% 混 CREAM ≈ (240,244,232)）：GOLD 2.17:1、MINT 2.19:1、CORAL 2.63:1（22px 非粗体按大字 3:1 也不达）；摘要 MINT on CREAM 2.32:1。PLUM 11.64、COCOA 14.74 都很好，问题只在 accent 直接当文字色。
- 期望 vs 实际：分数（市场分）与"N 款完成检验"摘要是玩家要读的数字/结论；期望 ≥3:1（大字）；实际最低 2.17:1。outcome 类别本身有文字冗余（`:167` outcome_label 写明热销/招牌/常规/失败），颜色不是唯一通道，故severity S2 而非 S1。
- 修复方向：分数/摘要文字用 COCOA，accent 只用于卡描边与图标；或加深 accent 变体。
- 置信度：高。

### F5 (S2) 菜单板/图鉴 13px 级小字多处对比不足

- 证据与计算：
  - `game/ui/menu_board_panel.gd:285` `event_fit` GOLD on 可用卡底 (255,251,243) = 2.35:1，13px；`:258` 价格说明 COCOA 0.62 = 4.44:1，13px（差 0.06 到线）；`:372,393` 锁定暗卡 body 白 0.78 混底后 3.77:1，13-14px。
  - `game/ui/recipe_book_panel.gd:262,284` 搭配等级名 16px accent：CORAL 2.79 / MINT 2.32 / GOLD 2.30 / 冲突紫 8C67B5 4.21。
  - `game/ui/tutorial_overlay.gd:104` 教学进度 MINT 15px 2.32:1（并入 F2 修复亦可）。
- 期望 vs 实际：这些都是带信息量的文字（事件加成、价格、锁定原因、搭配等级、教学进度），期望 ≥4.5:1；实际大面积 2.2-2.4:1。
- 修复方向：等级/事件文字用 COCOA + 小色标；GOLD/MINT/CORAL 保留在描边、图标、进度条等非文字载体上（该用法无碍）。
- 置信度：高。

### F6 (S2) 无字号/UI 缩放选项；最小字号 10-12px 且部分无 tooltip 兜底

- 证据：全仓 grep 无 `ui_scale/font_scale/text_size/字号` 任何设置；设置面板（`game/ui/pause_panel.gd:61-153`）只有音量×2、减弱动态、触觉、语言、显示。最小字号：`day_shop.gd:803` hud_cost 10px；`recipe_book_panel.gd:290,333` 图鉴细节 11px（搭配格 11px 无 tooltip，`menu_board_panel` 锁定暗卡 13px 正文；12px 有 `day_shop.gd:375` 契约药丸、`:527` 店员状态）。工程 1280x720 canvas_items stretch（`project.godot:41-44`），720p 下即物理 10-12px。
- 期望 vs 实际：低视力玩家通常依赖系统/游戏内字号缩放；本作没有任何一档，且 10px 成本注脚、11px 图鉴线索（等级分数/熟练度经验）信息只能硬读。熟练度那格有 tooltip（`:334`），搭配格（`:290`）没有。
- 修复方向：设置加"文字大小"档（对 SafeFrame 内根控件做 scale 或主题 font_size 乘数，两档即可：100%/125%）；给 11px 搭配分数补 tooltip；hud_cost 10px 至少提到 12px。
- 置信度：高（无救济选项是事实；具体字号阈值属工程判断）。

### F7 (S3) 耐心琥珀档与薄荷档亮度几乎相同，红绿色弱难分；0.4 档线无刻度

- 证据：D99A43 亮度 0.3827 vs 27B9A7 0.3792——色相是唯一差别；红绿 CVD 下两档趋同。已有冗余：秒数递减、条长连续量、掉档音效（`day_shop.gd:236-240`）+红档触觉、precision 路线 0.7 档线（`:1794-1804`）。
- 期望 vs 实际：小费三档（>0.7 满 / >0.4 低 / 无）是经济规则；琥珀/红边界（0.4）在普通路线没有任何非颜色标记，色弱玩家只能靠心算秒数。
- 修复方向：非 precision 路线也画 0.7/0.4 两根细档线（已有 patience_threshold 实现可复用）；或在卡角加"满小费/低小费/无小费"微型文字。因已有秒数+条长冗余，定 S3。
- 置信度：中高。

### F8 (S3) 零散小项

- `night_settlement_panel.gd:213` 空状态文案 COCOA 0.62 = 4.40:1（20px，差 0.06 到 4.5）。
- `flavor_radar.gd:30` 网格白 0.22 on 靛 = 2.03:1（装饰性参考线，可豁免，但若当作读数辅助建议提到 0.35+）；`:58` 薄荷多边形填充 2.24:1——雷达数值在右侧反馈气泡有完整文字冗余（FEEDBACK_HIGH/LOW 文案），故仅提示。
- `ui/customer_avatar.gd:52-59` 待机 bob/sway loop 无 reduced_motion 门控——当前**全仓无引用（死代码）**，一旦复用会直接违反减弱动态。建议加门控或删除。

## 检查过无问题的面

- **reduced_motion 作用面完整性**（grep 全量核对）：金币飞行 `_fly_coin`（day_shop:2927）、连击药丸脉冲 `_pulse_streak_pill`（:2950）、HUD 位移震 punch `_punch`（:2964，含 2321/2353 调用点）、情境面板淡入淡出（:1405，关时直接置可见+alpha=1）、杯体晃动/出杯 `cup_rig.gd:221,238`（并复位 rotation/scale）、店招标记脉冲 `pulse_route_sign`（shop_stage:186，含恢复基准比例）、道具选中抬升（:478）/点击弹跳（:488）、店员状态（:538）、顾客到达（:601 直接就位）/离开（:636 直接 queue_free）/待机 loop 创建（:601 提前 return）、结算卡入场 `night_settlement_panel.gd:232`。镜头无任何晃动代码；无粒子、无场景 AnimationPlayer；sfx.gd 的 7 处 tween 全是音频淡入淡出/闪避（非视觉）。`_flash` 反馈淡出未门控但纯透明度渐隐、无位移，符合惯例。
- **音量独立控制**：music/sfx 两条独立滑杆（pause_panel:80-91），拖动即写 settings 并 `Sfx.apply_settings()`，音量 ≤0.0001 时直接 `AudioServer.set_bus_mute`（sfx.gd:102）；日间与主菜单共用同一 PausePanel，入口一致。默认 0.75/0.55，存档 load 时 clamp（game_state:331-332）。
- **触觉开关独立性**：`Haptics.play` 仅检查 `GameState.haptics_enabled()`（haptics.gd:18），与任何音量无关；静音不影响触觉、关触觉不影响声音。开启时有 confirm 预览脉冲（pause_panel:478-482）。无头 `input_check.tscn` passed（haptics=true），`release_settings_check.tscn` passed（haptics_toggle=true, reset_preserves=true——重置进度保留设置）。
- **持久化一致性**：settings 整体入档（game_state:112），load 恢复 reduced_motion/haptics（:333-334）；`save_integrity`/`onboarding_check` 均含 reduced_motion 断言。减弱动态入口在主菜单设置与日间暂停两处同一面板，无场景遗漏。
- **夜间深底文字**：雷达面板（INDIGO 25324A 95%）轴标签白 0.85 实测 8.49:1 通过；暗板卡名称 CREAM 14.47:1、状态 C6A7E2 7.29:1、GOLD 元信息 6.29:1 均达标（仅 F5 所列锁定卡 body 例外）。夜间主体文字全在 CREAM 面板上（COCOA 14.74 / PLUM 11.64 / 次级 COCOA 0.66-0.76 = 5.01-6.86 全过 4.5）。
- **音频无字幕风险**：关键规则均有文字冗余——耐心掉档有秒数标签+离场闪现文本；顾客到达有订单卡出现；事件有 HUD 药丸文本+简报面板；备料/出错反馈 `_flash` 文本自带语义（颜色仅装饰，26px+6px 深描边可读）；未发现"仅靠声音传达的关键信息"。
- **色盲冗余（其他）**：结算 outcome 有类别文字；顾客类型（评论家/网红/组合）有专属 3D 模型剪影+卡片徽章文字，不靠衣服色；订单进度有"N/M"数字+图标槽；图鉴等级有等级名文字+tooltip；糖泵有白→珊瑚梯度+文字标签。
- **AppTheme 基线**：COCOA on CREAM 14.74:1、COCOA on CORAL 按钮 5.29:1、按钮焦点环已用 COCOA 4px（旧薄荷环问题已修）、禁用态文字约 3.4:1（禁用豁免）。进度条薄荷填充对深底满足非文字 3:1。
