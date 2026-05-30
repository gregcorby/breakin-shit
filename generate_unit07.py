#!/usr/bin/env python3
"""
Humanoid Unit-07 -> 3D model generator.

Procedurally reconstructs the "HUMANOID UNIT-07" reference sheet as a watertight-ish
Wavefront OBJ + MTL you can import into Blender, Unity, Godot, three.js, etc.

Spec lifted straight from the reference sheet:
    MODEL : 07
    HEIGHT: 6'2" (187.9 cm)
    WEIGHT: 72 kg
    VIBES : TIRED
    AI    : OVERTHINKER
    Don't forget: cables (neck go brrr), round joints, 5 fingers,
                  existential dread, silent judgment.

No third-party deps. Just: python3 generate_unit07.py
"""

import math
import os

# ---------------------------------------------------------------------------
# Spec / proportions (metres, feet on the floor at y = 0)
# ---------------------------------------------------------------------------
HEIGHT_M = 1.879  # 6'2"

# ---------------------------------------------------------------------------
# Geometry buffers
#   V      : list of (x, y, z)
#   FACES  : list of (material_name, (i0, i1, i2, ...))  -- indices are 0-based here,
#            converted to 1-based on write.
# ---------------------------------------------------------------------------
V = []
FACES = []


# ---------------------------------------------------------------------------
# Linear-algebra helpers (3-vectors, 3x3 row-major matrices)
# ---------------------------------------------------------------------------
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def length(a):
    return math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])


def normalize(a):
    n = length(a)
    if n < 1e-12:
        return (0.0, 0.0, 0.0)
    return (a[0] / n, a[1] / n, a[2] / n)


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def euler_matrix(rx, ry, rz):
    """Row-major 3x3 = Rz * Ry * Rx (angles in radians)."""
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    # Rx
    Rx = (1, 0, 0, 0, cx, -sx, 0, sx, cx)
    Ry = (cy, 0, sy, 0, 1, 0, -sy, 0, cy)
    Rz = (cz, -sz, 0, sz, cz, 0, 0, 0, 1)
    return matmul(Rz, matmul(Ry, Rx))


def matmul(a, b):
    r = [0.0] * 9
    for i in range(3):
        for j in range(3):
            r[i * 3 + j] = (
                a[i * 3 + 0] * b[0 * 3 + j]
                + a[i * 3 + 1] * b[1 * 3 + j]
                + a[i * 3 + 2] * b[2 * 3 + j]
            )
    return tuple(r)


def align_to(direction):
    """Rotation matrix mapping +Y onto `direction` (Rodrigues)."""
    b = normalize(direction)
    a = (0.0, 1.0, 0.0)
    v = cross(a, b)
    c = dot(a, b)
    if c > 1 - 1e-9:
        return (1, 0, 0, 0, 1, 0, 0, 0, 1)
    if c < -1 + 1e-9:
        # 180 deg about X
        return (1, 0, 0, 0, -1, 0, 0, 0, -1)
    vx = (
        0, -v[2], v[1],
        v[2], 0, -v[0],
        -v[1], v[0], 0,
    )
    vx2 = matmul(vx, vx)
    k = 1.0 / (1.0 + c)
    return tuple(
        (1 if i in (0, 4, 8) else 0) + vx[i] + vx2[i] * k for i in range(9)
    )


def make_tf(scale=(1, 1, 1), R=None, t=(0, 0, 0)):
    """Build a point-transform: scale -> rotate -> translate."""
    sxv, syv, szv = scale
    tx, ty, tz = t

    def tf(p):
        x, y, z = p[0] * sxv, p[1] * syv, p[2] * szv
        if R is not None:
            x, y, z = (
                R[0] * x + R[1] * y + R[2] * z,
                R[3] * x + R[4] * y + R[5] * z,
                R[6] * x + R[7] * y + R[8] * z,
            )
        return (x + tx, y + ty, z + tz)

    return tf


def emit(verts, faces, mtl, tf):
    """Append a transformed primitive to the global buffers."""
    base = len(V)
    for p in verts:
        V.append(tf(p))
    for f in faces:
        FACES.append((mtl, tuple(base + i for i in f)))


