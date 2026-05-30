#!/usr/bin/env python3
"""
Tiny pure-Python rasterizer to preview the generated Unit-07 model.
Z-buffered flat-shaded triangles, orthographic. Writes PNG via zlib (stdlib).
Run: python3 render_preview.py
"""
import math, struct, zlib, os
import generate_unit07 as g

W = H = 700
LIGHT = g.normalize((-0.4, 0.55, 0.8))

# material base colours (sRGB-ish 0..1) for shading
COL = {
    "body_light": (0.62, 0.64, 0.66),
    "body_mid":   (0.47, 0.49, 0.51),
    "body_dark":  (0.17, 0.18, 0.19),
    "accent_cyan":(0.12, 0.70, 0.92),
    "core_glow":  (0.25, 0.85, 1.00),
    "eye_glow":   (0.20, 0.75, 1.00),
}
EMISSIVE = {"core_glow": 0.7, "eye_glow": 0.65, "accent_cyan": 0.15}


def rot_y(p, a):
    c, s = math.cos(a), math.sin(a)
    return (c * p[0] + s * p[2], p[1], -s * p[0] + c * p[2])


def render(angle, fname):
    g.V.clear(); g.FACES.clear()
    g.build()
    verts = g.V; faces = g.FACES
    # rotate + find bounds
    pts = [rot_y(p, angle) for p in verts]
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    cx = (min(xs) + max(xs)) / 2; cy = (min(ys) + max(ys)) / 2
    span = max(max(xs) - min(xs), max(ys) - min(ys)) * 1.12
    scale = H / span

    def proj(p):
        sx = (p[0] - cx) * scale + W / 2
        sy = H / 2 - (p[1] - cy) * scale
        return sx, sy, p[2]

    # background gradient
    img = bytearray(W * H * 3)
    for y in range(H):
        t = y / H
        r = int(22 + t * 10); gg = int(24 + t * 12); b = int(30 + t * 16)
        for x in range(W):
            o = (y * W + x) * 3
            img[o] = r; img[o+1] = gg; img[o+2] = b
    zbuf = [-1e9] * (W * H)

    for mtl, idx in faces:
        base = COL.get(mtl, (0.6, 0.6, 0.6))
        em = EMISSIVE.get(mtl, 0.0)
        tri = idx[:3]
        a, b, c = (verts[i] for i in tri)
        # rotate the actual 3D points for normal + projection
        ra, rb, rc = rot_y(a, angle), rot_y(b, angle), rot_y(c, angle)
        n = g.normalize(g.cross(g.sub(rb, ra), g.sub(rc, ra)))
        if n[2] <= 0:  # back-face cull (viewing down -Z toward +Z)
            pass
        diff = max(0.0, g.dot(n, LIGHT))
        shade = 0.25 + 0.75 * diff
        col = tuple(min(1.0, base[k] * shade * (1 - em) + base[k] * em + em * 0.15)
                    for k in range(3))
        pa, pb, pc = proj(ra), proj(rb), proj(rc)
        raster(img, zbuf, pa, pb, pc, col)

    write_png(fname, img)
    print("wrote", fname)


def raster(img, zbuf, p0, p1, p2, col):
    x0, y0, z0 = p0; x1, y1, z1 = p1; x2, y2, z2 = p2
    minx = max(0, int(min(x0, x1, x2)))
    maxx = min(W - 1, int(max(x0, x1, x2)) + 1)
    miny = max(0, int(min(y0, y1, y2)))
    maxy = min(H - 1, int(max(y0, y1, y2)) + 1)
    area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
    if abs(area) < 1e-6:
        return
    inv = 1.0 / area
    R = int(col[0] * 255); G = int(col[1] * 255); B = int(col[2] * 255)
    for y in range(miny, maxy + 1):
        for x in range(minx, maxx + 1):
            px = x + 0.5; py = y + 0.5
            w0 = ((x1 - px) * (y2 - py) - (x2 - px) * (y1 - py)) * inv
            w1 = ((x2 - px) * (y0 - py) - (x0 - px) * (y2 - py)) * inv
            w2 = 1 - w0 - w1
            if w0 < 0 or w1 < 0 or w2 < 0:
                continue
            z = w0 * z0 + w1 * z1 + w2 * z2
            o = y * W + x
            if z > zbuf[o]:
                zbuf[o] = z
                d = o * 3
                img[d] = R; img[d+1] = G; img[d+2] = B


def write_png(path, rgb):
    def chunk(typ, data):
        c = struct.pack(">I", len(data)) + typ + data
        return c + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff)
    raw = bytearray()
    for y in range(H):
        raw.append(0)
        raw.extend(rgb[y * W * 3:(y + 1) * W * 3])
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(sig)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    out = os.path.dirname(os.path.abspath(__file__))
    render(0.0, os.path.join(out, "preview_front.png"))
    render(-0.6, os.path.join(out, "preview_34.png"))
    render(-math.pi / 2, os.path.join(out, "preview_side.png"))
