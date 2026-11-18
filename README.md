# gta6-dlss5

GTA 6 runs at 30 fps on every PS5, Pro included. If you have a GeForce RTX PC, it can take the PS5 picture and give it back with DLSS 5 neural rendering and 60 to 120 fps. You don't need a capture card: the PS5 streams to the PC over Remote Play.

This repo makes that a 5-minute setup:

| file | what it does |
|---|---|
| `setup.ps1` | checks your PC, installs [Veyra](https://github.com/Likely7/Veyra-NRVideo) (free, open source), verifies its SHA-256 and prints the GTA 6 preset for your GPU |
| `truefps.py` | measures the real frame rate of any recording and shows how many frames are copies |
| `compare.py` | builds a before/after split video you can post |

## Quick start (Windows 11)

Open PowerShell and paste:

```powershell
irm https://raw.githubusercontent.com/phosphenq/gta6-dlss5/main/setup.ps1 | iex
```

Or download the repo and run `powershell -ExecutionPolicy Bypass -File setup.ps1`. Add `-CheckOnly` to just test your PC.

Then:

1. **PS5:** Settings → System → Remote Play → turn on **Enable Remote Play**.
2. **PS5:** same menu → **Link Device** (some menus call it **Pair Device**). You get an 8-digit code; it expires in a few minutes, so have the PC ready.
3. **PC:** open the new desktop shortcut **GTA 6 DLSS 5 (Veyra)** → Home → **PS5 streaming** → **Get Account ID** (opens PSNTools) → paste it, enter the code. Saved consoles reconnect by themselves.
4. **PC:** Settings → PS5 streaming → quality **1080p · 60 fps**, codec **H.265**.
5. **PC:** top bar → **Pro mode** → set the preset below → fullscreen. Hold **V** to see the original picture.

Capture card owners pick **Capture card** on the Home screen instead of PS5 streaming.

## GTA 6 preset

| setting | RTX 50 | RTX 40 | RTX 20 / 30 |
|---|---|---|---|
| NR enhancement (DLSS 5 neural rendering) | on, version **RTX 50 · NVIDIA original**, 2 layers (1 layer is barely visible) | on, RTX 20–50 · SF, 1 layer | on, RTX 20–50 · SF, 1 layer |
| Output stabilizer · anti-flicker | on | on | on |
| Super resolution | RTX Video SR, target = your screen | same | same |
| Frame Gen | DLSS Frame Generation, **2X** on 60 Hz, **4X** on 120 Hz | 2X, 4X on 120 Hz | RTX 30: 2X in compatibility mode, RTX 20: off |
| Display tab | Display sync **Auto** (lowest latency), Output cap **Follow the display** | same | same |

**Why the copies matter.** GTA 6 renders 30 fps but the PS5 sends a 60 fps signal, so every second frame is a copy. Frame generation fed with copies makes stutter instead of smoothness. Veyra 2.1.6+ removes them by itself (automatic dedup, 60→30), so keep the source at 60 fps and don't force 30 on the console side. Check any clip yourself:

```
python truefps.py my_gta6_clip.mp4
```

## What we measured

All numbers come from the scripts in this repo and Veyra's own counters on an RTX 5080.

- **GTA 6 captured from a PS5** (a 60 fps file, 41 s): 2,475 frames, only **1,245 unique**, so the real rate is **30.1 fps** and the 1% low is **25.7 fps**.
- **GTA 6 on PS5 Pro** (Digital Foundry footage, 30 s): **863 real frames**. After Veyra with DLSS 5 and frame generation: **1,723 real frames**, or 57.4 fps on average against 28.8.
- **80 seconds of gameplay and cutscenes** (14 scenes, mostly IGN's PS5 Pro capture): **2,351 real frames** before, **4,700** after Veyra, 29.5 → 59.0 fps.
- **Live cost on an RTX 5080 with the RTX 50 preset** (2 neural-rendering layers, stabilizer, frame generation 2X): **4.1 ms** per neural-rendering layer, frame generation **1.5 ms**, optical flow 2.1 ms, **12 ms** per frame in total. The output holds **60.0 fps** with a 1% low of 56.3, and the GPU is at 39%.

## FAQ

**Can I jailbreak or "reverse" my PS5 to get DLSS?** No. The PS5 GPU is AMD and has no DLSS hardware, and GTA 6 needs the current firmware, while jailbreaks only exist for old firmware. PS5 Pro already uses Sony's own upscaler, PSSR. Your PC is the only way.

**Does it add input lag?** Yes, a little. Remote Play adds its own delay, and the RTX 5080 spends about 12 ms per frame on processing. Frame generation makes motion smoother but the game still reacts at 30 fps.

**Is this official DLSS 5?** On RTX 50, Veyra loads NVIDIA's own signed neural-rendering runtime (`nvngx_dlssnr.dll` 310.8). The integration itself is community-made and not certified by NVIDIA.

**Can I get banned?** Nothing touches the console or the game. It is video processing on your PC.

## Credits

[Veyra](https://github.com/Likely7/Veyra-NRVideo) by Likely7, GPL-3.0. This repo does not ship Veyra: `setup.ps1` downloads the official release from GitHub and checks it against the release's SHA-256. NVIDIA and DLSS are trademarks of NVIDIA Corporation. Grand Theft Auto is a trademark of Take-Two Interactive. Not affiliated with any of them.

Code in this repo: MIT.
