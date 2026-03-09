#!/bin/bash
# Monitor GitHub #24586 — Robust Version (v2)
# Revisa el estado del issue #24586 con error handling

echo "🔍 Monitor GitHub #24586 — Status Check"
echo "=========================================="

# Verificar que gh CLI está disponible
if ! command -v gh &> /dev/null; then
  echo "❌ ERROR: gh CLI no está instalado"
  echo "Status: unavailable (missing gh)" > /tmp/github-24586-status.txt
  exit 1
fi

# Verificar autenticación
if ! gh auth status &> /dev/null; then
  echo "❌ ERROR: No estás autenticado en GitHub"
  echo "Status: unauthenticated" > /tmp/github-24586-status.txt
  exit 1
fi

echo "✅ GitHub CLI auth OK"
echo ""

# Intentar obtener el status del issue (con timeout)
echo "Consultando issue #24586..."
STATUS=$(timeout 30 gh issue view 24586 --repo openclaw/openclaw --json state 2>&1)
RESULT=$?

if [ $RESULT -eq 124 ]; then
  echo "⏱️ TIMEOUT: GitHub tardó demasiado (>30s)"
  echo "Status: timeout" > /tmp/github-24586-status.txt
  exit 1
elif [ $RESULT -ne 0 ]; then
  echo "❌ ERROR consultando issue:"
  echo "$STATUS"
  echo "Status: error" > /tmp/github-24586-status.txt
  exit 1
fi

# Parse del estado
STATE=$(echo "$STATUS" | grep -o '"state":"[^"]*"' | cut -d'"' -f4)

if [ -z "$STATE" ]; then
  echo "⚠️  No pudimos extraer el estado del issue"
  echo "Status: unknown" > /tmp/github-24586-status.txt
  exit 1
fi

echo "Estado actual: $STATE"
echo ""

# Evaluar y reportar
case "$STATE" in
  "CLOSED")
    echo "🎉 ¡RESUELTO! El issue fue cerrado"
    echo "Recomendación: Probar native cron delivery nuevamente en lugar del workaround curl"
    echo "Status: CLOSED - Ready to test native delivery" > /tmp/github-24586-status.txt
    ;;
  "OPEN")
    echo "📖 El issue sigue abierto"
    echo "Recomendación: Mantener workaround curl hasta que se resuelva"
    echo "Status: OPEN - Continue using curl workaround" > /tmp/github-24586-status.txt
    ;;
  *)
    echo "ⓘ Estado desconocido: $STATE"
    echo "Status: unknown ($STATE)" > /tmp/github-24586-status.txt
    ;;
esac

# Guardar resultado en memory para posteridad
mkdir -p ~/.openclaw/workspace/memory
echo "{\"date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"issue\": 24586, \"state\": \"$STATE\", \"recommendation\": \"See log\"}" > ~/.openclaw/workspace/memory/github-24586-last-check.json

echo ""
echo "✅ Check completado"
