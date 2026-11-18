"""compare: before/after video for your console vs your PC.

split  - one frame, left half is the console, right half is the enhanced picture (16:9)
stack  - console on top, enhanced below (good for phones)

usage:
  python compare.py ps5.mp4 veyra.mp4 -o compare.mp4
  python compare.py ps5.mp4 veyra.mp4 -o compare.mp4 --mode stack --start 5 --dur 15
  python compare.py ps5.mp4 veyra.mp4 -o compare.mp4 --labels "PS5 30 FPS" "PC DLSS 5 60 FPS"

needs: ffmpeg in PATH. Output is 60 fps so the console side keeps its repeated frames
and the difference in motion is visible on any 60 Hz phone or monitor.
"""
import argparse
import os
import subprocess

FONT = "C\\:/Windows/Fonts/segoeuib.ttf" if os.name == "nt" else "DejaVuSans-Bold.ttf"


def label(text, x, y, size):
    t = text.replace("\\", "\\\\").replace(":", "\\:").replace("'", "’")
    return (f"drawtext=fontfile='{FONT}':text='{t}':x={x}:y={y}:fontsize={size}:fontcolor=white:"
            f"box=1:boxcolor=black@0.55:boxborderw=18")


def main():
    ap = argparse.ArgumentParser(description="before/after gameplay video")
    ap.add_argument("before")
    ap.add_argument("after")
    ap.add_argument("-o", "--out", default="compare.mp4")
    ap.add_argument("--mode", choices=["split", "stack"], default="split")
    ap.add_argument("--labels", nargs=2, default=["PS5  30 FPS", "PC  DLSS 5 + FRAME GEN"])
    ap.add_argument("--start", type=float, default=0)
    ap.add_argument("--dur", type=float, default=20)
    ap.add_argument("--fps", type=int, default=60)
    a = ap.parse_args()

    trim = f"trim=start={a.start}:duration={a.dur},setpts=PTS-STARTPTS,fps={a.fps}"
    if a.mode == "split":
        w, h = 1920, 1080
        graph = (
            f"[0:v]{trim},scale={w}:{h}:flags=lanczos,crop={w // 2}:{h}:0:0[l];"
            f"[1:v]{trim},scale={w}:{h}:flags=lanczos,crop={w // 2}:{h}:{w // 2}:0[r];"
            f"[l][r]hstack=2,drawbox=x={w // 2 - 2}:y=0:w=4:h={h}:color=white@0.9:t=fill,"
            f"{label(a.labels[0], 40, 40, 44)},{label(a.labels[1], 'w-tw-40', 40, 44)}[v]")
    else:
        w, h = 1080, 608
        graph = (
            f"[0:v]{trim},scale={w}:{h}:flags=lanczos,{label(a.labels[0], 30, 30, 38)}[t];"
            f"[1:v]{trim},scale={w}:{h}:flags=lanczos,{label(a.labels[1], 30, 30, 38)}[b];"
            f"[t][b]vstack=2[v]")
    fade = f"afade=t=in:d=0.3,afade=t=out:st={max(0, a.dur - 0.5):.2f}:d=0.5"
    cmd = ["ffmpeg", "-hide_banner", "-y", "-i", a.before, "-i", a.after, "-filter_complex", graph,
           "-map", "[v]", "-map", "0:a?", "-af", f"atrim=start={a.start}:duration={a.dur},asetpts=PTS-STARTPTS,{fade}",
           "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p", "-r", str(a.fps),
           "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", a.out]
    subprocess.run(cmd, check=True)
    print("saved", a.out)


if __name__ == "__main__":
    main()
