#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
配方研发 · 文字版原型 v0.2
==========================
用途：验证"晚上研发"完整循环的手感（对应 design/recipe_system.md §2~§6）。
运行：python3 prototype/recipe_lab.py [--day N]   # --day 可跳到第 N 天（解锁后期原料调试用）
存档：prototype/save.json（删掉即重开）

v0.2 新增：灵感点预算 / 原料熟练度成长 / 3 天市场检验 / 黑暗菜单与黑暗传说（话题度经济）
"""

import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "design" / "data"
SAVE_FILE = Path(__file__).resolve().parent / "save.json"

DIMS = ["aroma", "sweet", "rich", "fresh", "chew"]
DIM_NAMES = {"aroma": "香气", "sweet": "甜感", "rich": "浓郁", "fresh": "清爽", "chew": "嚼感"}

ATTEMPT_COST = 2   # 每次试做消耗灵感点
INSP_BASE = 8      # 每晚基础灵感点

FEEDBACK_HIGH = {
    "aroma": "香得冲鼻子，有点上头过度了……",
    "sweet": "齁得慌，喝两口就腻了……",
    "rich":  "太厚重了，糊嗓子。",
    "fresh": "太寡了，压不住茶涩。",
    "chew":  "料塞得太满，这是在喝八宝粥吗？",
}
FEEDBACK_LOW = {
    "aroma": "没什么香气，平平无奇。",
    "sweet": "寡淡，像在喝刷锅水。",
    "rich":  "水味很重，单薄。",
    "fresh": "闷闷的，喝完嘴里发腻。",
    "chew":  "口感单薄，一滑到底。",
}

DEFAULT_STATE = {
    "day": 1, "discovered": [], "dark_discovered": [],
    "xp": {}, "menu": [], "dark_menu": [], "tests": [], "buzz": 0,
}


# ---------------------------------------------------------------- 数据与存档

def load_data():
    with open(DATA_DIR / "ingredients.json", encoding="utf-8") as f:
        ing = json.load(f)
    with open(DATA_DIR / "recipes.json", encoding="utf-8") as f:
        recipes = json.load(f)
    with open(DATA_DIR / "dark_recipes.json", encoding="utf-8") as f:
        darks = json.load(f)
    return ing, recipes, darks


def load_state():
    if SAVE_FILE.exists():
        with open(SAVE_FILE, encoding="utf-8") as f:
            return json.load(f)
    return json.loads(json.dumps(DEFAULT_STATE))


def save_state(state):
    with open(SAVE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


# ---------------------------------------------------------------- 熟练度（§6.1）

def level_of(xp):
    return min(5, xp // 8 + 1)


def main_dim(item):
    return max(DIMS, key=lambda d: item["flavor"][d])


def gain_xp(state, items):
    """试做后全部用到的原料 +1 xp（翻车也涨），返回升级消息列表"""
    msgs = []
    for it in items:
        if it["id"] == "none":
            continue
        old = level_of(state["xp"].get(it["id"], 0))
        state["xp"][it["id"]] = state["xp"].get(it["id"], 0) + 1
        new = level_of(state["xp"][it["id"]])
        if new > old:
            msgs.append(f"📈 {it['name']} 熟练度升到 Lv{new}！"
                        + ("（主风味+1）" if new >= 3 else ""))
    return msgs


# ---------------------------------------------------------------- 核心判定（§2~§4）

def compute_flavor(cup, ing_data, state):
    items = [cup["base"], cup["milk"]] + cup["toppings"]
    flavor = {d: 0 for d in DIMS}
    for it in items:
        for d in DIMS:
            flavor[d] += it["flavor"][d]
        # 熟练度 Lv3+ 主维度 +1（§6.1）
        if level_of(state["xp"].get(it["id"], 0)) >= 3:
            flavor[main_dim(it)] += 1
    flavor["sweet"] += cup["sugar"]["sweet_mod"]

    triggered = []
    for rule in ing_data["affinities"]:
        a, b = rule["tags"]
        if a == b:
            hit = sum(1 for it in items if a in it["tags"]) >= 2
        else:
            hit = any(a in it["tags"] for it in items) and any(b in it["tags"] for it in items)
        if hit:
            triggered.append(rule)
            for d, v in rule.get("bonus", {}).items():
                flavor[d] += v
    return flavor, triggered


def score_cup(flavor, triggered, bands):
    score = 60
    worst_dim, worst_dev = None, 0
    for d in DIMS:
        lo, hi = bands[d]
        v = flavor[d]
        if lo <= v <= hi:
            score += 6
        else:
            dev = (lo - v) if v < lo else (v - hi)
            score -= 5 * dev
            if dev > worst_dev:
                worst_dim, worst_dev = d, dev
    for rule in triggered:
        score += rule["score"]
    return max(0, min(100, score)), worst_dim


def match_recipe(cup, recipes):
    cup_top = set(t["id"] for t in cup["toppings"])
    near_hint = None
    for r in recipes:
        miss = []
        if r["base"] != cup["base"]["id"]:
            miss.append("茶底")
        if r["milk"] != cup["milk"]["id"]:
            miss.append("奶基")
        if set(r["toppings"]) != cup_top:
            miss.append("小料")
        sugar_ok = r["sugar"][0] <= cup["sugar"]["value"] <= r["sugar"][1]
        if not miss and sugar_ok:
            return r, None
        if not miss and not sugar_ok:
            near_hint = "sugar"
        elif len(miss) == 1 and sugar_ok and near_hint is None:
            near_hint = miss[0]
    return None, near_hint


def grade_text(score):
    if score >= 80:
        return "◎ 优秀！"
    if score >= 60:
        return "○ 不错，但还称不上招牌。"
    if score >= 40:
        return "△ 平庸……大概会无人问津。"
    return "✗ 翻车了！"


# ---------------------------------------------------------------- 市场检验（§6.4）

def run_market_tests(state):
    """日结算：每个在测配方揭晓一天评分，满 3 天定级"""
    done = []
    for t in state["tests"]:
        day_score = max(0, min(100, t["quality"] + random.randint(-8, 8)))
        t["scores"].append(day_score)
        n = len(t["scores"])
        print(f"   📊 《{t['name']}》市场检验 第{n}天：{day_score} 分")
        if n >= 3:
            avg = sum(t["scores"]) / 3
            if avg >= 88:
                tier, price = "爆款", 18
            elif avg >= 78:
                tier, price = "招牌", 15
            elif avg >= 62:
                tier, price = "普通", 12
            else:
                tier, price = "滞销", 0
            if tier == "滞销":
                print(f"   💀 《{t['name']}》检验均分 {avg:.0f}，滞销下架……（返还 3 灵感点）")
                state["buzz"] += 0  # 滞销不产话题，仅止损
                t["refund"] = 3
            else:
                print(f"   🏆 《{t['name']}》检验定级：【{tier}】 建议售价 ¥{price}")
                state["menu"].append({"name": t["name"], "tier": tier, "price": price})
            done.append(t)
    refund = sum(t.get("refund", 0) for t in done)
    state["tests"] = [t for t in state["tests"] if t not in done]
    return refund


def end_day(state):
    """收工 → 白天营业模拟 → 计算次日灵感预算"""
    print(f"\n🌙 打烊。第 {state['day']} 天结束——白天营业结算：")
    refund = run_market_tests(state)
    dark_orders = min(len(state["dark_menu"]), 3)
    if dark_orders:
        state["buzz"] += dark_orders
        print(f"   🕶️ 黑暗菜单成交 {dark_orders} 单（猎奇顾客），话题度 +{dark_orders}")
    state["day"] += 1
    insp = INSP_BASE + 2 * len(state["menu"]) + state["buzz"] + refund
    print(f"   ☀️ 第 {state['day']} 天开业。灵感预算 = 基础{INSP_BASE}"
          f" + 菜单加成{2 * len(state['menu'])} + 话题度{state['buzz']}"
          + (f" + 返还{refund}" if refund else "") + f" = {insp}")
    state["buzz"] = 0
    save_state(state)
    return insp


# ---------------------------------------------------------------- 交互

def pick(prompt, options):
    for i, o in enumerate(options, 1):
        print(f"  {i}. {o}")
    while True:
        s = input(prompt).strip().lower()
        if s == "q":
            sys.exit(0)
        if s.isdigit() and 1 <= int(s) <= len(options):
            return int(s) - 1
        print("  输入编号即可（q 退出）")


def pick_toppings(toppings):
    print("  0. 不加小料")
    for i, t in enumerate(toppings, 1):
        print(f"  {i}. {t['name']}")
    while True:
        s = input("选小料（最多 2 种，逗号分隔）> ").strip().lower()
        if s == "q":
            sys.exit(0)
        if s in ("", "0"):
            return []
        try:
            idx = sorted(set(int(x) for x in s.replace("，", ",").split(",")))
        except ValueError:
            print("  格式：1 或 1,3")
            continue
        if all(1 <= i <= len(toppings) for i in idx) and len(idx) <= 2:
            return [toppings[i - 1] for i in idx]
        print("  最多 2 种，编号要在范围内哦")


def show_book(recipes, darks, state):
    print(f"\n📖 配方图鉴（{len(state['discovered'])}/{len(recipes)}）")
    for r in recipes:
        if r["id"] in state["discovered"]:
            print(f"  ★ [{r['tier']}] {r['name']} —— {r['desc']}")
        else:
            print(f"  ？ [{r['tier']}] ？？？")
    print(f"🕶️ 黑暗传说（{len(state['dark_discovered'])}/{len(darks)}）")
    for r in darks:
        if r["id"] in state["dark_discovered"]:
            print(f"  💀 {r['name']} —— {r['desc']}")
        else:
            print(f"  ？ ？？？")
    print()


def show_status(state, ing):
    all_items = ing["bases"] + ing["milks"] + ing["toppings"]
    names = {i["id"]: i["name"] for i in all_items}
    print(f"\n📋 第 {state['day']} 天 | 话题度 {state['buzz']}")
    if state["menu"]:
        print("  菜单：" + "；".join(f"《{m['name']}》[{m['tier']}]¥{m['price']}" for m in state["menu"]))
    if state["tests"]:
        print("  检验中：" + "；".join(f"《{t['name']}》第{len(t['scores'])}/3天" for t in state["tests"]))
    if state["dark_menu"]:
        print("  黑暗菜单：" + "、".join(state["dark_menu"]))
    lv = [f"{names[k]}Lv{level_of(v)}" for k, v in sorted(state["xp"].items()) if level_of(v) >= 2]
    if lv:
        print("  熟练度（Lv2+）：" + "、".join(lv))
    print()


def unlocked(items, day):
    return [i for i in items if i.get("unlock_day", 1) <= day]


# ---------------------------------------------------------------- 主循环

def craft(state, ing, recipes, darks):
    day = state["day"]
    print("\n【茶底】")
    bases = unlocked(ing["bases"], day)
    base = bases[pick("选茶底 > ", [b["name"] for b in bases])]
    print("\n【奶基】")
    milks = unlocked(ing["milks"], day)
    milk = milks[pick("选奶基 > ", [m["name"] for m in milks])]
    print("\n【小料】")
    tops = pick_toppings(unlocked(ing["toppings"], day))
    print("\n【糖度】")
    sugar = ing["sugar_levels"][pick("选糖度 > ", [s["name"] for s in ing["sugar_levels"]])]

    cup = {"base": base, "milk": milk, "toppings": tops, "sugar": sugar}
    names = "、".join([base["name"], milk["name"]] + [t["name"] for t in tops])
    print(f"\n🥤 摇匀……试喝：{names}（{sugar['name']}）")
    print("   " + "-" * 36)

    flavor, triggered = compute_flavor(cup, ing, state)
    for rule in triggered:
        mark = "✨" if rule["type"] == "synergy" else "💥"
        print(f"   {mark} {rule['note']}")

    hit, near = match_recipe(cup, recipes)
    dark_hit, dark_near = match_recipe(cup, darks)

    if hit:
        if hit["id"] in state["discovered"]:
            print(f"   ……这不就是你的《{hit['name']}》嘛，味道稳定。")
        else:
            state["discovered"].append(hit["id"])
            state["menu"].append({"name": hit["name"], "tier": hit["tier"], "price": hit["price"]})
            print("\n   ★★★ 传说配方诞生！ ★★★")
            print(f"   《{hit['name']}》 [{hit['tier']}] ¥{hit['price']} 免检直接上架！")
            print(f"   “{hit['desc']}”")
    elif dark_hit:
        if dark_hit["id"] in state["dark_discovered"]:
            print(f"   ……又做了一杯《{dark_hit['name']}》，何苦呢。")
        else:
            state["dark_discovered"].append(dark_hit["id"])
            state["dark_menu"].append(dark_hit["name"])
            state["buzz"] += dark_hit["buzz"]
            print("\n   💀💀💀 黑暗传说降临！ 💀💀💀")
            print(f"   《{dark_hit['name']}》 —— {dark_hit['desc']}")
            print(f"   全网震惊，话题度 +{dark_hit['buzz']}！已挂上黑暗菜单。")
    else:
        score, worst_dim = score_cup(flavor, triggered, ing["balance_bands"])
        if worst_dim:
            hi = ing["balance_bands"][worst_dim][1]
            text = FEEDBACK_HIGH[worst_dim] if flavor[worst_dim] > hi else FEEDBACK_LOW[worst_dim]
            print(f"   💬 {text}")
        else:
            print("   💬 挺平衡的一杯，就是……少了点记忆点。")
        if near == "sugar":
            print("   🔍 配料没问题，但甜度好像不太对……")
        elif near:
            print(f"   🔍 隐约有个熟悉的影子……换一种【{near}】试试？")
        if 75 <= score < 80:
            print("   🔍 就差一口气……换个小料或糖度微调下？")
        if dark_near:
            print("   🌫️ 你感觉自己正在接近某种……不可名状的东西。")
        print(f"   {grade_text(score)}（品质分 {score}）")

        if score >= 80:
            name = input("   ✍️ 够格上架！给它起个名字（回车放弃）> ").strip()
            if name:
                state["tests"].append({"name": name, "quality": score, "scores": []})
                print(f"   🧪 《{name}》进入 3 天市场检验期，每晚结算揭晓评分！")
        elif score < 40:
            dm_name = f"谜之特调 #{len(state['dark_menu']) + 1}"
            state["dark_menu"].append(dm_name)
            state["buzz"] += 1
            print(f"   🕶️ 已挂上黑暗菜单：《{dm_name}》，话题度 +1（总会有猎奇的人……）")

    for msg in gain_xp(state, [base, milk] + tops):
        print(f"   {msg}")
    save_state(state)


def main():
    random.seed()
    ing, recipes, darks = load_data()
    state = load_state()
    if "--day" in sys.argv:
        state["day"] = int(sys.argv[sys.argv.index("--day") + 1])

    insp = INSP_BASE + 2 * len(state["menu"])
    print("=" * 48)
    print("🧋 奶茶研发室 v0.2 · 灵感点/熟练度/市场检验/黑暗料理")
    print("   打烊了。今晚，调一杯没人喝过的东西。")
    print("   指令：回车=试做(-2灵感)  b=图鉴  s=状态  e=收工  q=退出")
    print("=" * 48)

    while True:
        print(f"\n—— 第 {state['day']} 天 · 夜 —— 灵感点 {insp} | 话题度 {state['buzz']}")
        if insp < ATTEMPT_COST:
            print("💤 灵感枯竭，只能收工了……")
            insp = end_day(state)
            continue
        s = input("> ").strip().lower()
        if s == "q":
            break
        if s == "b":
            show_book(recipes, darks, state)
            continue
        if s == "s":
            show_status(state, ing)
            continue
        if s == "e":
            insp = end_day(state)
            continue
        insp -= ATTEMPT_COST
        craft(state, ing, recipes, darks)

    save_state(state)
    print(f"\n进度已存档（{SAVE_FILE.name}）。图鉴 {len(state['discovered'])}/{len(recipes)}，"
          f"黑暗传说 {len(state['dark_discovered'])}/{len(darks)}。下次打烊见！")


if __name__ == "__main__":
    main()
