# Humanoid Unit-07 — image → 3D model

Turn the **HUMANOID UNIT-07** reference sheet into a real, textured 3D mesh using
the [Tripo3D](https://platform.tripo3d.ai) image-to-3D API.

The reference is a 5-view turnaround (front / 3⁄4 front / side / 3⁄4 back / back),
which is ideal input: we split it into clean per-view images and feed Tripo's
**multiview** mode for a faithful result, then download GLB (+ optional OBJ/FBX).

> **Why an API and not local generation?** Faithfully reconstructing detailed
> concept art needs a real image-to-3D model. That requires a GPU and model
> weights; doing it well on CPU isn't feasible. Tripo runs the heavy model
> server-side and returns a textured mesh.

## Pipeline

```
reference/unit07_sheet.png          # <- you drop the reference image here
        │
        ▼  pipeline/prep_views.py    # split turnaround -> clean per-view PNGs
reference/views/{front,side,back}.png
        │
        ▼  pipeline/tripo_image_to_3d.py   # upload -> generate -> download
model/unit07.glb  (+ unit07.obj / unit07.fbx)
```

## Setup

```bash
pip install -r requirements.txt
export TRIPO_API_KEY=tcli_xxxxxxxx        # from platform.tripo3d.ai -> API keys
```

## Run

```bash
# 1. split the sheet into front/side/back views
python3 pipeline/prep_views.py reference/unit07_sheet.png

# 2. generate the mesh from the multiview images (best fidelity)
python3 pipeline/tripo_image_to_3d.py \
    --front reference/views/front.png \
    --left  reference/views/side.png \
    --back  reference/views/back.png \
    --also obj,fbx

# ...or just from a single clean image:
python3 pipeline/tripo_image_to_3d.py reference/views/front.png --also obj
```

Output lands in `model/` (`unit07.glb` is textured/PBR; OBJ/FBX via `--also`).
Import the GLB into Blender (`File ▸ Import ▸ glTF 2.0`), Unity, Godot, etc.

### Options

- `--model-version v2.5-20250123` — pin a Tripo model version
- `--no-texture` / `--no-pbr` — geometry-only / no PBR maps
- `prep_views.py --band TOP BOTTOM` — adjust which rows are treated as the
  turnaround (fractions of image height) if auto-detection grabs the wrong band
- `prep_views.py --thresh N` — background brightness cutoff (0–255)

## Running this inside Claude Code on the web

To have the model generated **in this session** and committed for you, three
things must be true (none are by default):

1. **Network** — the environment's network policy must allow `api.tripo3d.ai`.
   It's currently blocked (every external AI host returns 403). Adjust the policy
   for this environment: https://code.claude.com/docs/en/claude-code-on-the-web
2. **API key** — add `TRIPO_API_KEY` as an environment secret.
3. **Reference image** — commit the sheet to `reference/unit07_sheet.png`
   (it lives in chat, not on disk).

With those in place, the two commands above run end-to-end and the resulting
`model/unit07.glb` is committed to this branch.
