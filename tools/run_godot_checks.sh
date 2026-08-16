#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$REPO_DIR/game"

CHECK_SCENES=(
  "tests/audio_check.tscn"
  "tests/campaign_check.tscn"
  "tests/dark_menu_check.tscn"
  "tests/endless_contract_check.tscn"
  "tests/event_check.tscn"
  "tests/export_config_check.tscn"
  "tests/font_asset_check.tscn"
  "tests/input_check.tscn"
  "tests/localization_check.tscn"
  "tests/market_test_check.tscn"
  "tests/menu_catalog_check.tscn"
  "tests/menu_check.tscn"
  "tests/model_asset_check.tscn"
  "tests/night_check.tscn"
  "tests/night_resume_check.tscn"
  "tests/onboarding_check.tscn"
  "tests/operating_cost_check.tscn"
  "tests/prep_batch_check.tscn"
  "tests/recipe_book_check.tscn"
  "tests/release_settings_check.tscn"
  "tests/research_brief_check.tscn"
  "tests/research_progress_check.tscn"
  "tests/save_integrity_check.tscn"
  "tests/staff_check.tscn"
  "tests/upgrade_check.tscn"
)

EXPECTED_CHECK_COUNT=25
if [[ "${#CHECK_SCENES[@]}" -ne "$EXPECTED_CHECK_COUNT" ]]; then
  printf '[GODOT_CHECKS] expected %d scenes, configured %d\n' \
    "$EXPECTED_CHECK_COUNT" "${#CHECK_SCENES[@]}" >&2
  exit 2
fi

if [[ -n "${GODOT_BIN:-}" ]]; then
  GODOT_EXECUTABLE="$GODOT_BIN"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT_EXECUTABLE="/Applications/Godot.app/Contents/MacOS/Godot"
elif command -v godot4 >/dev/null 2>&1; then
  GODOT_EXECUTABLE="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
  GODOT_EXECUTABLE="$(command -v godot)"
else
  printf '[GODOT_CHECKS] Godot not found; set GODOT_BIN to the executable path\n' >&2
  exit 2
fi

if [[ ! -x "$GODOT_EXECUTABLE" ]]; then
  printf '[GODOT_CHECKS] Godot is not executable: %s\n' "$GODOT_EXECUTABLE" >&2
  exit 2
fi

LOG_DIR="$(mktemp -d /private/tmp/milkteahouse-godot-checks.XXXXXX)" || exit 2
failures=()
passed=0
campaign_passed=0

printf '[GODOT_CHECKS] godot=%s scenes=%d logs=%s\n' \
  "$GODOT_EXECUTABLE" "${#CHECK_SCENES[@]}" "$LOG_DIR"

for scene in "${CHECK_SCENES[@]}"; do
  scene_path="$PROJECT_DIR/$scene"
  scene_name="${scene##*/}"
  scene_name="${scene_name%.tscn}"
  log_file="$LOG_DIR/$scene_name.log"

  if [[ ! -f "$scene_path" ]]; then
    printf '[GODOT_CHECKS] FAIL %s (scene missing)\n' "$scene" >&2
    failures+=("$scene:missing")
    continue
  fi

  printf '[GODOT_CHECKS] RUN  %s\n' "$scene"
  "$GODOT_EXECUTABLE" \
    --headless \
    --path "$PROJECT_DIR" \
    --log-file "$log_file" \
    "res://$scene"
  result=$?

  # Godot can return 0 after a GDScript assertion, parse failure or runtime
  # error. Treat every logged engine/script error as a failure except the known
  # macOS sandbox CA-certificate probe emitted before any project scene runs.
  unexpected_errors="$(grep -E '^(SCRIPT ERROR:|ERROR:)' "$log_file" \
    | grep -Fv 'ERROR: Condition "ret != noErr" is true. Returning: ""' || true)"
  if [[ "$result" -eq 0 && -n "$unexpected_errors" ]]; then
    result=3
  fi

  if [[ "$result" -eq 0 ]]; then
    passed=$((passed + 1))
    printf '[GODOT_CHECKS] PASS %s\n' "$scene"
  else
    failures+=("$scene:$result")
    printf '[GODOT_CHECKS] FAIL %s (exit=%d, log=%s)\n' \
      "$scene" "$result" "$log_file" >&2
    tail -n 80 "$log_file" >&2 || true
  fi
done

# The three-route campaign gate is deliberately opt-in because it renders and
# settles forty-two real shop days. Its fixed logical clock and assertions make
# it suitable for nightly/release CI without slowing every local smoke pass.
if [[ "${RUN_CAMPAIGN:-0}" == "1" ]]; then
  for strategy in careful balanced growth; do
    log_file="$LOG_DIR/campaign_strategy_$strategy.log"
    printf '[GODOT_CHECKS] RUN  campaign_strategy:%s\n' "$strategy"
    CAMPAIGN_STRATEGY="$strategy" "$GODOT_EXECUTABLE" \
      --headless \
      --path "$PROJECT_DIR" \
      --log-file "$log_file" \
      "res://tests/campaign_strategy_sim.tscn"
    result=$?
    unexpected_errors="$(grep -E '^(SCRIPT ERROR:|ERROR:)' "$log_file" \
      | grep -Fv 'ERROR: Condition "ret != noErr" is true. Returning: ""' || true)"
    if [[ "$result" -eq 0 && -n "$unexpected_errors" ]]; then
      result=3
    fi
    if [[ "$result" -eq 0 ]]; then
      campaign_passed=$((campaign_passed + 1))
      printf '[GODOT_CHECKS] PASS campaign_strategy:%s\n' "$strategy"
    else
      failures+=("campaign_strategy:$strategy:$result")
      printf '[GODOT_CHECKS] FAIL campaign_strategy:%s (exit=%d, log=%s)\n' \
        "$strategy" "$result" "$log_file" >&2
      tail -n 80 "$log_file" >&2 || true
    fi
  done
fi

if [[ "${#failures[@]}" -ne 0 ]]; then
  printf '[GODOT_CHECKS] FAILED passed=%d failed=%d logs=%s\n' \
    "$passed" "${#failures[@]}" "$LOG_DIR" >&2
  printf '  %s\n' "${failures[@]}" >&2
  exit 1
fi

printf '[GODOT_CHECKS] PASSED core=%d campaign=%d failed=0 logs=%s\n' \
  "$passed" "$campaign_passed" "$LOG_DIR"
