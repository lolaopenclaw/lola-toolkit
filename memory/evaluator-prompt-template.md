# Evaluator Prompt Template

**Última actualización:** 2026-03-27

Plantilla estándar para escribir prompts de evaluadores que completan en <10 min.

---

## 🎯 PRINCIPIOS

### DO ✅

1. **Concrete checklist:** 5-7 items máximo
2. **One command per check:** Bash one-liner que produce PASS/FAIL
3. **Simple output:** Plain text, no tables/reportes complejos
4. **Explicit scope:** "Check THESE N things, nothing more"

### DON'T ❌

1. **"Find all problems"** → Triggers exhaustive search (timeout)
2. **Tables/detailed reports** → Plain text only
3. **Meta-instructions** → No "be thorough", "think deeply", etc.
4. **Open-ended checks** → "Verify quality" (too vague)

---

## 📋 BASE TEMPLATE

```markdown
## EVALUATOR: [Task Name]

Verify the generator's output. Check these N things:

1. **[Check name]:** [What to verify] → Command: `[bash one-liner]`
2. **[Check name]:** [What to verify] → Command: `[bash one-liner]`
3. **[Check name]:** [What to verify] → Command: `[bash one-liner]`
4. **[Check name]:** [What to verify] → Command: `[bash one-liner]`
5. **[Check name]:** [What to verify] → Command: `[bash one-liner]`

### Output Format

- Check 1: PASS/FAIL — [one line reason]
- Check 2: PASS/FAIL — [one line reason]
- Check 3: PASS/FAIL — [one line reason]
- Check 4: PASS/FAIL — [one line reason]
- Check 5: PASS/FAIL — [one line reason]

**Final:** PASS/FAIL (score X/5 if needed)

Working directory: /home/mleon/.openclaw/workspace
```

---

## 📚 TASK-SPECIFIC CHECKLISTS

### A. Code/Script Changes

**Use when:** Generator modified/created scripts, modules, CLIs

```markdown
## EVALUATOR: [Script/Module Name]

Verify the generator's code changes. Check these 5 things:

1. **Syntax valid:** No syntax errors
   → Command: `bash -n script.sh` (or `python3 -m py_compile script.py`)

2. **No hardcoded paths:** No `/home/mleon` references
   → Command: `grep -n "/home/mleon" script.sh`

3. **Files exist:** All referenced files are present
   → Command: `ls -la file1.txt file2.json` (list expected files)

4. **Git clean:** No trailing whitespace or issues
   → Command: `git diff --check`

5. **Smoke test:** Script runs without crashing
   → Command: `timeout 10s ./script.sh --help` (or `--version` or minimal run)

### Output Format

- Check 1: PASS/FAIL — [one line]
- Check 2: PASS/FAIL — [one line]
- Check 3: PASS/FAIL — [one line]
- Check 4: PASS/FAIL — [one line]
- Check 5: PASS/FAIL — [one line]

**Final:** PASS/FAIL (5/5 = PASS, <5 = FAIL)

Working directory: /home/mleon/.openclaw/workspace
```

**Example checklist variants:**

- For **Python modules:** Replace check 1 with `python3 -m py_compile module.py`
- For **JSON configs:** Add `jq . config.json` check
- For **executables:** Add `chmod +x script.sh` verify

---

### B. Documentation/Memory Changes

**Use when:** Generator created/updated .md files in memory/

```markdown
## EVALUATOR: [Documentation Topic]

Verify the generator's documentation. Check these 5 things:

1. **File exists and non-empty:** File created with content
   → Command: `wc -l memory/[filename].md` (should be >10 lines)

2. **No broken references:** No [MISSING] or [TODO] placeholders
   → Command: `grep -E "\[(MISSING|TODO|FIXME)\]" memory/[filename].md`

3. **Key terms present:** Expected content exists
   → Command: `grep -i "[term1]" memory/[filename].md && grep -i "[term2]" memory/[filename].md`

4. **No unfinished sections:** No TODO/FIXME markers left
   → Command: `grep -E "(TODO|FIXME)" memory/[filename].md`

5. **Markdown valid:** Basic structure check (headers, lists)
   → Command: `head -30 memory/[filename].md` (manual visual check)

### Output Format

- Check 1: PASS/FAIL — [file has X lines]
- Check 2: PASS/FAIL — [no broken refs / found N broken refs]
- Check 3: PASS/FAIL — [term1 found / term2 missing]
- Check 4: PASS/FAIL — [no TODOs / found N TODOs]
- Check 5: PASS/FAIL — [structure looks good / missing headers]

**Final:** PASS/FAIL (5/5 = PASS)

Working directory: /home/mleon/.openclaw/workspace
```

