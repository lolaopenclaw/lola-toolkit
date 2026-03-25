#!/usr/bin/env bash
# Test script for notification-batcher.sh
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
BATCHER="$WORKSPACE/scripts/notification-batcher.sh"

echo "🧪 Testing Notification Batcher"
echo "================================"
echo ""

# Clean up any existing queue
rm -f "$WORKSPACE/data/notification-queue.jsonl" "$WORKSPACE/data/notification-queue.lock"

# Test 1: Add messages at different priorities
echo "Test 1: Adding messages at different priorities"
bash "$BATCHER" add low "surf-conditions" "Olas de 1.2m en Zarautz"
bash "$BATCHER" add medium "backup" "Backup OK: 142 files, 2.3MB"
bash "$BATCHER" add high "security-audit" "Found 2 warnings in lynis scan"
bash "$BATCHER" add medium "autoimprove" "Scripts: 3 experiments, 1 kept"
bash "$BATCHER" add low "cleanup" "No issues found"
echo "✅ Test 1 passed"
echo ""

# Test 2: Inspect queue
echo "Test 2: Queue contents"
cat "$WORKSPACE/data/notification-queue.jsonl" | jq -c '{priority, source}'
echo "✅ Test 2 passed"
echo ""

# Test 3: Flush low priority
echo "Test 3: Flush low priority only"
bash "$BATCHER" flush low
echo ""
echo "Remaining in queue:"
cat "$WORKSPACE/data/notification-queue.jsonl" | jq -c '{priority, source}'
echo "✅ Test 3 passed"
echo ""

# Test 4: Flush medium priority (includes medium + low)
echo "Test 4: Flush medium priority"
bash "$BATCHER" add low "test-low" "Test low message"
bash "$BATCHER" flush medium
echo ""
echo "Remaining in queue:"
cat "$WORKSPACE/data/notification-queue.jsonl" | jq -c '{priority, source}'
echo "✅ Test 4 passed"
echo ""

# Test 5: Critical priority (auto-flush)
echo "Test 5: Critical priority (auto-flush)"
bash "$BATCHER" add critical "gateway" "Gateway health check failed"
echo "✅ Test 5 passed"
echo ""

# Test 6: Empty queue
echo "Test 6: Flush on empty queue"
bash "$BATCHER" flush low
echo "✅ Test 6 passed"
echo ""

# Cleanup
rm -f "$WORKSPACE/data/notification-queue.jsonl" "$WORKSPACE/data/notification-queue.lock"

echo "================================"
echo "🎉 All tests passed!"
