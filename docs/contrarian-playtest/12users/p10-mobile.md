# P10 移动/触屏

日期 2026-08-17 · 方法：headless `mobile_render_check`（预算）与 `input_check`（传感器/安全区/手势）双通过；窗口模式截图 4 张（960x600 demo/gesture/menu、1280x720 gesture、另加 844x390 手机逻辑尺寸 gesture）+ tools/.venv PIL 逐像素量取按钮/罐体几何；教学门控点击拦截用 /tmp 临时 SceneTree 脚本经 `Input.parse_input_event` 注入真实点击做正反对照实验（game/ 未改动）。

## 发现（证据/复现/期望vs实际/修复方向/置信度，S0-S3）

### 1.【S1】手机上所有触控目标被画布等比缩到 ~29pt，全面低于 44pt/48dp 触控标准
- 证据：`game/project.godot` 作者分辨率 1280x720 + `canvas_items`/`expand`；SafeFrame 只在可见区 ≥1280x720 时保持 1.0（`ui/safe_frame.gd:47`），因此 UI 尺寸完全由窗口逻辑高度决定：iPhone 级横屏 844x390pt → content scale 0.542，Android 级 915x412dp → 0.572。作者 54px 高的情境原料按钮（`scenes/day_shop/day_shop.gd:1429`）、196x54 重置（:425）、300x58 摇茶（:1367）、96x52 暂停（:381）在手机上变成 29/31/28pt 高。
- 复现：`--resolution 844x390` + `SHOT_MOBILE_GESTURE=1 SHOT_DAY=12`，PIL 实测情境面板区带 65px（含标题行）→ 按钮高 ≈29px；对照 960x600 站台实测按钮 139x41 窗口像素（=185x55 画素描边，41 已低于 44），1280x720 时 54px 1:1。
- 期望vs实际：期望主操作 ≥44pt（Apple HIG）/48dp（Android）；实际约 29-31pt，只有标准的 2/3。相邻按钮间隙 8 画素描边（844x390 下 ≈4.3pt）也在最小间距之下，误触直接落进邻钮。
- 修复方向：检测 `OS.has_feature("mobile")` 且触屏为主输入时，给 SafeFrame 设移动最小缩放（如 ≥0.68）并把原料网格改 2 列大按钮；或提供手机专用 720p 竖排变体布局（顶 HUD/中 3D/底大按钮）。平板（≥820pt 高）不受影响，可维持现状。
- 置信度：高（双分辨率 + 手机尺寸实测，几何推导封闭）。

### 2.【S1】教学门控练习步骤在触屏（和鼠标）下根本无法完成——遮罩吞掉全部点击
- 证据：`ui/tutorial_overlay.gd:62` 根 ColorRect `mouse_filter = MOUSE_FILTER_STOP` 全屏拦截；门控步骤 3「选茶基」/4「封杯」（:233-234，`day_shop.gd:709-715` progress_provider）要求真实选料/封杯。同时 `_show_tutorial` 置 `running=false`，`day_shop._input` 在 :275 提前 return，键盘 1-9 捷径也被禁。
- 复现（实证）：窗口模式 1280x720 注入真实鼠标点击情境按钮中心——对照组（先 `_finish()` 关教学）：`cup_base=black_tea ✓`；实验组（教学显示中，step=2）：`cup_base=null`，同一按钮同一坐标点击被吞。onboarding_check 全程直调 `shop._on_base()`（tests/onboarding_check.gd:39），从未穿过 GUI，故回归测不出。
- 期望vs实际：期望「学过就要做一遍」的门控在触屏走通；实际触屏玩家只能连点两次「下一步」触发防软锁自动放行（TUTORIAL_GATE_RELEASED_NOTE「练习步骤已跳过」），第一天教学的核心练习设计对所有指针输入失效；唯一可能走通的是手柄焦点导航（焦点不受 mouse_filter 拦截）。
- 修复方向：门控步骤激活时把遮罩 mouse_filter 切为 IGNORE（聚光灯/卡片已各自 STOP），或门控期间把点击透传到当前步骤高亮区；回归里补一条「GUI 级点击能完成门控」的断言。
- 置信度：高（正反对照实验直接复现）。

