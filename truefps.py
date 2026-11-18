"""truefps: how many real frames per second is your console actually rendering?

A 60 fps capture of a 30 fps game is half copies. Remote Play, capture cards and
most clips on X/YouTube carry GTA 6 that way. This script drops the copies
(ffmpeg mpdecimate) and measures what is left.

usage:
  python truefps.py clip.mp4
  python truefps.py clip.mp4 --csv fps.csv --png fps.png

needs: ffmpeg + ffprobe in PATH (winget install Gyan.FFmpeg). matplotlib only for --png.
"""
import argparse
import json
import re
import statistics
import subprocess
import sys


def probe(path):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-count_frames",
         "-show_entries", "stream=width,height,r_frame_rate,nb_read_frames:format=duration",
         "-of", "json", path],
        capture_output=True, text=True, check=True).stdout
    j = json.loads(out)
    s, f = j["streams"][0], j["format"]
    num, den = (int(x) for x in s["r_frame_rate"].split("/"))
    return {"w": s["width"], "h": s["height"], "fps": num / den,
            "frames": int(s.get("nb_read_frames") or 0), "dur": float(f["duration"])}


def unique_times(path):
    # mpdecimate keeps a frame only if it differs from the last kept one; showinfo prints its timestamp
    p = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-an",
         "-vf", "mpdecimate=hi=768:lo=320:frac=0.33,showinfo", "-f", "null", "-"],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    return [float(m) for m in re.findall(r"pts_time:\s*([0-9.]+)", p.stderr)]


def main():
    ap = argparse.ArgumentParser(description="real frame rate of a gameplay recording")
    ap.add_argument("clip")
    ap.add_argument("--csv", help="write per-second fps to this CSV")
    ap.add_argument("--png", help="draw per-second fps chart to this PNG")
    a = ap.parse_args()

    info = probe(a.clip)
    t = unique_times(a.clip)
    if len(t) < 2:
        sys.exit("could not read frames, is ffmpeg installed?")

    dur = info["dur"]
    secs = int(dur)
    per_sec = [sum(1 for x in t if s <= x < s + 1) for s in range(secs)]
    gaps = [b - a for a, b in zip(t, t[1:]) if b > a]
    slow = sorted(gaps, reverse=True)[:max(1, len(gaps) // 100)]
    low1 = 1 / statistics.mean(slow)
    real = len(t) / dur
    copies = 1 - len(t) / info["frames"] if info["frames"] else 0

    print(f"clip            {a.clip}")
    print(f"video           {info['w']}x{info['h']}, {info['fps']:.0f} fps container, {dur:.1f} s, {info['frames']} frames")
    print(f"unique frames   {len(t)}  ({copies:.0%} were copies)")
    print(f"real fps        {real:.1f} average")
    print(f"1% low          {low1:.1f} fps")
    print(f"worst second    {min(per_sec)} fps (at {per_sec.index(min(per_sec))}s)")
    print(f"best second     {max(per_sec)} fps")
    verdict = "30 fps game in a 60 fps stream: turn ON dedup before frame generation" if info["fps"] >= 50 and real < 40 else \
              "stream already carries real frames" if real > info["fps"] * 0.9 else "mixed: check the per-second numbers"
    print(f"verdict         {verdict}")

    if a.csv:
        with open(a.csv, "w", encoding="utf-8") as f:
            f.write("second,fps\n" + "".join(f"{i},{v}\n" for i, v in enumerate(per_sec)))
    if a.png:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, ax = plt.subplots(figsize=(10, 3.2), dpi=150)
        ax.plot(range(secs), per_sec, color="#ffb347", lw=2)
        ax.axhline(30, color="#888", lw=1, ls="--")
        ax.set_xlabel("second"); ax.set_ylabel("real fps"); ax.set_ylim(0, max(62, max(per_sec) + 2))
        ax.set_title(f"real fps: {real:.1f} avg, 1% low {low1:.1f}")
        fig.tight_layout(); fig.savefig(a.png)


if __name__ == "__main__":
    main()
