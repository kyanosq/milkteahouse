#!/usr/bin/env bash
# 层2可玩性度量（验证方案 §二）：确定性 bot 矩阵 → balance_table.csv + 门禁断言。
# 用法: bash tools/balance_metrics.sh [输出目录]（默认 design/qa）
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$REPO_DIR/game"
source "$SCRIPT_DIR/find_godot.sh"
OUT_DIR="${1:-$REPO_DIR/design/qa}"
CSV="$OUT_DIR/balance_table.csv"
SAMPLES="${SAMPLES:-5}"

if [[ ! "$SAMPLES" =~ ^[1-9][0-9]*$ ]]; then
  printf '[BALANCE] SAMPLES must be a positive integer, got: %s\n' "$SAMPLES" >&2
  exit 2
fi

if ! GODOT="$(find_godot)"; then
  printf '[BALANCE] Godot not found; set GODOT_BIN to the executable path\n' >&2
  exit 2
fi
if [[ ! -x "$GODOT" ]]; then
  printf '[BALANCE] Godot is not executable: %s\n' "$GODOT" >&2
  exit 2
fi

mkdir -p "$OUT_DIR"
echo "profile,day,sample,earned,goal,stars,tau,dd,serve_rate,angry" > "$CSV"

failures=()
# 度量口径：regular/skilled 沿“现实可负担”升级路径跑（设计意图是边赚边买），
# 否则零升级存钱流会把 τ 推成虚高的无聊带。newbie 维持零升级（其前期真实状态）。
upgrades_for() {
  local profile="$1" day="$2"
  case "$profile" in
    regular)
      case "$day" in
        1) echo "" ;;
        3) echo "comfort:1" ;;
        5) echo "comfort:1,shaker:1" ;;
        7) echo "comfort:2,shaker:1" ;;
        9) echo "comfort:2,shaker:2,tip_jar:1" ;;
        12|14) echo "comfort:3,shaker:2,tip_jar:1" ;;
      esac ;;
    skilled)
      case "$day" in
        1) echo "" ;;
        3) echo "comfort:1,shaker:1" ;;
        5) echo "comfort:2,shaker:1" ;;
        7) echo "comfort:2,shaker:2,tip_jar:1" ;;
        9) echo "comfort:3,shaker:2,tip_jar:2" ;;
        12|14) echo "comfort:3,shaker:3,tip_jar:2" ;;
      esac ;;
  esac
}
run_one() {
  local profile="$1" day="$2" sample="$3"
  local log="/tmp/bm_${profile}_${day}_${sample}.log"
  BOT_PROFILE="$profile" BOT_DAY="$day" BOT_SAMPLE="$sample" \
    BOT_UPGRADES="$(upgrades_for "$profile" "$day")" \
    "$GODOT" --headless --path "$PROJECT_DIR" --log-file "$log" \
    "res://tests/autoplay.tscn" >/dev/null 2>&1
  local result=$?
  local unexpected_errors
  unexpected_errors="$(grep -E '^(SCRIPT ERROR:|ERROR:)' "$log" \
    | grep -Fv 'ERROR: Condition "ret != noErr" is true. Returning: ""' || true)"
  if [[ "$result" -ne 0 || -n "$unexpected_errors" ]]; then
    failures+=("godot-error:$profile:d$day:s$sample:exit-$result")
    return
  fi
  local line
  line="$(grep '\[RESULT\]' "$log" | head -1)"
  if [[ -z "$line" ]]; then
    failures+=("no-result:$profile:d$day:s$sample")
    return
  fi
  local earned goal stars tau dd serve angry
  earned="$(grep -o 'earned=[0-9]*' <<<"$line" | head -1 | cut -d= -f2)"
  goal="$(grep -o 'goal=[0-9]*' <<<"$line" | head -1 | cut -d= -f2)"
  stars="$(grep -o 'stars=[0-9]*' <<<"$line" | head -1 | cut -d= -f2)"
  tau="$(grep -o 'tau=[0-9.]*' <<<"$line" | head -1 | cut -d= -f2)"
  dd="$(grep -o 'dd=[0-9]*' <<<"$line" | head -1 | cut -d= -f2)"
  serve="$(grep -o 'serve_rate=[0-9]*' <<<"$line" | head -1 | cut -d= -f2)"
  angry="$(grep -o 'angry=[0-9]*' <<<"$line" | head -1 | cut -d= -f2)"
  if [[ -z "$earned" || -z "$goal" || -z "$stars" || -z "$tau" \
      || -z "$dd" || -z "$serve" || -z "$angry" ]]; then
    failures+=("malformed-result:$profile:d$day:s$sample")
    return
  fi
  echo "$profile,$day,$sample,$earned,$goal,$stars,$tau,$dd,$serve,$angry" >> "$CSV"
}

