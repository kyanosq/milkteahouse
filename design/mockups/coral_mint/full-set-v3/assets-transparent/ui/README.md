# Transparent UI assets

| Name | Description | In-game size | Path | Generator |
|---|---|---:|---|---|
| Reset sign narrow | Cream A-frame sign with blank teal board and reference-matched compact feet | 186×165 px | `ui-sign-reset-narrow.png` | Built-in ImageGen edit + background extraction |
| Reset sign front v2 | Nearly front-facing cream A-frame with centered blank teal board | 178×223 px | `ui-sign-reset-front-v2.png` | Built-in ImageGen precise-object edit + background extraction |
| Reset sign front v3 | Reference-proportioned front sign with wider, shorter teal board | 161×203 px | `ui-sign-reset-front-v3.png` | Built-in ImageGen proportion edit + background extraction |
| Pickup arrow v2 | Five-dash mint handoff arc with a lower-left arrowhead | 182×93 px | `ui-arrow-pickup-v2.png` | Built-in ImageGen precise-object edit + background extraction |
| Pickup arrow v3 | Flat-color five-dash mint handoff arc, no highlights | 1672×941 px | `ui-arrow-pickup-v3.png` | Built-in ImageGen cleanup edit + transparent background extraction |
| Pickup arrow v4 | Reference-muted mint handoff arc with unchanged geometry | 195×125 px | `ui-arrow-pickup-v4.png` | Existing v3 alpha/silhouette with selective color grade |
| Pickup arrow v5 | Final pale-mint handoff arc calibrated in the Day 1 scene | 195×125 px | `ui-arrow-pickup-v5.png` | Existing v3 alpha/silhouette with final reference color grade |
| Reset sign v4 | Slim pale-cream matte A-frame with blank teal board | 1206×1304 px | `ui-sign-reset-front-v4.png` | Built-in ImageGen precise-object edit + black-background alpha extraction |
| Reset sign front v6 | Reference-aligned compact A-frame with a lighter mint board | 161×203 px | `ui-sign-reset-front-v6.png` | Existing v4 alpha/silhouette with selective board color grade |
| Reset sign cup v1 | Warm-cream line-art milk-tea cup for the sign's brand lockup | 64×64 px | `ui-icon-sign-cup-v1.png` | Built-in ImageGen + solid-black alpha extraction |
| Selected ingredient frame v1 | Blank cream nine-slice tile with a strong coral double outline | 512×160 px | `ui-button-selected-frame-v1.png` | Built-in ImageGen precise-object edit + transparent background extraction |
| Cup guide v1 | Flat source-matched mint dashed placement oval | 200×140 px | `ui-cup-guide-v1.png` | Exact-coordinate reference crop + teal alpha extraction |
| HUD day / coin / inspiration v1 | Source-matched flat ochre line icons | 36×36 px each | `../hud-day.png`, `../hud-coin.png`, `../hud-inspiration.png` | Exact-coordinate reference crops + local cream-background alpha extraction |

Prompt: preserve the existing cream/teal painterly A-frame sign and camera angle; change only the feet to a compact stance whose outside span is about 1.20× the top frame; no text, symbols, shadow, extra objects, or background; return genuine alpha.

Front-v2 prompt: rebuild only the sign to match the source crop's near-front narrow A-frame silhouette; keep cream wood and a blank muted-teal board; no text, shadow, surrounding scene, or checkerboard; return genuine alpha.

Front-v3 prompt: keep the alpha sign and materials; make the teal board wider/shorter, slim the side rails and keep compact feet to match the source crop; no text, background or shadow; preserve genuine alpha.

Pickup-v2 prompt: rebuild the arrow from the source crop with a lower-left head, five rounded mint dashes and a right-weighted apex; no wood, tray, text or shadow; preserve genuine alpha.

Pickup-v4 fitting: preserve the selected v3 genuine alpha, dash count, arrowhead and 195×125 canvas; lift red while slightly lowering green/blue to match the reference's quieter mint. No generative repaint, crop, stretch or shadow was added.

Pickup-v5 fitting: repeat the v3 alpha-preserving grade with a slightly higher red floor and gentler green/blue reduction after same-coordinate runtime comparison. Geometry and transparency remain byte-for-byte equivalent at the alpha surface.

Front-v6 fitting: preserve the selected v4 genuine alpha, frame geometry and wood pixels; lift only teal-dominant board pixels toward the source's lighter muted mint. No generative repaint, stretch, background, text or shadow was added.

Sign-cup prompt: create one compact takeaway milk-tea cup outline matching the reference sign, with rounded lid, short straw and tiny accent; warm ivory single-color strokes on solid black for alpha extraction; no text, sign frame, fill, gradient, glow, shadow, checkerboard or extra object. Built-in generation mode; selected output was cropped to the measured mark, resized to 64×64 and extracted to genuine alpha.

Selected-frame prompt: preserve the secondary frame's wide blank nine-slice construction; keep the warm cream paper center and replace only the border with the source selected card's clean coral double outline and narrow cream separators; no text, icon, bowl, topping, teal dashes or content-area decoration; extract the exterior to genuine alpha.

Cup-guide fitting: crop the exact `(480,390)–(680,530)` Day 1 source coordinates, retain only pixels whose muted-teal channels separate from the cream workmat, and preserve the original dash geometry at 200×140. Built-in ImageGen precise-object variants were inspected but rejected because their dash length/count or glow drifted from the source; the final uses the source pixels directly.

HUD-icon fitting: crop the Day 1 source at `(29,19)–(65,55)`, `(248,19)–(284,55)` and `(332,19)–(368,55)`; estimate each scanline's cream chip background from its empty edge pixels, then retain the source foreground as genuine alpha. The runtime uses the resulting 36×36 assets without scaling or generative repainting.