# ---------------------------------------------------------------------------
# Primitive builders (local space) -> (verts, faces)
# ---------------------------------------------------------------------------
def uv_sphere(radius=1.0, segs=20, rings=14):
    verts = []
    faces = []
    for r in range(rings + 1):
        phi = math.pi * r / rings  # 0..pi (north->south)
        y = math.cos(phi) * radius
        rad = math.sin(phi) * radius
        for s in range(segs + 1):
            th = 2 * math.pi * s / segs
            verts.append((math.cos(th) * rad, y, math.sin(th) * rad))
    row = segs + 1
    for r in range(rings):
        for s in range(segs):
            a = r * row + s
            b = a + 1
            c = a + row
            d = c + 1
            if r != 0:
                faces.append((a, c, b))
            if r != rings - 1:
                faces.append((b, c, d))
    return verts, faces


def cylinder_y(r0=1.0, r1=1.0, h=1.0, segs=20, caps=True):
    """Cylinder/cone from y=0 (radius r0) to y=h (radius r1)."""
    verts = []
    faces = []
    for s in range(segs + 1):
        th = 2 * math.pi * s / segs
        c, sn = math.cos(th), math.sin(th)
        verts.append((c * r0, 0.0, sn * r0))
        verts.append((c * r1, h, sn * r1))
    for s in range(segs):
        a = s * 2
        b = a + 1
        cc = a + 2
        d = a + 3
        faces.append((a, cc, b))
        faces.append((b, cc, d))
    if caps:
        cb = len(verts)
        verts.append((0.0, 0.0, 0.0))
        ct = len(verts)
        verts.append((0.0, h, 0.0))
        for s in range(segs):
            a = s * 2
            cc = a + 2
            faces.append((cb, a, cc))
            b = a + 1
            d = a + 3
            faces.append((ct, d, b))
    return verts, faces