# 矩阵：三画像 × 关键日（首小时/中期/第二周/终章）× N 种子。
for profile in newbie regular skilled; do
  for day in 1 3 5 7 9 12 14; do
    for sample in $(seq 0 $((SAMPLES - 1))); do
      run_one "$profile" "$day" "$sample"
    done
  done
done
echo "[BALANCE] wrote $CSV ($(($(wc -l < "$CSV") - 1)) runs)"

python3 - "$CSV" "$SAMPLES" <<'PY'
import csv, sys, statistics as st
rows = list(csv.DictReader(open(sys.argv[1])))
sample_count = int(sys.argv[2])
fails = []
def med(v): return st.median(v)
def check(cond, msg):
    if not cond: fails.append(msg)

# 每画像×日的 p50 汇总
summary = {}
for r in rows:
    key = (r["profile"], int(r["day"]))
    summary.setdefault(key, []).append(r)

print(f'{"profile":8} {"day":>3} {"earned_p50":>10} {"stars_p50":>9} {"tau_p50":>7} {"dd_med":>6}')
for (profile, day), rs in sorted(summary.items(), key=lambda kv: (kv[0][0], kv[0][1])):
    earned = med([float(r["earned"]) for r in rs])
    stars = med([float(r["stars"]) for r in rs])
    tau = med([float(r["tau"]) for r in rs])
    dd = med([float(r["dd"]) for r in rs])
    print(f"{profile:8} {day:3d} {earned:10.0f} {stars:9.0f} {tau:7.2f} {dd:6.0f}")

# ponytail: <3 seeds cover parser/runtime smoke only; use SAMPLES>=3 for statistical claims.
if sample_count < 3:
    print(f"[BALANCE] SMOKE PASSED samples={sample_count}; statistical gates require SAMPLES>=3")
    sys.exit(0)

# 口径注记（2026-08-15，对照设计文档 §2/§6）：
# - 无聊带门禁只针对 mid（regular）画像：skilled 的高 τ 是 42/42★ 精通回报的
#   设计意图（3★ 线 = τ1.4），不是无聊。
# - 张力带取 [1.00, 1.45]（2★/3★ 边界区：逼近三星但无保证），而非早期草稿的
#   [0.9,1.15]（那意味着 mid 常态性拿不到 2★）。窗口从 Day8 起算——Day1-5 是
#   文档化的全清学习窗口。
# - DD 门禁取中位数：极端样本（回暖日/主编局）允许个别为 0，典型日必须有目标。
for (profile, day), rs in summary.items():
    if profile != "regular": continue
    dd_mid = med([int(r["dd"]) for r in rs])
    check(dd_mid >= 1, f"DD gate: regular day {day} median dd={dd_mid} (no affordable goal)")

reg = {d: med([float(r["tau"]) for r in rs]) for (p, d), rs in summary.items() if p == "regular"}
window = [reg.get(d) for d in range(8, 15) if reg.get(d) is not None]
in_band = sum(1 for t in window if 1.00 <= t <= 1.45)
check(in_band >= 2, f"tension gate: regular days 8-14 have only {in_band} tau-in-[1.00,1.45] days")

series = [reg[d] for d in sorted(reg) if d >= 8]
for i in range(len(series) - 2):
    check(not (series[i] > 1.6 and series[i+1] > 1.6 and series[i+2] > 1.6),
          f"boredom gate: regular tau>1.6 for 3 consecutive sampled days at index {i}")

if fails:
    print("[BALANCE] FAILED")
    for f in fails: print("  " + f)
    sys.exit(1)
print("[BALANCE] PASSED dd-median>=1 tension>=2 in d8-14 no-3day-boredom(regular)")
PY
metrics_rc=$?

if [[ ${#failures[@]} -ne 0 || $metrics_rc -ne 0 ]]; then
  printf '[BALANCE] FAILED runs-missing=%d\n' "${#failures[@]}" >&2
  if [[ ${#failures[@]} -ne 0 ]]; then
    printf '  %s\n' "${failures[@]}" >&2
  fi
  exit 1
fi
