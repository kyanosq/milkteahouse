# Iteration 27 — Featured Menu Operating Loop

Date: 2026-08-10

## Outcome

Night research now changes the next daytime shift directly. Approved legendary and player-named recipes retain their complete formula menu price tier launch heat and lifetime featured sales. The player chooses up to three recipes for tomorrow's featured menu from a dedicated night panel.

Featured recipes become visible customer orders instead of producing invisible passive settlement money. A served order uses the researched menu price; a fresh launch adds a two-coin premium. Fresh featured items also increase arrival speed by four percent each up to twelve percent. Heat loses one day after each completed shift and each featured item remains an evergreen order at a slower cadence after heat expires.

The former `2 × menu price` passive payout at settlement was removed. Settlement now reports actual featured cups and actual featured-drink revenue already earned through service.

## Player-facing rules

- Three featured slots are available. New approved recipes fill an open slot automatically.
- At least one valid drink remains featured whenever the shop owns a recoverable formula.
- A full menu requires removing one current feature before adding another so replacement is deliberate.
- Fresh items appear among regular-customer orders every fourth spawn opportunity. Evergreen items use a slower sixth-opportunity cadence.
- Event-specific critics influencers and group tickets keep their authored special orders; featured orders never overwrite those rules.
- The daytime order card shows the recipe name exact ingredient icons menu price and heat. Long English names use a two-line 248 px card instead of becoming unreadable ellipses.
- The day result explicitly attributes featured cups and revenue.

## Save and migration contract

Save v12 adds:

- `featured_menu`: up to three validated menu-item IDs;
- `menu_last_hype_day`: an idempotency guard for heat decay;
- normalized menu records with formula IDs price tier heat remaining and lifetime sales.

Legacy legendary menu entries are reconstructed by recipe ID or original name. The real Day 9 save's three-field `经典珍珠奶茶` entry therefore recovers its exact black-tea fresh-milk boba formula automatically. A legacy player-named item whose formula was never stored remains in collection/campaign counts but is clearly marked and cannot generate an impossible order.

New market-test candidates now preserve base milk toppings and sugar from the moment the player names the drink. On successful three-night grading the complete formula enters the featured-menu system.

## Balance verification

Deterministic 120-second A/B runs used identical seeds and no upgrades:

| Day / profile | No featured menu | Three fresh features | Effect |
| --- | ---: | ---: | --- |
| 9 / Newbie | 166 · 0★ · 14 served | 189 · 1★ · 14 served | +23 and one recovery star |
| 9 / Regular | 262 · 2★ · 22 served | 300 · 2★ · 22 served | +38 without tier inflation |
| 12 / Newbie | 125 · 0★ · 10 served / 5 lost | 140 · 0★ · 10 served / 6 lost | +15 but still requires growth |
| 12 / Regular | 311 · 2★ · 21 served | 335 · 2★ · 21 served | +24 without a free third star |

With all ten upgrade levels plus three fresh features:

- Day 9 Newbie / Regular: 363 (3★) / 593 (3★);
- Day 12 Newbie / Regular: 385 (2★) / 623 (3★).

The system therefore creates visible value and a modest recovery route while preserving the need for shop upgrades and faster execution. Fresh traffic can add pressure for a slow unupgraded player instead of acting as a pure multiplier.

## Automated verification

`menu_catalog_check.tscn` verifies:

- legacy legendary formula reconstruction;
- automatic three-slot fill full-slot and minimum-one guards;
- hot traffic multiplier and fresh/evergreen order cadence;
- exact formula reconstruction and launch pricing;
- custom recipe formula retention;
- actual daytime delivery sale attribution;
- removal of passive settlement income;
- one-decay-per-day heat and sales idempotency;
- bilingual menu-panel refresh.

Night discovery assertions now require normalized formula/heat data and automatic featuring. Save migration covers v12 selection plus the existing v5 fixture. The complete project regression passed 20/20 without script or runtime errors.

The real player save remained byte-identical before and after all tests and captures:

`c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`

## Visual evidence

All images are 1280 × 720 and were inspected at original resolution:

- `iteration27-featured-menu/01-menu-board-zh.png` — three active slots and two available recipes;
- `iteration27-featured-menu/02-menu-board-en.png` — English formula and metadata wrapping;
- `iteration27-featured-menu/03-featured-order-zh.png` — real branded daytime customer order;
- `iteration27-featured-menu/04-featured-order-en.png` — two-line long-name order card;
- `iteration27-featured-menu/05-featured-settlement-zh.png` — actual featured cups and revenue attribution.

## Remaining human tuning gate

Campaign sessions should judge whether four-percent-per-hot-item traffic feels exciting or stressful immediately after a launch and whether players rotate features before heat expires. If players always leave the first three items selected the next iteration should add customer-segment demand rather than simply increasing the numerical premium.