### 3.【S2】Haptics 六类语义脉冲在真机上分别退化为「无声」与「同一种」
- 证据：`export_presets.cfg` preset.2（Android）options 段没有任何 `permissions/*` 条目；Godot 官方文档明确 `Input.vibrate_handheld` 在 Android 需在导出预设勾选 VIBRATE 权限，否则无效果（部分版本甚至崩溃，godotengine/godot#103496）。`autoload/haptics.gd:43` 是唯一落点 `Input.vibrate_handheld(duration, amplitude)`——iOS 后端忽略 duration/amplitude（AudioServicesPlaySystemSound 单一固定脉冲），精心调的 18-148ms/0.18-0.92 六档（haptics.gd:4-11）在 iOS 全部变成同一下。
- 复现：审查导出配置即可（真机门槛外部）；headless 下 `input_check` haptics=true 只验证了测试桩路径。
- 期望vs实际：期望 tap/shake/confirm/success/warning/discover 有可辨差异（warning 112ms/0.92 vs tap 18ms/0.18）；实际 Android 无权限=全静默，iOS=无差异。「触觉关闭」本身有复选框视觉反馈且开时播 confirm 脉冲（pause_panel.gd:478-482），但玩家无从得知平台层已经把整层触觉架空。
- 修复方向：Android 预设勾选 Vibrate（或自定义 manifest 注入 `<uses-permission android:name="android.permission.VIBRATE"/>`）；iOS 差异化改用节奏型脉冲（多次 vibrate_handheld 间隔编码语义档），并在设置页加「触觉强度」让玩家可感知开关确实生效。
- 置信度：Android 部分高（官方文档+预设缺项）；iOS 退化中（引擎后端行为，未真机验证）。

### 4.【S2】触屏玩家看到成套键盘泄漏：按钮编号、教学文案与提示键名
- 证据：`day_shop.gd:1428` 情境按钮文案只分支 gamepad/其他，触屏上显示「1  阿萨姆」；`ui.csv:331` TUTORIAL_3_HINT「按钮前的数字对应键盘 1–9」原样教给无键盘玩家；`tutorial_overlay.gd:169` 第 4 步非手柄提示注入 `shake_hint()`=「空格」（TUTORIAL_SHAKE_HINT「…也可按空格键」）；暂停面板 pointer 分支 `SETTINGS_CONTROLS_DAY_KEYBOARD` 拼 Q/E/空格/F/Esc（pause_panel.gd:520-525）。对照：摇茶文案已有正确的 mobile 分支（`_shake_button_text` 检查 `OS.has_feature("mobile")`，DAY_SHAKE_BUTTON_MOBILE「点击 / 摇匀」），证明泄漏是不一致而非设计。
- 复现：SHOT_MOBILE_GESTURE 截图中央提示「摇晃设备或点击 · 摇匀 0/5」正确；门控实验输出 `button=1  阿萨姆`（pointer 模式）证明编号仍在；教学第 3/4 步文案见 ui.csv:331/334。
- 期望vs实际：期望触屏提示与桌面一致地做 mobile 分支；实际约一半提示面照抄键鼠方案。
- 修复方向：给 InputPrompts 增加 touch 方案（或 `OS.has_feature("mobile")` + 非 gamepad 即 touch 文案），编号前缀、TUTORIAL_3/4_HINT、SETTINGS_CONTROLS_*_KEYBOARD 全部走分支。
- 置信度：高（代码+文案+截图三证）。

### 5.【S3】小料罐 8 罐 0.24 间距 + 0.11 半径拾取圆柱：手机上约 28pt 目标、~1pt 间隙
- 证据：`ui/shop_stage.gd:288`（`-0.95 + i*0.24`，后期 8 罐）与 :320（CylinderShape3D radius=0.11）；投影后罐心距 ≈57.7 画素描边、圆柱直径 ≈53 描边、边隙 ≈4.8 描边。960x600 下实测罐带在 y=404 连成 442px 无缝色带（相邻罐视觉相接）；乘手机 scale 0.54 → 目标 ~29pt、间隙 ~2.6pt，低于手指定位精度（±10-15 逻辑像素）。
- 复现：SHOT_DAY=12 截图数罐 8 个；PIL 沿罐行扫描无可分割间隙。中段罐点击落在邻罐圆柱内的概率显著。
- 期望vs实际：期望「世界即界面」的物理拾取在触屏可用；实际主要靠顶部 4 列情境按钮兜底（120px 宽大按钮重复全部原料），误触罐子只会选错小料且倒杯有 ≥3 金币 2 秒二次确认（day_shop.gd:1231-1236），后果可恢复但卖点退化。
- 修复方向：触屏模式给罐体拾取圆柱半径按画布缩放反向放大（保证屏幕上 ≥44pt 有效目标），或触屏时拉大罐间距/只在 hover 型输入下启用罐体拾取。
- 置信度：几何高；误触率估计中（无真机触摸分布数据）。

