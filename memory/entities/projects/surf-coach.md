# Surf Coach AI — Summary

**Type:** project  
**Last synthesized:** 2026-03-22  
**Tiers:** 6 hot, 0 warm, 0 cold

## 🔥 Hot (recent / frequent)

- **[context]** Goal: AI coach for surf technique analysis using video + pose estimation. Provide automated feedback on pop-ups, turns, compression/extension.
- **[context]** Repo: github.com/lolaopenclaw/surf-coach-ai (private, shared with RagnarBlackmade). Local: ~/projects/surf-coach/
- **[context]** Tech stack: Python, MediaPipe (pose estimation), OpenCV (video processing), optical flow analysis. Runs with cpulimit to protect VPS.
- **[status]** Video corpus: 5 corrected videos (Jorge, Surf Labs) as ground truth + 4 raw comparison videos. 9 MP4s analyzed total.
- **[context]** Analysis pipeline: frame extraction → MediaPipe pose → optical flow → metrics (angle, speed, balance) → annotated MP4 + JSON report.
- **[status]** Status as of 2026-03-18: 2 full analyses complete (12550 + 14328 frames). analyze_remaining.py relaunched after VPS reboot with venv-coach.

---

See `surf-coach.json` for all 6 facts.