#!/usr/bin/env python3
"""
Unit-07 image -> 3D model, via the Tripo3D OpenAPI (v2).

Turns the reference image(s) into a real, textured mesh (GLB, and optionally
OBJ/FBX). This is a thin, defensive client around Tripo's documented v2 API:

    upload image(s)  ->  create task  ->  poll until done  ->  download model

Single image:     python3 tripo_image_to_3d.py reference/front.png
Multiview (better): python3 tripo_image_to_3d.py \
                        --front reference/front.png \
                        --left  reference/side.png \
                        --back  reference/back.png

Requires:
  * env var  TRIPO_API_KEY   (https://platform.tripo3d.ai -> API keys)
  * network access to https://api.tripo3d.ai

Docs: https://platform.tripo3d.ai/docs
"""
import argparse
import os
import sys
import time

import requests

API = "https://api.tripo3d.ai/v2/openapi"
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "model")


def auth_headers():
    key = os.environ.get("TRIPO_API_KEY")
    if not key:
        sys.exit("ERROR: set TRIPO_API_KEY (export TRIPO_API_KEY=tcli_...).")
    return {"Authorization": f"Bearer {key}"}


def ext_of(path):
    e = os.path.splitext(path)[1].lower().lstrip(".")
    return "jpeg" if e == "jpg" else (e or "png")


def upload_image(path):
    """Upload one image, return its file_token."""
    if not os.path.isfile(path):
        sys.exit(f"ERROR: image not found: {path}")
    with open(path, "rb") as fh:
        r = requests.post(
            f"{API}/upload",
            headers=auth_headers(),
            files={"file": (os.path.basename(path), fh)},
            timeout=120,
        )
    data = _ok(r, f"upload {path}")
    token = data.get("image_token") or data.get("file_token")
    if not token:
        sys.exit(f"ERROR: no image_token in upload response: {data}")
    print(f"  uploaded {os.path.basename(path)} -> {token[:12]}...")
    return token


def _ok(resp, what):
    try:
        body = resp.json()
    except ValueError:
        sys.exit(f"ERROR: {what}: non-JSON response ({resp.status_code}): {resp.text[:300]}")
    if resp.status_code != 200 or body.get("code", 0) != 0:
        sys.exit(f"ERROR: {what}: {resp.status_code} code={body.get('code')} "
                 f"msg={body.get('message') or body.get('suggestion') or body}")
    return body.get("data", {})


def create_image_task(token, path, model_version, texture, pbr):
    payload = {
        "type": "image_to_model",
        "file": {"type": ext_of(path), "file_token": token},
        "texture": texture,
        "pbr": pbr,
    }
    if model_version:
        payload["model_version"] = model_version
    r = requests.post(f"{API}/task", headers=auth_headers(), json=payload, timeout=60)
    return _ok(r, "create image_to_model task")["task_id"]


def create_multiview_task(tokens, paths, model_version, texture, pbr):
    """tokens/paths are dicts keyed by FRONT/LEFT/BACK/RIGHT; missing => {}."""
    order = ["FRONT", "LEFT", "BACK", "RIGHT"]
    files = []
    for k in order:
        if tokens.get(k):
            files.append({"type": ext_of(paths[k]), "file_token": tokens[k]})
        else:
            files.append({})
    payload = {
        "type": "multiview_to_model",
        "files": files,
        "texture": texture,
        "pbr": pbr,
    }
    if model_version:
        payload["model_version"] = model_version
    r = requests.post(f"{API}/task", headers=auth_headers(), json=payload, timeout=60)
    return _ok(r, "create multiview_to_model task")["task_id"]


def poll(task_id, label="task"):
    print(f"  {label} {task_id} submitted; polling...")
    last = -1
    while True:
        r = requests.get(f"{API}/task/{task_id}", headers=auth_headers(), timeout=60)
        data = _ok(r, "poll task")
        status = data.get("status")
        prog = data.get("progress", 0)
        if prog != last:
            print(f"    status={status} progress={prog}%")
            last = prog
        if status == "success":
            return data
        if status in ("failed", "cancelled", "banned", "unknown"):
            sys.exit(f"ERROR: task {status}: {data}")
        time.sleep(5)


def download(url, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with requests.get(url, stream=True, timeout=300) as r:
        r.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in r.iter_content(1 << 16):
                f.write(chunk)
    print(f"  saved {dest} ({os.path.getsize(dest)//1024} KB)")


def model_url(data):
    out = data.get("output", {})
    return out.get("pbr_model") or out.get("model") or out.get("base_model")


def convert(task_id, fmt, model_version):
    """Optional: convert the generated model to OBJ/FBX/STL/USDZ."""
    payload = {
        "type": "convert_model",
        "format": fmt.upper(),
        "original_model_task_id": task_id,
    }
    if model_version:
        payload["model_version"] = model_version
    r = requests.post(f"{API}/task", headers=auth_headers(), json=payload, timeout=60)
    cid = _ok(r, f"create convert->{fmt} task")["task_id"]
    data = poll(cid, f"convert->{fmt}")
    url = model_url(data)
    if url:
        download(url, os.path.join(OUT_DIR, f"unit07.{fmt.lower()}"))
    else:
        print(f"  (no {fmt} url returned)")


def main():
    ap = argparse.ArgumentParser(description="Tripo3D image -> 3D model")
    ap.add_argument("image", nargs="?", help="single input image (image_to_model)")
    ap.add_argument("--front")
    ap.add_argument("--left")
    ap.add_argument("--back")
    ap.add_argument("--right")
    ap.add_argument("--model-version", default=None,
                    help="e.g. v2.5-20250123 (default: account default)")
    ap.add_argument("--no-texture", action="store_true")
    ap.add_argument("--no-pbr", action="store_true")
    ap.add_argument("--also", default="", help="comma list of extra formats, e.g. obj,fbx")
    args = ap.parse_args()

    auth_headers()  # fail fast if TRIPO_API_KEY is unset
    texture = not args.no_texture
    pbr = not args.no_pbr
    mv = args.model_version

    multiview = {k: getattr(args, k.lower()) for k in ("FRONT", "LEFT", "BACK", "RIGHT")}
    have_mv = any(multiview.values())

    if have_mv:
        print("Multiview mode:", {k: os.path.basename(v) for k, v in multiview.items() if v})
        tokens = {k: (upload_image(v) if v else None) for k, v in multiview.items()}
        task_id = create_multiview_task(tokens, multiview, mv, texture, pbr)
    elif args.image:
        print("Single-image mode:", args.image)
        token = upload_image(args.image)
        task_id = create_image_task(token, args.image, mv, texture, pbr)
    else:
        ap.error("provide a single image, or --front/--left/--back/--right")

    data = poll(task_id, "generation")
    url = model_url(data)
    if not url:
        sys.exit(f"ERROR: no model url in output: {data.get('output')}")
    download(url, os.path.join(OUT_DIR, "unit07.glb"))

    for fmt in [f.strip() for f in args.also.split(",") if f.strip()]:
        convert(task_id, fmt, mv)

    print("\nDone. Model(s) in:", os.path.normpath(OUT_DIR))


if __name__ == "__main__":
    main()