**Example checklist variants:**

- For **multi-file docs:** Check cross-references (`grep -r "link-to-section" memory/`)
- For **reference docs:** Verify examples are runnable (`bash -n example.sh`)
- For **API docs:** Check all endpoints listed (`grep "POST\|GET\|PUT" doc.md`)

---

### C. Configuration Changes

**Use when:** Generator modified config files (JSON, YAML, .env)

```markdown
## EVALUATOR: [Config Name]

Verify the generator's configuration changes. Check these 5 things:

1. **Config loads:** No syntax errors
   → Command: `jq . config.json` (or `yamllint config.yml`)

2. **No syntax errors:** Valid JSON/YAML/etc.
   → Command: (covered by check 1)

3. **Key fields present:** Required keys exist
   → Command: `jq '.field1, .field2, .field3' config.json`

4. **Backup exists:** Changes are tracked in git
   → Command: `git diff config.json | head -20`

5. **Rollback documented:** Instructions exist for reverting
   → Command: `grep -i "rollback\|revert" memory/[related-doc].md`

### Output Format

- Check 1: PASS/FAIL — [jq passed / syntax error at line X]
- Check 2: PASS/FAIL — (skip if check 1 passed)
- Check 3: PASS/FAIL — [all keys present / missing: fieldX]
- Check 4: PASS/FAIL — [diff shows changes / no diff found]
- Check 5: PASS/FAIL — [rollback documented / no instructions]

**Final:** PASS/FAIL (≥4/5 = PASS)

Working directory: /home/mleon/.openclaw/workspace
```

**Example checklist variants:**

- For **.env files:** Check no secrets committed (`grep "API_KEY" .env`)
- For **openclaw config:** Use `openclaw config validate` if available
- For **package.json:** Run `npm install --dry-run` to verify deps

---

## 🧪 ADVANCED PATTERNS

### Skip Checks Already Done by Generator

If generator reports Ralph Wiggum checks in output:

```markdown
## EVALUATOR: [Task]

Generator already validated:
- ✅ Syntax (bash -n passed)
- ✅ No hardcoded paths

Verify these 3 ADDITIONAL things:

1. **Integration test:** Script works with real data
   → Command: `./script.sh --test-data data/sample.json`

2. **Edge case (empty input):** Handles empty input gracefully
   → Command: `echo "" | ./script.sh`

3. **Edge case (large input):** Doesn't crash on large file
   → Command: `./script.sh --input data/large-10mb.txt`

### Output Format

- Check 1: PASS/FAIL — [one line]
- Check 2: PASS/FAIL — [one line]
- Check 3: PASS/FAIL — [one line]

**Final:** PASS/FAIL (3/3 = PASS)
```

**Benefit:** Evaluator focuses on high-level checks, not redundant syntax validation.

---

### Multi-File Verification

When generator created multiple related files:

```markdown
## EVALUATOR: [Module Name]

Generator created 3 files. Check these 5 things:

1. **All files exist:** script.sh, config.json, README.md
   → Command: `ls -la script.sh config.json README.md`

2. **Script references config:** Uses config.json path
   → Command: `grep "config.json" script.sh`

3. **README documents usage:** Includes example command
   → Command: `grep -E "(Example|Usage)" README.md`

4. **No file is empty:** Each file has content
   → Command: `wc -l script.sh config.json README.md` (all >5 lines)

5. **Integration:** Script runs with config
   → Command: `timeout 10s ./script.sh --config config.json --dry-run`

### Output Format

[Same as before]
```

