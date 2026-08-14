# Iteration 22 — Package and Export Readiness

Date: 2026-08-09  
Engine: Godot 4.6.3 stable

## Outcome

The current vertical slice now has reproducible release presets for macOS, Windows Desktop, Android and iOS. macOS, Windows and iOS artifacts were generated from the same project after the Blender upgrade-kit integration. Android is project-ready but locally blocked by the missing external JDK/Android SDK toolchain.

## Runtime payload reductions

### Font subsetting

- Untouched OFL source: `assets_src/fonts/LXGWWenKai-Regular.full.ttf` — 25,575,676 B.
- Shipped deterministic subset: `game/assets/fonts/LXGWWenKai-Regular.ttf` — 505,004 B.
- Reduction: 98.0% (24.39 MiB to 0.48 MiB).
- Builder is pinned to `fonttools==4.63.0`; the exact collected input is stored in `LXGWWenKai-runtime-glyphs.txt`.
- Eleven codepoints not present in the source font remain intentional system-fallback glyphs: `✅ ❌ 🌟 🍚 🐟 📢 🔍 😡 🤐 🤳 🦉`.
- Runtime SHA-256: `23c9d62c0cb815f9dd4f548d45071ea04724b73a4a50e7f7724ee463069bdccc`.

Visual evidence: `design/qa/iteration20-font-package/01-menu-subset-font.png` through `03-night-subset-font.png`. The automated font test checks import, 45 critical UI characters, system fallback and a sub-1 MiB budget.

### Shop texture packaging

The shop GLB contains its four used images in buffer views. Its Godot import mode is now **Embed as Basis Universal** (`gltf/embedded_image_handling=2`) instead of extracting runtime dependencies beside the GLB. This allows old extracted `shop_scene_tmp*` and `shop_scene_floor_coral_mint.png` copies to be excluded safely.

An earlier attempt excluded those images while the import mode was still **Extract Textures**. The exported app then had missing dependencies; the clean startup smoke caught the defect. The exclusion was accepted only after the Basis Universal reimport removed every external texture path from the imported scene. Runtime evidence: `design/qa/iteration22-package-export/01-day10-basisu-shop.png`.

Platform app icons are generated from one opaque 1024 × 1024 master and resized deterministically to fourteen required iOS sizes. The derivative size sources remain available to the exporters but are excluded as ordinary PCK resources; the 1024 px master remains because `application/config/icon` is a real project dependency. The platform-generated icons stay intact while the repeated small runtime copies are removed, reducing the icon-bearing PCK from 12,904,044 B to 11,912,032 B on macOS.

## Export results

| Target | Artifact | Result | Verification |
| --- | --- | ---: | --- |
| macOS | `build/macos/MilkTeaHouse.zip` — 73,380,459 B | Passed | Universal x86_64 + arm64; bundle ID/version/icon present; PCK 10,164,000 B; exported binary prints `[EXPORT_SMOKE] clean startup/shutdown` without leak/RID warnings |
| Windows Desktop | `build/windows/MilkTeaHouse.exe` — 114,784,560 B | Package passed | PE32+ x86-64 single executable with embedded PCK; compiled scripts; no tests or extracted shop-texture copies. Runtime execution requires Windows hardware/VM and was not claimed on macOS |
| iOS | `build/ios/MilkTeaHouse.ipa` — 37,737,456 B | Passed | Xcode archive and IPA export succeeded; arm64; strict code-sign verification passed; bundle ID `com.milkteahouse.game`; version `0.1.0` (1); signed by Team `9AP4GA8W53`; PCK 10,164,048 B; app icons/Assets.car/PrivacyInfo present |
| Android | `build/android/MilkTeaHouse-debug.apk` | Environment-blocked | Preset validates arm64-only package `com.milkteahouse.game`, but this Mac has no valid Java SDK path and lacks Android SDK `platform-tools`, `adb`, `build-tools`, and `apksigner` |

Artifact SHA-256:

- macOS: `50f4688105e6c5d0916b9165ccf755f2647cef61f390069d87bfffe9a0e23674`
- Windows: `e0297b1cb1280b30bcef73027715241135dc9a3989a8d679bc3f057fa43485eb`
- iOS: `ac771d7ca6eacf3fc4a13d254c9bbc58158c0f4db4f1ef25eda9696381a131ee`

These artifact values were refreshed after the Iteration 23 Blender mobile-performance pass; its detailed before/after evidence is in `design/qa/mobile-render-performance-iteration23.md`.

The iOS development provisioning profile is `iOS Team Provisioning Profile: *` (`cbedca05-d408-47ec-94ef-2190e33e9277`), expiring 2027-07-29. Development signing intentionally leaves `get-task-allow=true`; an App Store distribution profile remains a release-account step, not a game-project defect. Xcode reports non-fatal template warnings for empty unused camera/photo/microphone descriptions and skipped AppIntents metadata.

## Automated guard

`game/tests/export_config_check.tscn` now verifies:

- all four preset names and compiled-script mode;
- identical test/duplicate-texture/app-icon exclusions;
- Android arm64 package identity;
- iOS team, bundle and 15 exact opaque icon assets;
- mobile ETC2/ASTC import support;
- project icon binding;
- shop Basis Universal embedded-image mode.

The full 13-suite gameplay/release regression passed after final packaging. Regular-profile Day 10 with all ten shop upgrade levels also remained 29/29 served, 515 coins and 3 stars. The real save SHA-256 stayed `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

## Remaining release gates

1. Install/configure a JDK and Android SDK, then build and run the arm64 APK on representative low/mid devices.
2. Boot an iOS simulator or authorize a physical-device install for runtime capture. All 24 installed iOS simulators were shutdown; the debugger workflow deliberately did not boot one without user action.
3. Profile draw calls, GPU/CPU frame time, memory and thermals on mobile hardware against the GDD budgets.
4. Run the planned five human 14-day sessions and a native Windows smoke before declaring a public release candidate.
