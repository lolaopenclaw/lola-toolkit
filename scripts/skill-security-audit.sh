#!/usr/bin/env bash
# ============================================================
# Skill Security Audit — OpenClaw
# Analyzes ClawHub skills for security risks before installation
# Usage: bash scripts/skill-security-audit.sh [SKILL_NAME|PATH] [OPTIONS]
# ============================================================
set -uo pipefail

# --- Config ---
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SKILLS_DIR="$WORKSPACE/skills"
AUDITS_DIR="$WORKSPACE/memory/audits"
REGISTRY="$WORKSPACE/memory/skill-audit-registry.md"
DATE=$(date +%Y-%m-%d)
SCORE=0
FINDINGS=()
WARNINGS=0
ERRORS=0
CLEAN=0

# --- Colors ---
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Flags (global) ---
JSON_OUTPUT=false
STRICT_MODE=false
SCORE_ONLY=false
SAVE_REPORT=false
DETAILED=false
AUDIT_ALL=false

# --- Usage ---
usage() {
    cat <<EOF
${BOLD}Skill Security Audit — OpenClaw${NC}

Analyzes ClawHub skills for security risks before installation.

Usage: $0 <SKILL_NAME|PATH> [OPTIONS]

Positional Arguments:
  SKILL_NAME|PATH  Skill name (from \$OPENCLAW_WORKSPACE/skills/) or local path

Options:
  --analyze        Full analysis (default)
  --report         Generate markdown report to memory/audits/
  --score          Only show risk score
  --json           Output as JSON (for automation)
  --strict         Fail on any warnings (exit code 1)
  --detailed       Deep analysis with dependency tree
  --all            Audit all installed skills
  -h, --help       Show this help

Risk Scores:
  0-24   🟢 VERDE    — Install with confidence
  25-49  🟢 BAJO     — Probably OK
  50-74  🟡 AMARILLO — Review before installing
  75-94  🟡 MEDIO    — Needs thorough audit
  95-100 🔴 CRÍTICO  — Do NOT install

Examples:
  # Analyze a skill interactively
  $0 my-skill

  # Get risk score only
  $0 my-skill --score

  # Output as JSON (for CI/CD)
  $0 my-skill --json

  # Fail if any warnings (for strict checks)
  $0 my-skill --strict --json

  # Audit all installed skills
  $0 --all --report

Environment:
  OPENCLAW_WORKSPACE    Base workspace path (default: \$HOME/.openclaw/workspace)
  STRICTNESS            Override --strict via env (1=strict, 0=lenient)
EOF
    exit 0
}

# --- Helpers ---
add_finding() {
    local severity="$1" msg="$2" points="$3"
    FINDINGS+=("${severity}|${msg}")
    SCORE=$((SCORE + points))
    case "$severity" in
        CRITICAL|HIGH) ((ERRORS++)) ;;
        MEDIUM) ((WARNINGS++)) ;;
        LOW|INFO) ((CLEAN++)) ;;
    esac
}

score_label() {
    local s=$1
    if [ "$s" -ge 95 ]; then echo "🔴 CRÍTICO (no instalar)"
    elif [ "$s" -ge 75 ]; then echo "🟡 RIESGO MEDIO (auditar)"
    elif [ "$s" -ge 50 ]; then echo "🟡 AMARILLO (revisar)"
    elif [ "$s" -ge 25 ]; then echo "🟢 BAJO (probably OK)"
    else echo "🟢 VERDE (instalar)"; fi
}

score_status() {
    local s=$1
    if [ "$s" -ge 75 ]; then echo "RED"
    elif [ "$s" -ge 50 ]; then echo "YELLOW"
    else echo "GREEN"; fi
}

# --- Analysis Functions ---