def box(sx=1.0, sy=1.0, sz=1.0):
    """Axis-aligned box centred on origin."""
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    verts = [
        (-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
        (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz),
    ]
    faces = [
        (0, 1, 2), (0, 2, 3),  # back
        (5, 4, 7), (5, 7, 6),  # front
        (4, 0, 3), (4, 3, 7),  # left
        (1, 5, 6), (1, 6, 2),  # right
        (3, 2, 6), (3, 6, 7),  # top
        (4, 5, 1), (4, 1, 0),  # bottom
    ]
    return verts, faces


def torus(R=1.0, r=0.3, segs=24, sides=14):
    verts = []
    faces = []
    for i in range(segs):
        u = 2 * math.pi * i / segs
        cu, su = math.cos(u), math.sin(u)
        for j in range(sides):
            v = 2 * math.pi * j / sides
            cv, sv = math.cos(v), math.sin(v)
            x = (R + r * cv) * cu
            y = r * sv
            z = (R + r * cv) * su
            verts.append((x, y, z))
    for i in range(segs):
        for j in range(sides):
            a = i * sides + j
            b = i * sides + (j + 1) % sides
            c = ((i + 1) % segs) * sides + j
            d = ((i + 1) % segs) * sides + (j + 1) % sides
            faces.append((a, c, b))
            faces.append((b, c, d))
    return verts, faces


# ---------------------------------------------------------------------------
# High-level part helpers
# ---------------------------------------------------------------------------
def ball(center, radius, mtl, scale=(1, 1, 1)):
    verts, faces = uv_sphere(radius, segs=20, rings=14)
    emit(verts, faces, mtl, make_tf(scale=scale, t=center))


def segment(p0, p1, r0, r1, mtl, segs=18):
    """Tapered cylinder (a limb bone) between two points."""
    d = sub(p1, p0)
    h = length(d)
    if h < 1e-9:
        return
    R = align_to(d)
    verts, faces = cylinder_y(r0, r1, h, segs=segs)
    emit(verts, faces, mtl, make_tf(R=R, t=p0))


def tube(p0, p1, r, mtl, segs=10):
    segment(p0, p1, r, r, mtl, segs=segs)


def boxpart(center, size, mtl, rot=(0, 0, 0)):
    verts, faces = box(*size)
    R = euler_matrix(*rot)
    emit(verts, faces, mtl, make_tf(R=R, t=center))


# ---------------------------------------------------------------------------
# Materials
# ---------------------------------------------------------------------------
MATS = {
    # name        : (diffuse rgb,            emissive rgb,        spec, shininess)
    "body_light":  ((0.55, 0.57, 0.59), (0, 0, 0),           (0.30, 0.30, 0.32), 40),
    "body_mid":    ((0.42, 0.44, 0.46), (0, 0, 0),           (0.25, 0.25, 0.27), 35),
    "body_dark":   ((0.14, 0.15, 0.16), (0, 0, 0),           (0.20, 0.20, 0.22), 60),
    "accent_cyan": ((0.10, 0.66, 0.87), (0.02, 0.16, 0.22),  (0.40, 0.55, 0.60), 80),
    "core_glow":   ((0.15, 0.78, 1.00), (0.20, 0.85, 1.00),  (0.50, 0.60, 0.65), 90),
    "eye_glow":    ((0.05, 0.05, 0.07), (0.10, 0.55, 0.75),  (0.30, 0.40, 0.45), 90),
}


# ---------------------------------------------------------------------------
# Build Unit-07
# ---------------------------------------------------------------------------
def build():
    # --- key heights (m) ---
    y_head_c = 1.74
    head_ry = 0.135  # vertical half-height of head
    y_neck_top = 1.585
    y_neck_bot = 1.515
    y_shoulder = 1.485
    sh_x = 0.205     # shoulder half-width (ball-joint centre)
    y_chest = 1.42
    y_abdomen = 1.20
    y_pelvis = 1.045
    hip_x = 0.105
    y_hip = 1.00
    y_knee = 0.535
    y_ankle = 0.085
    y_elbow = 1.205
    y_wrist = 0.935

    # ====================================================================
    # HEAD  (smooth ovoid + dark face panel + glowing eyes + ear cans)
    # ====================================================================
    ball((0, y_head_c, 0), 1.0, "body_light",
         scale=(0.145, head_ry, 0.155))

    # face panel: a slightly inset dark plate on the +Z (front) side
    boxpart((0, y_head_c - 0.005, 0.138), (0.165, 0.20, 0.045),
            "body_dark")
    # two round glowing eyes
    for sx in (-1, 1):
        ball((sx * 0.045, y_head_c + 0.015, 0.163), 0.018, "eye_glow",
             scale=(1.0, 1.4, 0.6))

    # ear "headphones": round can + accent ring on each side (round joints!)
    for sx in (-1, 1):
        d = (sx, 0.0, 0.0)
        R = align_to(d)
        # outer can
        verts, faces = cylinder_y(0.052, 0.052, 0.030, segs=22)
        emit(verts, faces, "body_mid",
             make_tf(R=R, t=(sx * 0.135, y_head_c - 0.005, 0.0)))
        # cyan accent ring around the can
        tv, tf_ = torus(0.052, 0.012, segs=24, sides=10)
        emit(tv, tf_, "accent_cyan",
             make_tf(R=R, t=(sx * 0.150, y_head_c - 0.005, 0.0)))
        # dark hub
        ball((sx * 0.150, y_head_c - 0.005, 0.0), 0.024, "body_dark")

    # ====================================================================
    # NECK  +  CABLES (neck go brrr)
    # ====================================================================
    segment((0, y_neck_bot, 0), (0, y_neck_top, 0), 0.052, 0.046,
            "body_dark", segs=18)
    # bundle of cables looping from skull base into the upper back
    cable_anchors = [
        (-0.035, 0.02), (0.0, 0.03), (0.035, 0.02),
        (-0.020, -0.025), (0.020, -0.025),
    ]
    for (cx, cz) in cable_anchors:
        top = (cx, y_neck_top + 0.02, cz - 0.045)
        mid = (cx * 1.4, (y_neck_top + y_neck_bot) / 2, cz - 0.075)
        bot = (cx * 1.2, y_neck_bot - 0.02, cz - 0.05)
        tube(top, mid, 0.0085, "accent_cyan", segs=8)
        tube(mid, bot, 0.0085, "accent_cyan", segs=8)

    # ====================================================================
    # TORSO  (chest plate, glowing core, segmented abdomen, pelvis)
    # ====================================================================
    # upper chest block
    boxpart((0, y_chest, 0.0), (0.34, 0.20, 0.18), "body_light")
    # chest bevels -> shoulders
    for sx in (-1, 1):
        segment((sx * 0.14, y_chest + 0.07, 0), (sx * sh_x, y_shoulder, 0),
                0.055, 0.05, "body_mid", segs=14)
    # glowing reactor core in the sternum
    ball((0, y_chest + 0.01, 0.10), 0.035, "core_glow",
         scale=(1.0, 1.0, 0.7))
    tv, tf_ = torus(0.05, 0.012, segs=24, sides=10)
    emit(tv, tf_, "accent_cyan",
         make_tf(R=euler_matrix(math.pi / 2, 0, 0),
                 t=(0, y_chest + 0.01, 0.095)))

    # segmented abdomen (3 stacked ab plates, tapering)
    ab_ys = [1.345, 1.285, 1.225]
    ab_w = [0.27, 0.245, 0.225]
    for y, w in zip(ab_ys, ab_w):
        boxpart((0, y, 0.0), (w, 0.05, 0.15), "body_mid")
        # dark gap rings between plates
        boxpart((0, y - 0.03, 0.0), (w * 0.8, 0.012, 0.13), "body_dark")
    # spine cable down the front gaps
    tube((0, 1.37, 0.075), (0, 1.20, 0.07), 0.01, "accent_cyan", segs=8)

    # pelvis
    boxpart((0, y_pelvis, 0.0), (0.26, 0.13, 0.17), "body_light")
    boxpart((0, y_pelvis - 0.02, 0.0), (0.20, 0.06, 0.14), "body_dark")

    # ====================================================================
    # ARMS  (ball shoulder/elbow/wrist joints + tapered bones)  x2
    # ====================================================================
    for sx in (-1, 1):
        sh = (sx * sh_x, y_shoulder, 0.0)
        # arm hangs slightly out from the body
        el = (sx * (sh_x + 0.045), y_elbow, 0.01)
        wr = (sx * (sh_x + 0.075), y_wrist, 0.02)

        ball(sh, 0.062, "body_dark")                 # shoulder joint
        segment(sh, el, 0.05, 0.042, "body_light")   # upper arm
        ball(el, 0.05, "body_dark")                  # elbow joint
        segment(el, wr, 0.042, 0.034, "body_mid")    # forearm
        ball(wr, 0.04, "body_dark")                  # wrist joint
        # cyan tricep cable
        tube((sh[0], sh[1] - 0.02, -0.03),
             (el[0], el[1] + 0.02, -0.02), 0.008, "accent_cyan", segs=8)

        build_hand(wr, sx)

    # ====================================================================
    # LEGS  (ball hip/knee/ankle joints + tapered bones + feet)  x2
    # ====================================================================
    for sx in (-1, 1):
        hip = (sx * hip_x, y_hip, 0.0)
        kn = (sx * hip_x, y_knee, 0.015)
        an = (sx * hip_x, y_ankle, 0.0)

        ball(hip, 0.072, "body_dark")                # hip joint
        segment(hip, kn, 0.075, 0.055, "body_light") # thigh
        ball(kn, 0.058, "body_dark")                 # knee joint
        segment(kn, an, 0.055, 0.042, "body_mid")    # shin
        ball(an, 0.044, "body_dark")                 # ankle joint
        # cyan hamstring cable
        tube((hip[0], hip[1] - 0.03, -0.04),
             (kn[0], kn[1] + 0.03, -0.03), 0.009, "accent_cyan", segs=8)

        build_foot(an, sx)


def build_hand(wrist, sx):
    """Palm + 5 fingers (3 segments each). Fingers point downward, thumb aside."""
    mid = "body_mid"
    dark = "body_dark"
    # palm
    palm_c = (wrist[0], wrist[1] - 0.05, wrist[2] + 0.005)
    boxpart(palm_c, (0.058, 0.075, 0.028), mid)

    finger_len = [0.052, 0.058, 0.054, 0.046]   # index..pinky
    spread = [-0.021, -0.007, 0.007, 0.021]
    for k in range(4):
        basex = palm_c[0] + spread[k]
        top = (basex, palm_c[1] - 0.04, palm_c[2] + 0.006)
        fl = finger_len[k]
        # three knuckle segments
        p = top
        for seg_i in range(3):
            slen = fl * (0.42 if seg_i == 0 else 0.32 if seg_i == 1 else 0.26)
            nxt = (p[0], p[1] - slen, p[2] + 0.002)
            r = 0.0085 - seg_i * 0.0015
            segment(p, nxt, r + 0.001, r, mid, segs=8)
            ball(nxt, r, dark)
            p = nxt
    # thumb (off to the inner side, angled)
    tb = (palm_c[0] - sx * 0.03, palm_c[1] + 0.02, palm_c[2] + 0.01)
    tb_end = (palm_c[0] - sx * 0.055, palm_c[1] - 0.02, palm_c[2] + 0.02)
    segment(tb, tb_end, 0.011, 0.008, mid, segs=8)
    ball(tb_end, 0.008, dark)


def build_foot(ankle, sx):
    """Wedge foot pointing +Z (forward)."""
    light = "body_light"
    dark = "body_dark"
    # heel block
    boxpart((ankle[0], 0.035, ankle[2] + 0.02), (0.085, 0.07, 0.10), light)
    # toe ramp
    boxpart((ankle[0], 0.022, ankle[2] + 0.12), (0.085, 0.044, 0.14), light)
    # sole
    boxpart((ankle[0], 0.006, ankle[2] + 0.07), (0.09, 0.014, 0.245), dark)


# ---------------------------------------------------------------------------
# Writers
# ---------------------------------------------------------------------------
def write_mtl(path):
    with open(path, "w") as f:
        f.write("# Humanoid Unit-07 materials\n")
        for name, (kd, ke, ks, ns) in MATS.items():
            f.write(f"\nnewmtl {name}\n")
            f.write(f"Kd {kd[0]:.3f} {kd[1]:.3f} {kd[2]:.3f}\n")
            f.write(f"Ka {kd[0]*0.2:.3f} {kd[1]*0.2:.3f} {kd[2]*0.2:.3f}\n")
            f.write(f"Ks {ks[0]:.3f} {ks[1]:.3f} {ks[2]:.3f}\n")
            f.write(f"Ke {ke[0]:.3f} {ke[1]:.3f} {ke[2]:.3f}\n")
            f.write(f"Ns {ns}\n")
            f.write("illum 2\nd 1.0\n")


def write_obj(path, mtl_name):
    # group consecutive faces by material to keep usemtl statements tidy
    with open(path, "w") as f:
        f.write("# Humanoid Unit-07 - procedurally generated from the reference sheet\n")
        f.write(f"# {len(V)} vertices, {len(FACES)} faces\n")
        f.write(f"mtllib {mtl_name}\n")
        f.write("o Unit-07\n")
        for x, y, z in V:
            f.write(f"v {x:.5f} {y:.5f} {z:.5f}\n")
        cur = None
        for mtl, idx in FACES:
            if mtl != cur:
                f.write(f"usemtl {mtl}\n")
                cur = mtl
            f.write("f " + " ".join(str(i + 1) for i in idx) + "\n")


def bounds():
    xs = [p[0] for p in V]
    ys = [p[1] for p in V]
    zs = [p[2] for p in V]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def main():
    build()
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "model")
    os.makedirs(out_dir, exist_ok=True)
    obj_path = os.path.join(out_dir, "unit07.obj")
    mtl_path = os.path.join(out_dir, "unit07.mtl")
    write_mtl(mtl_path)
    write_obj(obj_path, "unit07.mtl")

    (xmn, xmx), (ymn, ymx), (zmn, zmx) = bounds()
    print("Humanoid Unit-07 generated.")
    print(f"  vertices : {len(V)}")
    print(f"  faces    : {len(FACES)}")
    print(f"  height   : {ymx - ymn:.3f} m  (target {HEIGHT_M} m)")
    print(f"  width    : {xmx - xmn:.3f} m")
    print(f"  depth    : {zmx - zmn:.3f} m")
    print(f"  -> {obj_path}")
    print(f"  -> {mtl_path}")


if __name__ == "__main__":
    main()
