# Setup — generating Unit-07 in a Claude Code web session

To have the model generated **inside a Claude Code on the web session** and
committed for you, three things must be configured **on the environment** (none
can be set from inside the sandbox — the network allowlist is enforced by a proxy
outside the container, and there is no in-container secrets store).

All of this happens in the environment editor at
[claude.ai/code](https://claude.ai/code). Docs:
https://code.claude.com/docs/en/claude-code-on-the-web#network-access

## 1. Open the environment editor

Click the **cloud icon** (it shows the current environment's name) → hover the
environment → click the **settings/gear icon** on the right.

## 2. Network access → Custom

In the **Network access** selector, choose **Custom**. An **Allowed domains**
field appears. Add:

```
*.tripo3d.ai
```

Then **check "Also include default list of common package managers"** so PyPI and
GitHub stay reachable (needed for `pip install` and `git push`).

> Wildcard is intentional: the API is `api.tripo3d.ai`, but generated models are
> downloaded from a different subdomain. If the download host is ever off-domain
> (some setups use an object-store CDN), the first run surfaces the exact host —
> add that one line too.

## 3. Environment variables

In the same dialog's environment-variables field (`.env` format, one `KEY=value`
per line, **no quotes**):

```
TRIPO_API_KEY=tcli_your_key_here
```

> ⚠️ There is no dedicated secrets store. Anyone who can edit this environment can
> read this value. Use a key you're comfortable storing here, and rotate/revoke it
> afterward if you like.

## 4. Commit the reference image

A fresh session clones the repo clean, so an image pasted into chat won't be
present. Commit the reference sheet to the repo at:

```
reference/unit07_sheet.png
```

## 5. Start a fresh session and run

Network and env-var changes apply to **new sessions**. Start a new session on
branch `claude/3d-model-conversion-Tvx8m`, then run:

```bash
pip install -r requirements.txt

python3 pipeline/prep_views.py reference/unit07_sheet.png

python3 pipeline/tripo_image_to_3d.py \
    --front reference/views/front.png \
    --left  reference/views/side.png \
    --back  reference/views/back.png \
    --also obj,fbx
```

The textured mesh lands in `model/` (`unit07.glb`, plus `unit07.obj` /
`unit07.fbx`). Commit it to the branch.
