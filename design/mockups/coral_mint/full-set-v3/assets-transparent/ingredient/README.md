# Ingredient assets

| Name | Description | In-game size | Runtime path | Cost |
|---|---|---:|---|---:|
| 珍珠 v4 | 奶油陶瓷碗中密集的深可可色珍珠；透明底 | 128×128px source, 76×72px UI slot | `game/assets/icons/boba.png` | Built-in ImageGen |
| 椰果 v4 | 奶油陶瓷碗中密集的半透明乳白椰果方块；透明底 | 128×128px source, 76×72px UI slot | `game/assets/icons/coconut_jelly.png` | Built-in ImageGen |
| 布丁 v4 | 奶油陶瓷碗中密集的柔金橙色布丁方块；透明底 | 128×128px source, 76×72px UI slot | `game/assets/icons/pudding.png` | Built-in ImageGen |
| 桂花冻 v3 | 奶油陶瓷碗中的低饱和蜂蜜金桂花冻；透明底 | 128×128px source, 76×72px UI slot | `game/assets/icons/osmanthus_jelly-v3.png` | Built-in ImageGen |

Day 1 v4 source files:

- `topping-boba-v4.png` ← `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-149a9edb-0cfd-4a51-8e90-6e5f5c171874.png`
- `topping-coconut-jelly-v4.png` ← `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-d6395603-724e-4781-8d47-b46f8a6f3780.png`
- `topping-pudding-v4.png` ← `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-be591671-0f7c-4554-bb9c-580f1252c35b.png`

Built-in ImageGen mode: `precise-object-edit`. Prompt summary: preserve the reference's shallow warm-cream bowl and replace the sparse contents with a dense, readable serving of dark tapioca pearls, milky coconut-jelly cubes, or golden pudding cubes; cozy matte painterly 3D, restrained light, one isolated object, genuine alpha, no card/text/UI. The accepted images are normalized to one `(5,22)–(123,104)` optical box; the checkerboard-backed matte boba revision was rejected.

Final built-in ImageGen prompt:

> Replace the unfinished osmanthus placeholder with six to eight translucent pale honey-gold jelly cubes and muted flower flecks in the same cream ceramic bowl, hand-painted softness, lighting, scale and padding as the adjacent topping icons; no text, outline, lid, plate, spoon, scene or watermark.

The first checkerboard-background extraction was rejected to `qa/rejected/region155-osmanthus/`. The accepted subject was regenerated on solid muted teal, locally chroma-matted, checked on contrasting coral and cream backgrounds, then normalized to the existing family’s exact 98×77px visible bounds at x12/y30 before the 128×128 runtime export.
