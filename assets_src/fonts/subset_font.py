#!/usr/bin/env python3
"""Build and verify the runtime LXGW WenKai subset from every shipped text source."""
from __future__ import annotations

import argparse
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


SOURCE_SUFFIXES = {".gd", ".json", ".tscn", ".godot"}
ALWAYS_KEEP = "".join(chr(codepoint) for codepoint in range(32, 127)) + "\n\t\r"


def collect_text(game_root: Path) -> tuple[str, list[Path]]:
    characters = set(ALWAYS_KEEP)
    scanned: list[Path] = []
    for path in sorted(game_root.rglob("*")):
        if not path.is_file() or ".godot" in path.parts or path.suffix not in SOURCE_SUFFIXES:
            continue
        scanned.append(path)
        characters.update(path.read_text(encoding="utf-8"))
    return "".join(sorted(characters)), scanned


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--game-root", type=Path, required=True)
    parser.add_argument("--glyph-list", type=Path, required=True)
    args = parser.parse_args()

    text, scanned = collect_text(args.game_root.resolve())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.glyph_list.parent.mkdir(parents=True, exist_ok=True)

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.notdef_glyph = True
    options.notdef_outline = True
    options.recommended_glyphs = True
    options.recalc_bounds = True
    options.recalc_timestamp = False

    with TTFont(args.source, lazy=False) as original:
        source_cmap = set()
        for table in original["cmap"].tables:
            source_cmap.update(table.cmap)

    font = subset.load_font(str(args.source), options)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    subset.save_font(font, str(args.output), options)

    cmap = set()
    with TTFont(args.output, lazy=False) as result:
        for table in result["cmap"].tables:
            cmap.update(table.cmap)
    requested_codepoints = {ord(character) for character in text if not character.isspace()}
    supported_requested = requested_codepoints & source_cmap
    missing = sorted(supported_requested - cmap)
    if missing:
        preview = " ".join(f"U+{value:04X}" for value in missing[:20])
        raise SystemExit(f"Runtime subset is missing shipped glyphs: {preview}")
    source_missing = requested_codepoints - source_cmap

    args.glyph_list.write_text(text, encoding="utf-8")
    print(
        f"Subset {args.source.name}: {len(scanned)} sources, "
        f"{len(requested_codepoints)} requested codepoints, "
        f"{len(supported_requested)} present in source, "
        f"{len(source_missing)} delegated to fallback, {len(cmap)} cmap entries, "
        f"{args.output.stat().st_size} bytes."
    )


if __name__ == "__main__":
    main()
