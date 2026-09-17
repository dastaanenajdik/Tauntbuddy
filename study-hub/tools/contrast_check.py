#!/usr/bin/env python3
"""
Contrast contract · TauntBuddy Study Hub
=========================================
Computes WCAG 2.x contrast ratios for every text/surface pair used in
css/*.css and fails if any pair drops below its threshold (7:1 for primary
body pairs, 4.5:1 for secondary pairs and worst-case photo scrims).

    python3 study-hub/tools/contrast_check.py
"""

import sys

def _channel(v):
    v /= 255
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

def lum(rgb):
    r, g, b = rgb
    return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b)

def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))

def ratio(fg, bg):
    l1, l2 = sorted([lum(fg), lum(bg)], reverse=True)
    return (l1 + 0.05) / (l2 + 0.05)

def blend(top, alpha, bottom):
    return tuple(round(alpha * t + (1 - alpha) * b) for t, b in zip(top, bottom))

PAIRS = [
    # (name, fg, bg, threshold)
    ("ink on card",            "1a140d", "fffdf7", 7.0),
    ("muted on card",          "5b5142", "fffdf7", 4.5),
    ("ink on card-soft",       "1a140d", "faf5ea", 7.0),
    ("on-navy on navy",        "ffffff", "14324e", 7.0),
    ("on-navy-muted on navy",  "c4d3e2", "14324e", 4.5),
    ("on-teal on teal",        "ffffff", "0b554c", 7.0),
    ("on-teal-muted on teal",  "c9eae3", "0b554c", 4.5),
    ("on-accent on accent",    "fff8f0", "8a3d0c", 7.0),
    ("accent-muted on accent", "f6dcc6", "8a3d0c", 4.5),
    ("on-gold on gold",        "241a04", "e3b23c", 7.0),
    ("on-ok on ok",            "ffffff", "145f3a", 7.0),
    ("ok-soft-ink on ok-soft", "12402a", "e2f2e8", 7.0),
    ("ink on chip/ghost",      "1a140d", "efe6d3", 7.0),
    ("ink on day-header",      "1a140d", "f6efe0", 7.0),
    ("muted on day-header",    "5b5142", "f6efe0", 4.5),
    ("kind-learn chip",        "1d3f77", "e3ecfa", 4.5),
    ("kind-practice chip",     "5b2d90", "f0e6fb", 4.5),
    ("kind-revision chip",     "8a4a0d", "fdeedd", 4.5),
    ("kind-review chip",       "0d5744", "dcf3ea", 4.5),
    ("kind-mock chip",         "8f2118", "fbdede", 4.5),
]

OVERLAYS = [
    ("white on scrim worst-case (0.70 over white photo)", "ffffff", blend(hx("0c1422"), 0.70, (255, 255, 255)), 4.5),
    ("lede on scrim worst-case (0.70 over white photo)",  "e8edf4", blend(hx("0c1422"), 0.70, (255, 255, 255)), 4.5),
    ("white on nav pill (12% white over navy)",           "ffffff", blend((255, 255, 255), 0.12, hx("14324e")), 4.5),
    ("white on btn.blank (16% white over navy)",          "ffffff", blend((255, 255, 255), 0.16, hx("14324e")), 4.5),
    ("on-dark chip text (16% white over navy scrim)",     "ffffff", blend((255, 255, 255), 0.16, hx("0c1422")), 4.5),
]

def main():
    failures = 0
    for name, fg, bg, need in PAIRS + OVERLAYS:
        bg_rgb = hx(bg) if isinstance(bg, str) else bg
        r = ratio(hx(fg), bg_rgb)
        ok = r >= need
        failures += 0 if ok else 1
        print(f"{'PASS' if ok else 'FAIL'}  {r:5.2f}:1 (need {need}:1)  {name}")
    print()
    if failures:
        print(f"{failures} contrast failure(s) ❌")
        return 1
    print("All contrast pairs clear their thresholds ✅")
    return 0

if __name__ == "__main__":
    sys.exit(main())
