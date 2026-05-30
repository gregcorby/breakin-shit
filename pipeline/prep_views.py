#!/usr/bin/env python3
"""
Split the Unit-07 reference sheet into clean per-view images for Tripo's
multiview mode (or just to grab a clean single front view).

The sheet's top band is a turnaround row: FRONT, 3/4 FRONT, SIDE, 3/4 BACK, BACK.
This auto-detects the figures in that band by scanning for vertical whitespace
gaps, then writes cropped, white-background-trimmed, square-padded PNGs.

  python3 prep_views.py reference/unit07_sheet.png
  python3 prep_views.py reference/unit07_sheet.png --band 0.0 0.34 --bg-to-white

Outputs into reference/views/:  front.png  side.png  back.png  (+ all_<n>.png)

Tune with --band TOP BOTTOM (fractions of height) if auto-detection grabs the
wrong row, and inspect the printed column splits.
"""
import argparse
import os
import sys

from PIL import Image


def near_white(px, thresh):
    return px[0] >= thresh and px[1] >= thresh and px[2] >= thresh


def column_is_blank(img, x, thresh, frac=0.985):
    w, h = img.size
    px = img.load()
    blank = sum(1 for y in range(h) if near_white(px[x, y], thresh))
    return blank / h >= frac


def find_columns(img, thresh, min_gap):
    """Return [(x0, x1), ...] spans of non-blank content."""
    w, _ = img.size
    blanks = [column_is_blank(img, x, thresh) for x in range(w)]
    spans = []
    x = 0
    while x < w:
        if not blanks[x]:
            start = x
            while x < w and not blanks[x]:
                x += 1
            spans.append((start, x))
        x += 1
    # merge spans separated by gaps smaller than min_gap
    merged = []
    for s in spans:
        if merged and s[0] - merged[-1][1] < min_gap:
            merged[-1] = (merged[-1][0], s[1])
        else:
            merged.append(list(s))
    # drop slivers
    return [tuple(m) for m in merged if (m[1] - m[0]) > min_gap]


def trim_and_square(crop, thresh, bg_to_white, pad=0.08):
    """Trim white margins, then pad to a centered square."""
    rgb = crop.convert("RGB")
    px = rgb.load()
    w, h = rgb.size
    minx, miny, maxx, maxy = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            if not near_white(px[x, y], thresh):
                minx = min(minx, x); miny = min(miny, y)
                maxx = max(maxx, x); maxy = max(maxy, y)
    if maxx <= minx or maxy <= miny:
        return None
    crop = crop.crop((minx, miny, maxx + 1, maxy + 1))
    cw, ch = crop.size
    side = int(max(cw, ch) * (1 + pad))
    bg = (255, 255, 255) if bg_to_white else (255, 255, 255)
    canvas = Image.new("RGB", (side, side), bg)
    canvas.paste(crop.convert("RGB"), ((side - cw) // 2, (side - ch) // 2))
    return canvas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet")
    ap.add_argument("--band", nargs=2, type=float, default=[0.0, 0.34],
                    metavar=("TOP", "BOTTOM"),
                    help="vertical fraction of the sheet holding the turnaround row")
    ap.add_argument("--thresh", type=int, default=232,
                    help="0-255; pixels brighter than this count as background")
    ap.add_argument("--bg-to-white", action="store_true",
                    help="flatten near-white background to pure white")
    args = ap.parse_args()

    if not os.path.isfile(args.sheet):
        sys.exit(f"ERROR: sheet not found: {args.sheet}")

    img = Image.open(args.sheet).convert("RGB")
    W, H = img.size
    top, bot = int(H * args.band[0]), int(H * args.band[1])
    band = img.crop((0, top, W, bot))
    print(f"sheet {W}x{H}; band rows {top}-{bot}")

    min_gap = max(8, W // 60)
    spans = find_columns(band, args.thresh, min_gap)
    print(f"detected {len(spans)} figures in band: {spans}")

    out = os.path.join(os.path.dirname(args.sheet), "views")
    os.makedirs(out, exist_ok=True)

    figs = []
    for i, (x0, x1) in enumerate(spans):
        sq = trim_and_square(band.crop((x0, 0, x1, bot - top)),
                             args.thresh, args.bg_to_white)
        if sq is None:
            continue
        p = os.path.join(out, f"all_{i}.png")
        sq.save(p)
        figs.append(p)
        print(f"  wrote {p}")

    # Map turnaround order -> Tripo views. For 5 figures:
    # 0 FRONT, 1 3/4 FRONT, 2 SIDE, 3 3/4 BACK, 4 BACK
    label = {}
    if len(figs) >= 5:
        label = {"front": figs[0], "side": figs[2], "back": figs[4]}
    elif len(figs) >= 3:
        label = {"front": figs[0], "side": figs[len(figs)//2], "back": figs[-1]}
    elif figs:
        label = {"front": figs[0]}
    for name, src in label.items():
        dst = os.path.join(out, f"{name}.png")
        Image.open(src).save(dst)
        print(f"  -> {name}: {dst}")

    print("\nNext:")
    if "front" in label and "back" in label:
        print("  python3 pipeline/tripo_image_to_3d.py \\")
        print(f"    --front {label.get('front')} \\")
        print(f"    --left  {label.get('side')} \\")
        print(f"    --back  {label.get('back')} --also obj,fbx")
    else:
        print(f"  python3 pipeline/tripo_image_to_3d.py {label.get('front','reference/front.png')} --also obj,fbx")


if __name__ == "__main__":
    main()