analyze_code() {
    local dir="$1"
    echo -e "${CYAN}[1/5] Code Analysis...${NC}"

    # Dangerous eval/exec patterns
    local eval_count
    eval_count=$(grep -rn -E '\beval[[:space:]]*\(' "$dir" --include="*.js" --include="*.ts" --include="*.py" 2>/dev/null | grep -v node_modules | grep -v '\.min\.' | wc -l)
    eval_count=$((eval_count + $(grep -rn 'eval[[:space:]]*"' "$dir" --include="*.sh" 2>/dev/null | grep -v '#' | wc -l)))
    eval_count=$((eval_count + $(grep -rn "eval[[:space:]]*'" "$dir" --include="*.sh" 2>/dev/null | grep -v '#' | wc -l)))
    if [ "$eval_count" -gt 0 ]; then
        add_finding "HIGH" "Found $eval_count eval() calls — potential code injection" 20
    else
        add_finding "LOW" "No eval() calls found" 0
    fi

    local exec_count
    exec_count=$(grep -rn 'exec(' "$dir" --include="*.js" --include="*.ts" --include="*.py" 2>/dev/null | grep -v node_modules | grep -v 'child_process' | wc -l)
    if [ "$exec_count" -gt 3 ]; then
        add_finding "HIGH" "Found $exec_count exec() calls — review carefully" 15
    elif [ "$exec_count" -gt 0 ]; then
        add_finding "MEDIUM" "Found $exec_count exec() calls" 8
    fi

    # Hardcoded URLs (fetch/curl/axios)
    local url_count
    url_count=$(grep -rn -E '(fetch|axios|curl|wget|http\.get|https\.get)\s*\(' "$dir" --include="*.js" --include="*.ts" --include="*.py" --include="*.sh" 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$url_count" -gt 5 ]; then
        add_finding "HIGH" "Found $url_count network calls — possible data exfiltration" 20
    elif [ "$url_count" -gt 0 ]; then
        add_finding "MEDIUM" "Found $url_count network calls — review endpoints" 8
    else
        add_finding "LOW" "No outbound network calls detected" 0
    fi

    # Filesystem access
    local fs_count
    fs_count=$(grep -rn -E '(fs\.(read|write|unlink|rmdir|mkdir|rename)|readFile|writeFile|appendFile|createReadStream|createWriteStream)' "$dir" --include="*.js" --include="*.ts" 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$fs_count" -gt 10 ]; then
        add_finding "MEDIUM" "Heavy filesystem access ($fs_count calls) — verify scope" 10
    elif [ "$fs_count" -gt 0 ]; then
        add_finding "INFO" "Found $fs_count filesystem operations" 3
    fi

    # Prompt injection patterns
    local injection_count
    injection_count=$(grep -rn -iE '(ignore previous|disregard|forget your|you are now|new instructions|system prompt)' "$dir" --include="*.md" --include="*.txt" --include="*.js" --include="*.ts" 2>/dev/null | grep -v node_modules | grep -v audit | wc -l)
    if [ "$injection_count" -gt 0 ]; then
        add_finding "CRITICAL" "Found $injection_count potential prompt injection patterns!" 30
    else
        add_finding "LOW" "No prompt injection patterns detected" 0
    fi

    # Shell command execution
    local shell_count
    shell_count=$(grep -rn -E '(child_process|spawn\(|execSync|spawnSync|shelljs|\.system\()' "$dir" --include="*.js" --include="*.ts" --include="*.py" 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$shell_count" -gt 0 ]; then
        add_finding "HIGH" "Found $shell_count shell execution patterns" 15
    fi

    # Obfuscated code
    local obf_count
    obf_count=$(grep -rn -E '(atob|btoa|Buffer\.from.*base64|fromCharCode|\\x[0-9a-f]{2})' "$dir" --include="*.js" --include="*.ts" 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$obf_count" -gt 3 ]; then
        add_finding "HIGH" "Found $obf_count obfuscation patterns — suspicious" 20
    elif [ "$obf_count" -gt 0 ]; then
        add_finding "MEDIUM" "Found $obf_count encoding/decode patterns" 5
    fi
}

analyze_credentials() {
    local dir="$1"
    echo -e "${CYAN}[2/5] Credential Detection...${NC}"

    # Hardcoded secrets
    local secret_count
    secret_count=$(grep -rn -iE '(api_key|apikey|api\.key|password|passwd|secret|token|auth_token|access_token|private_key)\s*[=:]\s*["\x27][^"\x27]{8,}' "$dir" 2>/dev/null | grep -v node_modules | grep -v '\.example' | grep -v 'process\.env' | grep -v 'ENV\[' | wc -l)
    if [ "$secret_count" -gt 0 ]; then
        add_finding "CRITICAL" "Found $secret_count hardcoded credentials!" 30
    else
        add_finding "LOW" "No hardcoded credentials found" 0
    fi

    # .env files committed
    if find "$dir" -name ".env" -not -path "*/node_modules/*" -not -name ".env.example" 2>/dev/null | grep -q .; then
        add_finding "HIGH" ".env file found in skill directory — credentials may be exposed" 15
    fi

    # Config files with sensitive data
    local config_secrets
    config_secrets=$(find "$dir" -name "config.json" -o -name "config.yaml" -o -name "config.yml" 2>/dev/null | xargs grep -l -iE '(password|secret|token|key)' 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$config_secrets" -gt 0 ]; then
        add_finding "MEDIUM" "Config files may contain sensitive values — verify they use env vars" 10
    fi

    # process.env usage (good practice)
    local env_usage
    env_usage=$(grep -rn 'process\.env' "$dir" --include="*.js" --include="*.ts" 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$env_usage" -gt 0 ]; then
        add_finding "INFO" "Uses process.env ($env_usage refs) — good practice for secrets" 0
    fi
}

analyze_dependencies() {
    local dir="$1"
    echo -e "${CYAN}[3/5] Dependency Audit...${NC}"

    local pkg="$dir/package.json"
    if [ ! -f "$pkg" ]; then
        add_finding "INFO" "No package.json — no npm dependencies" 0
        return
    fi

    # Count deps
    local dep_count
    dep_count=$(python3 -c "
import json,sys
try:
    d=json.load(open('$pkg'))
    print(len(d.get('dependencies',{}))+len(d.get('devDependencies',{})))
except: print(0)
" 2>/dev/null)

    if [ "$dep_count" -gt 20 ]; then
        add_finding "MEDIUM" "High dependency count ($dep_count) — larger attack surface" 10
    elif [ "$dep_count" -gt 0 ]; then
        add_finding "INFO" "$dep_count dependencies found" 2
    fi

    # Unpinned versions
    local unpinned
    unpinned=$(python3 -c "
import json,re,sys
try:
    d=json.load(open('$pkg'))
    deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}
    count=sum(1 for v in deps.values() if re.match(r'^[\^~>]',str(v)))
    print(count)
except: print(0)
" 2>/dev/null)

    if [ "$unpinned" -gt 0 ]; then
        add_finding "MEDIUM" "$unpinned dependencies not pinned to exact version" 5
    fi

    # npm audit (if node_modules exist)
    if [ -d "$dir/node_modules" ]; then
        local audit_result
        audit_result=$(cd "$dir" && npm audit --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    v=d.get('metadata',{}).get('vulnerabilities',{})
    crit=v.get('critical',0)+v.get('high',0)
    med=v.get('moderate',0)
    print(f'{crit},{med}')
except: print('0,0')
" 2>/dev/null || echo "0,0")
        local crit_high med
        crit_high=$(echo "$audit_result" | cut -d, -f1)
        med=$(echo "$audit_result" | cut -d, -f2)
        if [ "$crit_high" -gt 0 ]; then
            add_finding "HIGH" "npm audit: $crit_high critical/high vulnerabilities" 15
        fi
        if [ "$med" -gt 0 ]; then
            add_finding "MEDIUM" "npm audit: $med moderate vulnerabilities" 5
        fi
    fi

    # List deps for report
    if [ "$DETAILED" = true ]; then
        echo -e "  Dependencies:"
        python3 -c "
import json
try:
    d=json.load(open('$pkg'))
    for name,ver in d.get('dependencies',{}).items():
        print(f'    - {name}: {ver}')
except: pass
" 2>/dev/null
    fi
}

analyze_permissions() {
    local dir="$1"
    echo -e "${CYAN}[4/5] Permission Analysis...${NC}"

    # Executable files
    local exec_files
    exec_files=$(find "$dir" -type f -executable -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l)
    if [ "$exec_files" -gt 5 ]; then
        add_finding "MEDIUM" "$exec_files executable files — review necessity" 5
    fi

    # Access to sensitive paths
    local sensitive_access
    sensitive_access=$(grep -rn -E '(/etc/passwd|/etc/shadow|~/.ssh|\.openclaw/credentials|\.env|/proc/|/sys/)' "$dir" --include="*.js" --include="*.ts" --include="*.sh" --include="*.py" 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$sensitive_access" -gt 0 ]; then
        add_finding "CRITICAL" "Accesses sensitive system paths ($sensitive_access refs)" 25
    fi

    # Network listeners
    local listener_count
    listener_count=$(grep -rn -E '(\.listen\(|createServer|\.bind\()' "$dir" --include="*.js" --include="*.ts" 2>/dev/null | grep -v node_modules | wc -l)
    if [ "$listener_count" -gt 0 ]; then
        add_finding "HIGH" "Opens network listeners ($listener_count) — verify necessity" 15
    fi

    # File count and size
    local file_count total_size
    file_count=$(find "$dir" -type f -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l)
    total_size=$(du -sh "$dir" --exclude=node_modules --exclude=.git 2>/dev/null | cut -f1)
    add_finding "INFO" "Skill contains $file_count files ($total_size)" 0
}

analyze_skill_metadata() {
    local dir="$1"
    echo -e "${CYAN}[5/5] Metadata Analysis...${NC}"

    # SKILL.md existence
    if [ ! -f "$dir/SKILL.md" ]; then
        add_finding "MEDIUM" "No SKILL.md found — missing documentation" 5
    fi

    # Author info
    local author="Unknown"
    if [ -f "$dir/SKILL.md" ]; then
        author=$(grep -i 'author' "$dir/SKILL.md" 2>/dev/null | head -1 | sed 's/.*:\s*//' || echo "Unknown")
    fi
    if [ -f "$dir/package.json" ]; then
        local pkg_author
        pkg_author=$(python3 -c "import json; print(json.load(open('$dir/package.json')).get('author',''))" 2>/dev/null || true)
        [ -n "$pkg_author" ] && author="$pkg_author"
    fi

    # Version
    local version="unknown"
    if [ -f "$dir/package.json" ]; then
        version=$(python3 -c "import json; print(json.load(open('$dir/package.json')).get('version','unknown'))" 2>/dev/null || echo "unknown")
    fi

    echo "$author" > /tmp/skill_author
    echo "$version" > /tmp/skill_version
}

# --- JSON Output ---
generate_json() {
    local skill_name="$1" dir="$2"
    local author version
    author=$(cat /tmp/skill_author 2>/dev/null || echo "Unknown")
    version=$(cat /tmp/skill_version 2>/dev/null || echo "unknown")

    [ "$SCORE" -gt 100 ] && SCORE=100

    # Build findings array
    local findings_json="["
    local first=true
    for f in "${FINDINGS[@]}"; do
        local sev msg
        sev=$(echo "$f" | cut -d'|' -f1)
        msg=$(echo "$f" | cut -d'|' -f2-)
        if [ "$first" = false ]; then findings_json="$findings_json,"; fi
        findings_json="${findings_json}{\"severity\":\"$sev\",\"message\":\"$(echo "$msg" | sed 's/"/\\"/g')\"}"
        first=false
    done
    findings_json="$findings_json]"

    # Output JSON
    python3 << PYJSON
import json, sys
data = {
    "skill": "$skill_name",
    "version": "$version",
    "author": "$author",
    "date": "$DATE",
    "score": $SCORE,
    "label": "$(score_label "$SCORE")",
    "status": "$(score_status "$SCORE")",
    "summary": {
        "errors": $ERRORS,
        "warnings": $WARNINGS,
        "clean": $CLEAN
    },
    "findings": json.loads('$findings_json'),
    "pass_strict": $([[ $ERRORS -eq 0 ]] && echo "true" || echo "false"),
    "installable": $([[ $SCORE -lt 75 ]] && echo "true" || echo "false")
}
print(json.dumps(data, indent=2))
PYJSON
}

# --- Report Generation ---
generate_report() {
    local skill_name="$1" dir="$2"
    local author version label status
    author=$(cat /tmp/skill_author 2>/dev/null || echo "Unknown")
    version=$(cat /tmp/skill_version 2>/dev/null || echo "unknown")

    # Cap score at 100
    [ "$SCORE" -gt 100 ] && SCORE=100

    label=$(score_label "$SCORE")
    status=$(score_status "$SCORE")

    echo ""
    echo -e "${BOLD}===== SKILL SECURITY AUDIT =====${NC}"
    echo -e "Skill:   ${BOLD}$skill_name${NC}"
    echo -e "Version: $version"
    echo -e "Author:  $author"
    echo -e "Date:    $DATE"
    echo ""
    echo -e "RISK SCORE: ${BOLD}$SCORE/100${NC} — $label"
    echo ""
    echo -e "${BOLD}FINDINGS:${NC}"
    for f in "${FINDINGS[@]}"; do
        local sev msg
        sev=$(echo "$f" | cut -d'|' -f1)
        msg=$(echo "$f" | cut -d'|' -f2-)
        case "$sev" in
            CRITICAL) echo -e "  ${RED}🔴 [CRITICAL]${NC} $msg" ;;
            HIGH)     echo -e "  ${RED}⛔ [HIGH]${NC} $msg" ;;
            MEDIUM)   echo -e "  ${YELLOW}⚠️  [MEDIUM]${NC} $msg" ;;
            LOW)      echo -e "  ${GREEN}✅ [LOW]${NC} $msg" ;;
            INFO)     echo -e "  ℹ️  [INFO] $msg" ;;
        esac
    done
    echo ""
    echo -e "Summary: $ERRORS errors, $WARNINGS warnings, $CLEAN clean"
    echo -e "Status:  $status"
    echo "================================"

    # Save markdown report
    if [ "$SAVE_REPORT" = true ]; then
        local report_file="$AUDITS_DIR/${skill_name}-audit-${DATE}.md"
        mkdir -p "$AUDITS_DIR"
        cat > "$report_file" <<REPORT
# 🔒 Security Audit: $skill_name

**Date:** $DATE
**Version:** $version
**Author:** $author
**Risk Score:** $SCORE/100 — $label

## Findings

| Severity | Finding |
|----------|---------|
$(for f in "${FINDINGS[@]}"; do
    sev=$(echo "$f" | cut -d'|' -f1)
    msg=$(echo "$f" | cut -d'|' -f2-)
    case "$sev" in
        CRITICAL) echo "| 🔴 CRITICAL | $msg |" ;;
        HIGH)     echo "| ⛔ HIGH | $msg |" ;;
        MEDIUM)   echo "| ⚠️ MEDIUM | $msg |" ;;
        LOW)      echo "| ✅ LOW | $msg |" ;;
        INFO)     echo "| ℹ️ INFO | $msg |" ;;
    esac
done)

