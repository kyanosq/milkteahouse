# Background props

Built with the built-in image generation tool using `qa/regions/reference-1280x720.png` as the style, material, palette and perspective reference.

- `background-window-v1.png`: transparent warm-oak wall window; two lower cream/mint panes; no wall, shelf, UI, text or characters.
- `background-shelf-v1.png`: transparent low two-tier light-oak wall shelf; empty shelves; no wall, window, UI, text or characters.
- `background-shelf-v2.png`: final single-level wide light-oak wall shelf with one open cubby, lower base slab and three support feet; genuine alpha; no wall, UI or props.
- `background-entrance-v2.png`: transparent deep-teal entrance panel with a cream/light-oak jamb; the selected v2 crop narrows the jamb to the reference proportion.
- `background-floor-greige-v1.png`: square cool-greige matte wood-plank albedo generated from the equal-coordinate entrance-floor crop; no baked perspective, props, shadows, rugs or UI.
- `background-succulent-v1.png`: transparent pale ceramic pot with a compact sage succulent, generated from `qa/regions/source-potted-succulent-original.png`; no railing, sign, counter, character or floor.
- `background-entry-railing-v1.png`: transparent pale-oak queue rail with three round posts and a narrow muted-teal side panel, generated from `qa/regions/source-entry-railing-original.png` then gently desaturated to the source palette; no customers, plant, sign, counter or floor.
- `background-entry-railing-v2.png`: reference-fitted queue rail with the missing coral upper post restored, slimmer pale-oak handrail, three cream caps and muted-teal inset; genuine alpha, no customers, cards, wall or floor.
- `background-entry-railing-v6.png`: selected same-coordinate perspective fit. It preserves the v2 paint, lowers only the coral top segment, keeps the top/middle anchors stable, then increases the lower shear to meet the reference's sharp near-field turn; genuine alpha on a 200×570 canvas.
- `background-wall-seam-v1.png`: transparent warm-greige perspective wall/baseboard molding generated from the equal-coordinate region 169 crop; no wall fill, window, shelf, floor, furniture or UI.
- `background-wall-seam-v2.png`: final steeper/taller wall molding fitted after same-coordinate runtime comparison; same built-in master and genuine alpha.
- `background-wall-floor-v1.png`: selected transparent wall/floor transition with the source's cool-greige plane below the cream molding.
- `background-wall-floor-v2.png`: final runtime grade, slightly cooler/darker and lower-saturation after equal-coordinate comparison.

Runtime slots at 1280×720:

- Window TextureRect: `(560, -120, 280, 186)`; visible subject approximately x=602–797, y=0–31.
- Shelf TextureRect: `(830, -21, 480, 95)`; visible subject approximately x=830–1280+, y=0–74.
- Entrance TextureRect: `(0, -30, 120, 108)`; visible subject approximately x=0–119, y=0–78.
- Floor material: 512×512 runtime albedo on the existing `grey_cartago` 3D floor mesh; high-resolution master stays in this directory.
- Succulent TextureRect: `(276, 434, 70, 88)`; layered behind the A-frame sign and in front of the 3D shop.
- Entry railing TextureRect: `(126, 72, 220, 680)` at z=1; customers stay behind it and the A-frame sign stays in front at z=2.
- Wall/floor TextureRect: `(0, 42, 650, 160)` behind the window/shelf and all live UI; the molding rises from about y=102 at the left edge to y=42 at x=650, with the greige plane continuing below it.

Wall-seam generation: built-in ImageGen `precise-object-edit` mode. Reference input: `qa/regions/region169/123-back-wall-day1-before.png` (left half only). Prompt summary: isolate one long thin matte warm-gray perspective baseboard with a cream highlight and contact shadow; genuine transparent background; no window, shelf, wall/floor fill, furniture, text, checkerboard or extra objects. Selected built-in source: `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-431288f4-3640-47d7-bd6c-2b198bd88da5.png`; alpha bounds were fitted to the measured 650×100 runtime slot without repainting.

Wall-floor edit: built-in ImageGen `precise-object-edit` followed by `background-extraction`. Preserve the seam and add only the reference's low-contrast cool-greige floor/wainscot plane below it; keep everything above genuinely transparent; no window, shelf, furniture, UI or text. Selected extracted source: `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-6282ba4f-5841-4d34-955c-e4e3590b8e06.png`; its genuine-alpha bounds were fitted to 650×160.

Shelf v2 edit: built-in ImageGen `precise-object-edit`. Image 1 was the Day 1 reference shelf; Image 2 was `background-shelf-v1.png`. Prompt summary: preserve the pale-oak material and soft painterly lighting, replace the two-level rack with one very wide open cubby, a lower base slab and three short support feet, one isolated object on genuine alpha, no wall, pause button, UI, text or extra shelves. Selected source: `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-4b3a51e1-ca72-467b-8e1a-5c9f3370b41f.png`; the final alpha bounds are stored in `background-shelf-v2.png` and fitted to the measured 480×95 slot.

Entry-railing v2 generation: built-in ImageGen `background-extraction`, grounded by the full Day 1 reference and the v1 cutout. Prompt summary: preserve the tall side/isometric queue-rail structure, add the reference's coral upper post, keep soft matte ivory wood, three rounded caps and a narrow dusty-teal inset, isolate the complete object with no people/cards/scene. Selected source: `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-99b01b1e-51ef-4e1c-aeb8-cff9f76b85d0.png`; its baked neutral checkerboard was locally chroma-matted, verified on a contrasting teal field, and fitted to the 120x570 runtime canvas before in-scene placement.
