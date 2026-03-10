#!/bin/bash
# Google TTS wrapper - generates audio from text and sends as voice note
# Usage: google-tts.sh "texto"
# Uses gtts (Google Translate TTS) - free, no API key needed
# Speed: 1.25x (Manu preference 2026-03-10)

VENV_DIR="$(dirname "$0")/tts-venv"
TEXT="$1"
TIMESTAMP=$(date +%s)
OUTPUT="/home/mleon/.openclaw/media/outbound/tts-${TIMESTAMP}.mp3"
SPEED="${2:-1.25}"

if [ -z "$TEXT" ]; then
    echo "Usage: $0 \"text\" [speed]"
    exit 1
fi

mkdir -p /home/mleon/.openclaw/media/outbound

source "$VENV_DIR/bin/activate"
python3 << PYEOF
from gtts import gTTS
import subprocess, os, sys

text = """${TEXT}"""
speed = ${SPEED}
temp_file = "${OUTPUT}.tmp.mp3"
final_file = "${OUTPUT}"

# Generate TTS
tts = gTTS(text=text, lang='es', tld='es')
tts.save(temp_file)

# Speed up with ffmpeg
result = subprocess.run([
    'ffmpeg', '-y', '-i', temp_file,
    '-filter:a', f'atempo={speed}',
    '-vn', final_file
], capture_output=True, text=True)

os.remove(temp_file)

if result.returncode == 0:
    print(final_file)
else:
    print(f"ERROR: ffmpeg failed: {result.stderr}", file=sys.stderr)
    sys.exit(1)
PYEOF
