#!/usr/bin/env python3
"""Optional one-time MP4 → OGV conversion. Requires local FFmpeg, not for gameplay."""
import argparse
import subprocess
from pathlib import Path
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('source', type=Path)
p.add_argument('destination', type=Path, nargs='?', default=Path(__file__).resolve().parents[1] / 'assets/video/tufted_deer_documentary.ogv')
a = p.parse_args()
a.destination.parent.mkdir(parents=True, exist_ok=True)
# -n preserves any existing video. Do not stretch the input image.
subprocess.run(['ffmpeg', '-n', '-i', str(a.source), '-c:v', 'libtheora', '-q:v', '7', '-c:a', 'libvorbis', '-q:a', '4', str(a.destination)], check=True)