---

### Scoring Variants

**Binary (PASS/FAIL only):**
```
**Final:** PASS (5/5 checks passed)
**Final:** FAIL (2/5 checks failed: syntax, missing file)
```

**Scored (for partial success):**
```
**Final:** PARTIAL PASS (4/5 checks passed, 1 minor issue: no rollback doc)
**Final:** FAIL (2/5 checks passed, critical: syntax error, missing files)
```

**Use binary by default.** Only use scoring if task allows partial success.

---

## 📏 PROMPT LENGTH GUIDELINES

### Target

- **Checklist:** 5-7 items (not 10+)
- **Total prompt:** 500-800 chars (not 2000+)
- **Commands:** One-liners (not multi-step scripts)

### Example: TOO LONG ❌

```markdown
## EVALUATOR: Rate-Limiting Module

Verify the implementation thoroughly. Check all aspects:

1. Syntax validity
2. Code style
3. Performance
4. Security
5. Documentation
6. Tests
7. Config
8. Backwards compatibility
9. Error handling
10. Logging
11. Monitoring
12. ...

For each check, provide detailed analysis with tables...
```

**Problem:** 12+ checks, vague criteria, asks for tables → timeout

### Example: JUST RIGHT ✅

```markdown
## EVALUATOR: Rate-Limiting Module

Verify the generator's implementation. Check these 5 things:

1. **Syntax:** `node -c middleware/rateLimiter.js`
2. **Tests pass:** `npm test -- rateLimiter`
3. **Config valid:** `jq . config/rateLimit.json`
4. **Docs exist:** `wc -l docs/rate-limiting.md` (>20 lines)
5. **Smoke test:** `timeout 5s node -e "require('./middleware/rateLimiter')"`

### Output Format

- Check 1: PASS/FAIL — [one line]
- ...

**Final:** PASS/FAIL
```

**Result:** 5 checks, concrete commands, plain output → completes in 5-8 min

---

## 🔄 ITERATION PROTOCOL

### First Evaluation: FAIL

Output template when generator's work fails checks:

```markdown
## EVALUATION RESULT: FAIL (2/5 checks passed)

**Failed checks:**

- Check 1: FAIL — Syntax error at line 42 (bash -n script.sh)
- Check 4: FAIL — Missing file: config.json (ls check)

**Passed checks:**

- Check 2: PASS — No hardcoded paths
- Check 3: PASS — Git diff clean
- Check 5: PASS — Smoke test passed

**ACTION REQUIRED:**

Generator must fix:
1. Syntax error on line 42
2. Create missing config.json

Re-spawn generator with this feedback.
```

### Second Evaluation: Re-verify

```markdown
## EVALUATOR: [Task] (Re-verification)

Generator reported fixes. Re-check the 2 failed items:

1. **Syntax valid:** (previously failed)
   → Command: `bash -n script.sh`

2. **File exists:** (previously failed)
   → Command: `ls -la config.json`

### Output Format

- Check 1: PASS/FAIL — [fixed / still broken]
- Check 2: PASS/FAIL — [file created / still missing]

**Final:** PASS/FAIL

(No need to re-check items that passed first time)
```

**Max 2 iterations.** If fails again → escalate to human.

---

## 🛠️ TEMPLATE USAGE EXAMPLES

### Real Task: Verify Script Implementation

```markdown
## EVALUATOR: Garmin Health Report Script

Verify scripts/garmin-health-report.sh. Check these 5 things:

1. **Syntax valid:** Script has no syntax errors
   → Command: `bash -n scripts/garmin-health-report.sh`

2. **Executable:** Has execute permission
   → Command: `test -x scripts/garmin-health-report.sh && echo PASS || echo FAIL`

3. **No secrets:** No API keys hardcoded
   → Command: `grep -i "api_key\|apikey\|secret" scripts/garmin-health-report.sh`

4. **Help works:** --help flag returns usage
   → Command: `./scripts/garmin-health-report.sh --help | head -5`

5. **Dry-run:** Runs without errors in dry-run mode
   → Command: `timeout 10s ./scripts/garmin-health-report.sh --dry-run`

### Output Format

- Check 1: PASS/FAIL — [one line]
- Check 2: PASS/FAIL — [one line]
- Check 3: PASS/FAIL — [one line]
- Check 4: PASS/FAIL — [one line]
- Check 5: PASS/FAIL — [one line]

**Final:** PASS/FAIL (5/5 = PASS)

Working directory: /home/mleon/.openclaw/workspace
```

