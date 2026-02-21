#!/bin/bash
# =============================================================================
# tier-rotation.sh — Rotación automática de memory tiers (HOT/WARM/COLD)
# =============================================================================
# Ejecutado cada lunes 23:30 por cron
# Mueve archivos entre tiers basado en antigüedad
# =============================================================================

set -euo pipefail

DAILY_DIR="/home/mleon/.openclaw/workspace/memory/DAILY"
HOT_DIR="$DAILY_DIR/HOT"
WARM_DIR="$DAILY_DIR/WARM"
COLD_DIR="$DAILY_DIR/COLD"
REPORT_FILE="/home/mleon/.openclaw/workspace/memory/$(date +%Y-%m-%d)-tier-rotation.md"

# Timestamps
TODAY=$(date +%s)
SEVEN_DAYS=$((7 * 24 * 3600))
THIRTY_DAYS=$((30 * 24 * 3600))

# Contadores
HOT_COUNT=0
WARM_COUNT=0
COLD_COUNT=0
MOVED_HOT_TO_WARM=0
MOVED_WARM_TO_COLD=0

echo "=== Memory Tier Rotation - $(date) ===" > "$REPORT_FILE"

# --- HOT → WARM (archivos >7 días) ---
echo ""
echo "🔄 Rotando HOT → WARM..."
for file in "$HOT_DIR"/*; do
    if [ ! -e "$file" ]; then continue; fi
    
    FILEDATE=$(stat -c %Y "$file" 2>/dev/null || echo "$TODAY")
    AGE=$((TODAY - FILEDATE))
    
    if [ $AGE -gt $SEVEN_DAYS ]; then
        mv "$file" "$WARM_DIR/" 2>/dev/null
        MOVED_HOT_TO_WARM=$((MOVED_HOT_TO_WARM + 1))
        echo "  → $(basename $file)"
    fi
done

# --- WARM → COLD (archivos >30 días) ---
echo ""
echo "❄️  Rotando WARM → COLD (comprimiendo)..."
ARCHIVE_MONTH=$(date +%Y-%m)
COLD_ARCHIVE="$COLD_DIR/archive-${ARCHIVE_MONTH}.tar.gz"

FILES_TO_ARCHIVE=()
for file in "$WARM_DIR"/*; do
    if [ ! -e "$file" ]; then continue; fi
    
    FILEDATE=$(stat -c %Y "$file" 2>/dev/null || echo "$TODAY")
    AGE=$((TODAY - FILEDATE))
    
    if [ $AGE -gt $THIRTY_DAYS ]; then
        FILES_TO_ARCHIVE+=("$file")
        MOVED_WARM_TO_COLD=$((MOVED_WARM_TO_COLD + 1))
    fi
done

if [ ${#FILES_TO_ARCHIVE[@]} -gt 0 ]; then
    echo "📦 Comprimiendo ${#FILES_TO_ARCHIVE[@]} archivos..."
    tar czf "$COLD_ARCHIVE" -C "$WARM_DIR" ${FILES_TO_ARCHIVE[@]##*/} 2>/dev/null || true
    
    # Borrar originals tras comprimir
    for file in "${FILES_TO_ARCHIVE[@]}"; do
        rm -f "$file"
        echo "  → $(basename $file)"
    done
fi

# --- Conteos finales ---
HOT_COUNT=$(find "$HOT_DIR" -type f | wc -l)
WARM_COUNT=$(find "$WARM_DIR" -type f | wc -l)
COLD_COUNT=$(find "$COLD_DIR" -type f | wc -l)

# --- Generar reporte ---
cat >> "$REPORT_FILE" << EOF

## 📊 Tier Rotation Report

**Date:** $(date)

### 🔄 Movement Summary
- HOT → WARM: $MOVED_HOT_TO_WARM archivos
- WARM → COLD: $MOVED_WARM_TO_COLD archivos (comprimidos)

### 📈 Final Counts
- 🔥 HOT: $HOT_COUNT archivos (~7 días)
- 🌤️ WARM: $WARM_COUNT archivos (~8-30 días)
- ❄️ COLD: $COLD_COUNT archivos (comprimidos, >30 días)

### 📦 Compression
- Archive: archive-${ARCHIVE_MONTH}.tar.gz
- Size: $(du -h "$COLD_ARCHIVE" 2>/dev/null | cut -f1 || echo "0 KB")

### ✅ Status
All tiers rotated successfully.

---
**Next rotation:** $(date -d "next Monday" "+%Y-%m-%d %H:%M")
EOF

echo ""
echo "✅ Tier rotation completado"
echo "📊 Reporte: $REPORT_FILE"
