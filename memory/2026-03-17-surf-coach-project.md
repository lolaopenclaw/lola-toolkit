# Surf Coach AI Project — 2026-03-17

## Status
MVP analysis phase. Videos downloaded, initial analysis running overnight.

## What We're Building
AI tool for analyzing surfer movements during dryland training, surfskate sessions, and functional exercises. Using MediaPipe pose estimation to give automated technique feedback similar to a human coach.

## Key Info
- **User:** Manu (Manuel León)
- **Coach reference:** Jorge (Surf Labs) — provides video corrections that will be ground truth
- **Training types to analyze:**
  - Dry land simulations (pop-ups, turns, compression/extension)
  - Surfskate sessions
  - Functional strength work

## Repo Location
`~/projects/surf-coach/` on VPS

## What's Done
- [x] Git repo initialized (main branch)
- [x] SPEC.md v0.1 written (full product spec, tech stack, MVP scope)
- [x] README.md created
- [x] Project structure scaffolded (src/, data/, docs/, notebooks/)
- [x] requirements.txt with MediaPipe, OpenCV, NumPy, matplotlib
- [x] .gitignore configured
- [x] gog auth fixed (now has full Drive scope)
- [x] Videos downloaded (2 corrected + 4 raw = ~513 MB)
- [x] Python venv set up with dependencies
- [x] Analysis scripts written (pose estimation + optical flow)
- [x] Video analysis running (4 videos, 300 frames each)

## Tomorrow Morning
1. Review analysis results (JSON + annotated videos in output/)
2. Fix MediaPipe import issue (Python 3.14 compatibility)
3. Extract key angles/patterns from corrected videos (compare vs raw)
4. Prepare summary report for SPEC.md v0.2

## Technical Notes
- Videos in: ~/projects/surf-coach/data/videos/{corregidos,brutos}/
- Analysis running: src/analyze_simple.py (optical flow as fallback)
- Output: output/ (JSON + annotated MP4s)
- MediaPipe issue: import fails on this Python version, using optical flow for now

## Notes
- Spec-driven development approach agreed
- No code execution until Manu reviews SPEC.md
- Focus on understanding existing coach feedback before automating
- MVP v0 is CLI script for video analysis (not web/real-time yet)
