# Central cup state assets

Built-in imagegen mode, derived from the reference cup crop and a shared empty-cup master. Final runtime files live in `game/assets/ui/full_set_v3/cup/`.

- `cup-empty-v1.png`: empty clear cup, exact shared silhouette and anchor.
- `cup-tea-v1.png`: 58% warm amber tea.
- `cup-milk-v1.png`: 72% pale caramel milk tea with a restrained swirl.
- `cup-topping-v1.png`: milk tea with tapioca pearls settled at the bottom.
- `cup-topping-v2.png`: reference-calibrated topping state with a clean alpha edge, thinner rim, lower liquid surface and smaller pearls; the 296×332 runtime copy is color-normalized for the live workbench.
- `cup-sealed-v1.png`: mixed milk tea, pearls, taut film and short coral straw.

Prompt set: preserve the same front-facing three-quarter tapered cup, double white rim, soft airy hand-painted mobile-game rendering, warm ivory/caramel palette, restrained matte highlights, no oily CGI sheen, no logo/text/watermark, and genuine transparent exterior. Each derived prompt changes only the named contents or seal state; the generated alpha was normalized against the empty-cup master to keep every state pixel-aligned.

Topping-v2 prompt: use the current transparent cup as the edit target and the 1280×720 reference crop as visual truth; keep the centered near-front tapered silhouette, replace the thick noisy rim with the reference's narrow clean ellipse, lower and soften the caramel liquid, reduce the pearls to small loose bottom rows, remove every fringe/stray pixel, and return genuine alpha with no background, label, lid, straw, shadow patch or watermark. Built-in ImageGen precise-object edit plus transparent background extraction; saturation was normalized to 0.68 after extraction.