## Summary

- **Errors:** $ERRORS
- **Warnings:** $WARNINGS
- **Clean checks:** $CLEAN
- **Status:** $status

## Recommendation

$(if [ "$SCORE" -ge 75 ]; then
    echo "⛔ **DO NOT INSTALL** without thorough manual review and fixes."
elif [ "$SCORE" -ge 50 ]; then
    echo "⚠️ **Review carefully** before installing. Address warnings first."
elif [ "$SCORE" -ge 25 ]; then
    echo "🟢 **Probably safe.** Quick review recommended."
else
    echo "🟢 **Install with confidence.** Low risk."
fi)
REPORT
        echo -e "\n📄 Report saved: $report_file"
    fi
}

# --- Audit All ---
audit_all() {
    echo -e "${BOLD}Auditing all installed skills...${NC}\n"
    local results=()
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ ! -d "$skill_dir" ] && continue
        local name
        name=$(basename "$skill_dir")
        # Reset per-skill
        SCORE=0; FINDINGS=(); WARNINGS=0; ERRORS=0; CLEAN=0
        analyze_code "$skill_dir"
        analyze_credentials "$skill_dir"
        analyze_dependencies "$skill_dir"
        analyze_permissions "$skill_dir"
        analyze_skill_metadata "$skill_dir"
        [ "$SCORE" -gt 100 ] && SCORE=100
        local label
        label=$(score_label "$SCORE")
        results+=("$SCORE|$name|$label")
        if [ "$SAVE_REPORT" = true ]; then
            generate_report "$name" "$skill_dir" > /dev/null 2>&1
        fi
    done

    echo -e "\n${BOLD}===== AUDIT SUMMARY =====${NC}"
    printf "%-30s %-6s %s\n" "SKILL" "SCORE" "STATUS"
    printf "%-30s %-6s %s\n" "-----" "-----" "------"
    IFS=$'\n'
    for r in $(printf '%s\n' "${results[@]}" | sort -t'|' -k1 -nr); do
        local sc nm lb
        sc=$(echo "$r" | cut -d'|' -f1)
        nm=$(echo "$r" | cut -d'|' -f2)
        lb=$(echo "$r" | cut -d'|' -f3-)
        printf "%-30s %-6s %s\n" "$nm" "$sc" "$lb"
    done
    unset IFS
}