### Real Task: Verify Memory Documentation

```markdown
## EVALUATOR: Subagent Best Practices Doc

Verify memory/subagent-best-practices.md. Check these 5 things:

1. **File exists:** File created and non-empty
   → Command: `wc -l memory/subagent-best-practices.md`

2. **Timeout section:** Contains 600s default
   → Command: `grep "600" memory/subagent-best-practices.md`

3. **Ralph Wiggum section:** Documents pre-validation checks
   → Command: `grep -i "ralph wiggum\|pre-validation" memory/subagent-best-practices.md`

4. **Examples:** At least 2 code blocks with examples
   → Command: `grep -c '```' memory/subagent-best-practices.md` (≥4)

5. **No TODOs:** No unfinished sections
   → Command: `grep -i "TODO\|FIXME\|TBD" memory/subagent-best-practices.md`

### Output Format

- Check 1: PASS/FAIL — [file has X lines / file missing]
- Check 2: PASS/FAIL — [600s found / not found]
- Check 3: PASS/FAIL — [section exists / missing]
- Check 4: PASS/FAIL — [found N blocks / too few]
- Check 5: PASS/FAIL — [no TODOs / found N TODOs]

**Final:** PASS/FAIL (5/5 = PASS)

Working directory: /home/mleon/.openclaw/workspace
```

---

## 📊 BEFORE/AFTER COMPARISON

### OLD STYLE (Causes Timeouts) ❌

```markdown
Thoroughly evaluate the generator's implementation of the rate-limiting feature.

Check all aspects of code quality, performance, security, documentation, and tests.
Provide a detailed analysis with:
- Table of findings
- Severity ratings
- Recommendations for improvement
- Comparison with industry best practices

Be thorough and don't miss anything.
```

**Problems:**
- No concrete checklist
- "Thorough" → exhaustive search
- Tables → complex formatting
- Open-ended → agent keeps searching
- **Result:** Timeout at 9 min with incomplete analysis

### NEW STYLE (Completes in <10 min) ✅

```markdown
## EVALUATOR: Rate-Limiting Module

Check these 5 things:

1. **Tests pass:** `npm test -- rateLimiter`
2. **Syntax valid:** `node -c middleware/rateLimiter.js`
3. **Config valid:** `jq . config/rateLimit.json`
4. **Docs exist:** `wc -l docs/rate-limiting.md` (>20 lines)
5. **Smoke test:** `timeout 5s node -e "require('./middleware/rateLimiter')"`

### Output Format

- Check 1: PASS/FAIL — [one line]
- Check 2: PASS/FAIL — [one line]
- Check 3: PASS/FAIL — [one line]
- Check 4: PASS/FAIL — [one line]
- Check 5: PASS/FAIL — [one line]

**Final:** PASS/FAIL
```

**Improvements:**
- 5 concrete checks (not "all aspects")
- One command per check (not "analyze")
- Plain text output (not tables)
- Explicit scope (not "don't miss anything")
- **Result:** Completes in 6 min with clear PASS/FAIL

---

## 🎯 TL;DR

1. **5-7 checks max** (not 10+)
2. **One bash command per check** (produces PASS/FAIL)
3. **Plain text output** (no tables/reports)
4. **Explicit scope** ("check THESE things, nothing more")
5. **Binary result** (PASS/FAIL, not detailed analysis)

**Copy template → Fill in 5 checks → Done.**

**Prompt length:** 500-800 chars ideal, never >1500.

**Completion time:** <10 min consistently.
