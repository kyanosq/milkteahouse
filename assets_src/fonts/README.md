# Runtime font pipeline

`LXGWWenKai-Regular.full.ttf` is the untouched OFL source font. The game ships a deterministic subset at `../../game/assets/fonts/LXGWWenKai-Regular.ttf`.

`subset_font.py` collects every codepoint present in shipped GDScript, JSON, TSCN and project settings files, adds printable ASCII, builds the subset with FontTools and reopens the result to prove that all non-emoji runtime text remains mapped. Its exact character input is stored in `LXGWWenKai-runtime-glyphs.txt` for review.

Pinned tool: `fonttools==4.63.0` (Python 3.10+).

```bash
python3 -m pip install --target /tmp/milkteahouse-fonttools-4.63.0 fonttools==4.63.0
PYTHONPATH=/tmp/milkteahouse-fonttools-4.63.0 python3 subset_font.py \
  --source LXGWWenKai-Regular.full.ttf \
  --output ../../game/assets/fonts/LXGWWenKai-Regular.ttf \
  --game-root ../../game \
  --glyph-list LXGWWenKai-runtime-glyphs.txt
```

Validation compares the output against the original font's cmap. Characters absent from the original font are reported as fallback glyphs rather than falsely blamed on subsetting.

This intentionally keeps system-font fallback available for arbitrary player-entered recipe names while avoiding a 24 MiB full multilingual font in every exported package.

Verified output (2026-08-10):

- source: 25,575,676 bytes;
- runtime subset: 503,208 bytes (98.0% smaller);
- runtime SHA-256: `e0ff0a50889a23ff24612d37526349681a08f21f703c38c34d4dce99a37e5a29`;
- PlayStation prompt glyphs included in-package: `× ○ □ △`;
- intentional source-font fallbacks: `🌟 🍚 🐟 📢 🔍 🤐 🤳 🦉`.

`game/tests/font_asset_check.tscn` guards import, 95 critical UI glyphs, system fallback and a 256 KiB–1 MiB runtime budget.