### 6.【S3】orientation=4（sensor_landscape）允许 180° 自动翻转，与「摇晃设备」玩法耦合
- 证据：`project.godot` `window/handheld/orientation=4`（SENSOR_LANDSCAPE）；竖屏被正确拒绝（不含 portrait），但系统可在两横朝向间自动旋转。摇茶正是「抓住手机快速甩动」（DAY_NEXT_SHAKE_MOBILE），甩动惯量足以触发系统 180° 翻转，摇茶中途整幅 UI/镜头翻转、SafeFrame 重新布局；`input/shake_gesture.gd:48-51` 重力校准只在首个样本，旋转后不重校准（推导逐样本 delta ≤5.8 < 7.5 阈值，不会假触发摇茶，只是视觉翻转）。
- 期望vs实际：期望摇茶动作期间画面稳定；实际传感器横屏会在玩家最剧烈晃动设备时旋转。另 export_presets.cfg 无任何平台朝向覆盖，全靠此全局值。
- 修复方向：改为 orientation=0 固定横屏；或保留 sensor_landscape 但在 `_can_gesture_shake()` 为真期间锁定 `DisplayServer.screen_orientation`。
- 置信度：中（配置证据确凿，翻转触发依赖真机系统行为，未实机复现）。

## 检查过无问题的面

- **移动渲染预算（项目侧）**：headless day10 满升级 3 顾客（=满员 `_max_customers`=3，day_shop.gd:1666）59,232 三角/199 表面/199 网格/1 阴影光，全部在 120k/200/200/1 红线内；draw_calls 在 headless 为 0 由 `mobile_render_check.gd:72` 的 renderer 分支正确豁免。备注：199/200 表面仅 1 个余量，后续加任一可见道具即破线。
- **安全区**：SafeFrame 移动端读 `get_display_safe_area` 按比例换算（safe_frame.gd:26-37），cutout 布局 0.9 缩放居中、遮罩 overscan 不缩水、跟随元素 `_window_to_frame` 换算，均由 input_check 断言（safe=320x/40y+cutout）；844x390 与 960x600 实测 HUD/暂停按钮无截断、无越屏。
- **传感器摇茶门控**：满杯（`_can_gesture_shake`）才启用；首样本重力校准防「拿起即送摇」；150ms 节流 + 反向脉冲才计数；水平比 1.25 过滤竖直晃动（input_check sensor_gate/mouse_gesture 全绿）。触屏拖拽摇茶依赖默认 `emulate_mouse_from_touch`（未被 project.godot 关闭）→ 走 InputEventMouseMotion，velocity 缺失时有 relative*60 兜底（shake_gesture.gd:21）。
- **无键盘兜底**：暂停（按钮 96x52+Esc）、摇茶（300x58 按钮+点杯）、订单（卡片整卡透明按钮）、店员（CapsuleShape r=0.24 大命中体）、教学（下一步/跳过按钮）均有非键盘路径；`emulate_touch_from_mouse` 亦开启便于桌面调试。
- **订单卡触摸流程**：封杯后点其他卡=仅核对（切 active+提示「点击 · 核对订单」），再点才交付；提示文案随输入方案即时刷新（input_check:302-317）；暂停/结算期间订单按键被拒（R3-F2 保留）。
- **HUD 药丸窄屏**：事件/契约独立成行避免挤压核心指标（day_shop.gd:346-353 注释即此设计）；844x390 实测七枚药丸+暂停无重叠，mobile_render_check 另有塌缩/重叠断言。
- **触觉工程面**：六类语义在昼夜两场景全覆盖（28 处调用）；按最近输入路由手机/手柄（触屏点击即切回 pointer，haptics.gd:27-50）；每档独立冷却防抖；开关主菜单可达、开启有 confirm 脉冲、关闭不影响音频/动画（SETTINGS_HAPTICS_DESC 明示）。
- **竖屏拒绝**：orientation=4 不含 portrait，配置正确（见发现 6 的另一半问题）。
