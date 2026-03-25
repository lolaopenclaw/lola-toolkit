#!/bin/bash
# Test end-to-end del skill youtube-smart-transcript

echo "🧪 Test End-to-End: youtube-smart-transcript"
echo "============================================="
echo ""

# Video de prueba
VIDEO="dQw4w9WgXcQ"

echo "📹 Video de prueba: $VIDEO (Rick Astley - Never Gonna Give You Up)"
echo ""

# Test 1: Formato text
echo "Test 1: Formato text..."
OUTPUT=$(./youtube-smart-transcript.py "$VIDEO" 2>/dev/null | wc -l)
if [ "$OUTPUT" -gt 0 ]; then
    echo "✅ PASS: $OUTPUT líneas extraídas"
else
    echo "❌ FAIL: No se extrajo transcripción"
    exit 1
fi
echo ""

# Test 2: Formato JSON
echo "Test 2: Formato JSON..."
OUTPUT=$(./youtube-smart-transcript.py "$VIDEO" --format json 2>/dev/null | jq -r '.[0].text' 2>/dev/null)
if [ -n "$OUTPUT" ]; then
    echo "✅ PASS: JSON válido, primer segmento: $OUTPUT"
else
    echo "❌ FAIL: JSON inválido"
    exit 1
fi
echo ""

# Test 3: Formato SRT
echo "Test 3: Formato SRT..."
OUTPUT=$(./youtube-smart-transcript.py "$VIDEO" --format srt 2>/dev/null | head -1)
if [ "$OUTPUT" = "1" ]; then
    echo "✅ PASS: SRT válido"
else
    echo "❌ FAIL: SRT inválido"
    exit 1
fi
echo ""

# Test 4: Metadata
echo "Test 4: Metadata..."
OUTPUT=$(./youtube-smart-transcript.py "$VIDEO" --metadata 2>&1 | grep -c "method")
if [ "$OUTPUT" -gt 0 ]; then
    echo "✅ PASS: Metadata presente"
else
    echo "❌ FAIL: Metadata faltante"
    exit 1
fi
echo ""

# Test 5: Caché
echo "Test 5: Verificar caché..."
CACHE_FILE=~/.openclaw/workspace/youtube-transcripts/${VIDEO}_es_en.json
if [ -f "$CACHE_FILE" ]; then
    SIZE=$(stat -f%z "$CACHE_FILE" 2>/dev/null || stat -c%s "$CACHE_FILE" 2>/dev/null)
    echo "✅ PASS: Archivo de caché existe (${SIZE} bytes)"
else
    echo "❌ FAIL: Archivo de caché no existe"
    exit 1
fi
echo ""

echo "============================================="
echo "✅ Todos los tests completados exitosamente"
echo ""
echo "📊 Resumen:"
echo "  - Extracción text: OK"
echo "  - Extracción JSON: OK"
echo "  - Extracción SRT: OK"
echo "  - Metadata: OK"
echo "  - Caché: OK"
echo ""
echo "🎉 Skill listo para producción"
