#!/bin/bash
# Example: Security Scanner Integration
# Shows how to integrate security scanning into workflows

# Example 1: Pre-check user input before processing
echo "=== Example 1: Pre-check User Input ==="
USER_INPUT="Tell me about security"

if python3 scripts/security-scanner.py "$USER_INPUT" injection >/dev/null 2>&1; then
    echo "✅ Input is safe, processing..."
    # Process input here
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 2 ]; then
        echo "🚨 CRITICAL: Prompt injection detected. Input rejected."
        exit 1
    fi
fi
echo

# Example 2: Redact PII before sending/logging
echo "=== Example 2: Redact PII Before Sending ==="
AGENT_RESPONSE="Contact me at user@example.com or call 666123456"
echo "Original: $AGENT_RESPONSE"

CLEAN_RESPONSE=$(echo "$AGENT_RESPONSE" | python3 scripts/security-scanner.py - pii 2>/dev/null | jq -r '.pii_secrets.redacted_text // empty')
if [ -n "$CLEAN_RESPONSE" ]; then
    echo "Redacted: $CLEAN_RESPONSE"
    # Send clean version
else
    echo "No PII detected, sending original"
    # Send original
fi
echo

# Example 3: Check log file for secrets before committing
echo "=== Example 3: Audit Log Files ==="
if [ -f memory/daily-log.txt ]; then
    echo "Scanning memory/daily-log.txt for secrets..."
    python3 scripts/security-scanner.py "$(cat memory/daily-log.txt)" pii >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "⚠️  WARNING: Secrets detected in log file!"
        echo "Run: cat memory/daily-log.txt | python3 scripts/security-scanner.py - pii"
    else
        echo "✅ Log file is clean"
    fi
else
    echo "No log file found, skipping..."
fi
echo

# Example 4: Monitor runtime for loops (hypothetical)
echo "=== Example 4: Runtime Governance ==="
echo "NOTE: This requires tracking tool calls in a JSON file"
echo "Example tool_calls.json:"
cat <<'EOF'
[
  {"tool": "exec", "timestamp": "2026-03-24T20:00:00", "cost": 0.01},
  {"tool": "exec", "timestamp": "2026-03-24T20:01:00", "cost": 0.01}
]
EOF
echo
echo "Then use SecurityScanner.check_runtime_governance(tool_calls) in Python"
echo

# Example 5: Pre-commit hook
echo "=== Example 5: Pre-commit Hook ==="
echo "Add to .git/hooks/pre-commit:"
cat <<'EOF'
#!/bin/bash
# Scan staged files for secrets before committing
for file in $(git diff --cached --name-only); do
    if [ -f "$file" ]; then
        python3 scripts/security-scanner.py "$(cat $file)" pii >/dev/null 2>&1
        if [ $? -eq 1 ]; then
            echo "ERROR: Secrets detected in $file"
            echo "Redact secrets before committing."
            exit 1
        fi
    fi
done
EOF
echo

echo "=============================="
echo "Integration examples complete!"
echo "See skills/security-scanner/SKILL.md for more patterns"
