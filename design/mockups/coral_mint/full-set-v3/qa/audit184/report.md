# Iteration 184 remaining-work audit

## Audit scope

- Surface: Day 1 shop, 1280×720, zh_CN, 11:17, two customers, selected boba.
- User goal: match the supplied reference screen region by region while preserving the playable preparation flow.
- Evidence: `01-current-day1.png` captured in this audit; `reference-1280x720.png` is the user-supplied visual target.

## Overall verdict

The main layout anchors are close, but the screen is not yet a faithful match. The largest remaining gaps are the front-counter silhouette, the lower half of the left queue rail, and the center worktop/ticket treatment. Rear stations, HUD, cup, arrow, pickup label and bell are substantially closer and should not be globally repositioned.

## Region steps

1. **Full composition — needs work (P1).** `02-full-reference-current.png` shows the same major zones and interaction hierarchy, but the current foreground is straighter, cooler and more segmented than the reference. Preserve the established anchors; correct the structural silhouettes and materials below them.
2. **Left queue — needs work (P1).** `03-left-lane-reference-current.png` shows that cards and customer head envelopes are close. The railing's lower half bends left too early, changing the customer/rail overlap. The sign begins roughly 20–25px too high and extends lower, making it taller and more tilted; the succulent is about 15–20px high. Customer contact shadows are much weaker, so both figures float.
3. **Rear stations and HUD — mostly healthy (P3).** `04-rear-hud-reference-current.png` shows the HUD chips, pause control, kettle, milk, toppings, sugar pumps and shaker are already near their source envelopes. Remaining differences are mostly font weight, matte warmth, shelf tone and small-label legibility; avoid another structural move here.
4. **Center worktop and order ticket — needs work (P1).** `05-worktop-pickup-reference-current.png` shows the mat slot, cup and dashed cup circle are aligned. The current mat lacks the reference's rounded stitched outer edge and warm cloth tone. The live order ticket is about 15–20% too narrow/short and its paper stack is too compressed. Dark plank seams and stronger grain compete with the play targets.
5. **Pickup area — minor work (P2).** `05-worktop-pickup-reference-current.png` shows the arrow, label and bell are well aligned. The tray inset is flatter and plainer than the reference, with different border thickness, corner softness and wood/cream texture.
6. **Front counter and primary action — needs work (P1).** `06-front-counter-reference-current.png` shows the CTA is well placed and legible. The reference has one broad curved cream lip and a shaped teal fascia; the current build has straight doubled rails and a flat lower plane. This is the strongest whole-screen structural mismatch.

## Accessibility risks

- Small sugar labels and station captions may be difficult at reduced viewport sizes.
- Patience dots communicate state mainly through color/fill; confirm equivalent accessible names and non-color feedback.
- Screenshots cannot verify keyboard order, screen-reader output, target sizes, animation timing, reduced motion or state-change announcements.

## Recommended order

1. Rebuild the front-counter lip/fascia silhouette from an equal-coordinate crop.
2. Refit only the railing rows below the first middle post; then align sign and succulent vertically.
3. Restore the mat's stitched outer treatment and enlarge the ticket/paper stack without moving its anchor.
4. Reduce worktop seam contrast and warm the scoped material grade.
5. Add/reference-fit customer contact shadows and finish yellow-body silhouette polish.
6. Finish tray material and small typography, then record the preparation flow to audit motion and game feel.

## Evidence limits

This pass audits one frozen Day 1 state. It does not establish animation quality, gameplay depth, later-day layouts, mobile reflow or full accessibility compliance.
