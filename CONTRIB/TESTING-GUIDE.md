# Testing Guide for OpenClaw Contributions

## Testing Environment Setup

### Option A: Fresh VM (Recommended)
```bash
# Create Ubuntu 22.04+ VM (DigitalOcean, Hetzner, local VM)
# Install OpenClaw from scratch
curl -fsSL https://get.openclaw.dev | bash  # or whatever the official install is

# Clone your fork
git clone https://github.com/YOUR_USER/openclaw.git
cd openclaw
git checkout your-feature-branch
```

### Option B: Docker (Quick)
```bash
# If OpenClaw provides a Docker image
docker run -it --rm openclaw/openclaw:latest bash
# Copy your scripts in and test
```

## Test Checklist (Per Script)

### 1. Environment Independence
- [ ] No hardcoded paths — uses `$OPENCLAW_WORKSPACE` or defaults
- [ ] No user-specific references
- [ ] Works with default OpenClaw installation
- [ ] Handles missing optional dependencies gracefully

### 2. Functionality
- [ ] `--help` works and is accurate
- [ ] All documented options work
- [ ] Dry-run mode doesn't modify anything
- [ ] Normal mode produces expected results
- [ ] Error cases handled (missing files, permissions, etc.)

### 3. Safety
- [ ] No destructive operations without confirmation
- [ ] Backup created before modifications
- [ ] Rollback works if applicable
- [ ] No data leaves the machine unexpectedly

### 4. Compatibility
- [ ] Works on Ubuntu 22.04+
- [ ] Works on Debian 12+
- [ ] Bash 5.0+ (no bashisms that break on older versions)
- [ ] Dependencies documented and checked at runtime

## Running Tests

### Skill Security Audit
```bash
# Create a test skill with known patterns
mkdir -p /tmp/test-skill
cat > /tmp/test-skill/SKILL.md << 'EOF'
# Test Skill
A skill that does network things.
EOF

cat > /tmp/test-skill/run.sh << 'EOF'
#!/bin/bash
curl https://example.com
eval "$USER_INPUT"
EOF

# Run audit — should flag curl and eval
bash scripts/skill-security-audit.sh /tmp/test-skill
# Expected: warnings for curl (network) and eval (execution)
```

### Memory Guardian
```bash
# Create test memory structure
export OPENCLAW_WORKSPACE=/tmp/test-workspace
mkdir -p $OPENCLAW_WORKSPACE/memory
echo "test content" > $OPENCLAW_WORKSPACE/memory/2025-01-01.md
echo "" > $OPENCLAW_WORKSPACE/memory/empty-file.md

# Run analysis
bash scripts/memory-guardian.sh --analyze
# Expected: reports on file sizes, flags empty file

# Dry-run clean
bash scripts/memory-guardian.sh --clean --dry-run
# Expected: shows what would be removed, removes nothing
```

### Critical Update
```bash
# Create test config
echo "TestOption yes" > /tmp/test-config

# Baseline
bash scripts/critical-update.sh --baseline

# Dry-run apply
bash scripts/critical-update.sh --dry-run /tmp/test-config
# Expected: shows what would happen, no changes
```

## Reporting Test Results

When submitting a PR, include:
```markdown
## Testing

Tested on:
- Ubuntu 22.04 LTS (fresh install)
- OpenClaw v0.x.x
- Bash 5.1.16

Results:
- [x] All options work as documented
- [x] Dry-run is non-destructive
- [x] Error handling works for edge cases
- [x] No hardcoded paths remain
```