# --- Main ---
SKILL_INPUT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --analyze) shift ;;
        --report) SAVE_REPORT=true; shift ;;
        --score) SCORE_ONLY=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        --strict) STRICT_MODE=true; shift ;;
        --detailed) DETAILED=true; shift ;;
        --all) AUDIT_ALL=true; shift ;;
        -h|--help) usage ;;
        *) SKILL_INPUT="$1"; shift ;;
    esac
done

# Environment override for strict mode
[ "${STRICTNESS:-0}" = "1" ] && STRICT_MODE=true

if [ "$AUDIT_ALL" = true ]; then
    audit_all
    exit 0
fi

if [ -z "$SKILL_INPUT" ]; then
    echo "Error: Specify a skill name or path, or use --all"
    echo "Usage: $0 <SKILL_NAME|PATH> [--report] [--score] [--detailed]"
    exit 1
fi

# Resolve skill path
SKILL_DIR=""
if [ -d "$SKILL_INPUT" ]; then
    SKILL_DIR="$SKILL_INPUT"
elif [ -d "$SKILLS_DIR/$SKILL_INPUT" ]; then
    SKILL_DIR="$SKILLS_DIR/$SKILL_INPUT"
else
    echo "Error: Skill not found: $SKILL_INPUT"
    echo "Searched: $SKILL_INPUT, $SKILLS_DIR/$SKILL_INPUT"
    exit 1
fi

SKILL_NAME=$(basename "$SKILL_DIR")

echo -e "${BOLD}🔍 Auditing skill: $SKILL_NAME${NC}"
echo -e "   Path: $SKILL_DIR\n"

analyze_code "$SKILL_DIR"
analyze_credentials "$SKILL_DIR"
analyze_dependencies "$SKILL_DIR"
analyze_permissions "$SKILL_DIR"
analyze_skill_metadata "$SKILL_DIR"

if [ "$SCORE_ONLY" = true ]; then
    [ "$SCORE" -gt 100 ] && SCORE=100
    echo "$SCORE — $(score_label "$SCORE")"
    exit 0
fi

# Generate output
if [ "$JSON_OUTPUT" = true ]; then
    generate_json "$SKILL_NAME" "$SKILL_DIR"
else
    generate_report "$SKILL_NAME" "$SKILL_DIR"
fi

# Strict mode: fail if errors or warnings
if [ "$STRICT_MODE" = true ]; then
    if [ "$ERRORS" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
        exit 1
    fi
fi

exit 0
