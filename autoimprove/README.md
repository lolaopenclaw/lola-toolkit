# 🔬 Autoimprove — Auto-optimization Framework

Inspired by [Karpathy's autoresearch](https://github.com/karpathy/autoresearch).

## Concept

The same iterate→test→keep/discard loop applied to our OpenClaw setup:

```
Human writes program.md (what to optimize, how to measure)
    ↓
Agent reads target file
    ↓
Agent proposes a change
    ↓
Agent applies the change
    ↓
Agent runs evaluation (objective metric)
    ↓
Score improved? → KEEP (record in results.tsv)
Score worse?    → DISCARD (revert)
    ↓
Repeat N times
```

## Structure

```
autoimprove/
├── engine.sh          # Core engine (setup, baseline, tracking)
├── README.md          # This file
├── programs/          # program.md files (one per optimization target)
│   ├── backup-speed/  # Optimize backup script
│   └── prompt-tokens/ # Optimize prompt token usage
└── results/           # Experiment results (auto-generated)
```

## Usage

1. Create a `program.md` for your target (see examples in `programs/`)
2. Run: `bash engine.sh programs/my-target/program.md`
3. The engine sets up tracking, then the agent takes over
4. Results in `results/experiments.tsv`

## program.md Format

```markdown
TARGET_FILE: /path/to/file/to/optimize
EVAL_COMMAND: bash /path/to/eval-script.sh
BASELINE_SCORE: auto
GOAL: Minimize execution time while maintaining correctness
CONSTRAINTS: Must produce valid backup, must include all required files

## Context
[Describe what the target file does]

## What to try
[Suggest directions for the agent]
```

## Key Principles (from autoresearch)

1. **Single file to modify** — Keep scope manageable
2. **Fixed evaluation** — Same test every time, comparable results
3. **Objective metric** — A number, lower is better
4. **Git tracking** — Every improvement is a commit
5. **Autonomous** — No human in the loop during experiments
