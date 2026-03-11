#!/bin/bash
# migrate-to-local-models.sh
# Migra todos los crons y config de Anthropic → Ollama local
# Ejecutar DESPUÉS de reiniciar el gateway con Ollama detectado
set -e

echo "🔄 Migrando a modelos locales..."
echo ""

# === 1. CRONS CON model=haiku → ollama/qwen2.5:14b ===
echo "📋 Cambiando crons haiku → ollama/qwen2.5:14b..."

# model-reset-nightly → ESTE VA A 7B (resetea al default de chat)
echo "  → model-reset-nightly → ollama/qwen2.5:7b (reset al default)"
openclaw cron edit 600074f1-c32f-4fee-b45d-e84c611e1071 --model "ollama/qwen2.5:7b" 2>&1 | tail -1

# healthcheck:fail2ban → 14B
echo "  → healthcheck:fail2ban → 14B"
openclaw cron edit c8522805-6bc4-451e-887b-69866ddf5b95 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# Autoimprove Nightly x2 → 14B
echo "  → Autoimprove Nightly (1) → 14B"
openclaw cron edit 6018f037-1d26-4322-874e-d256c295a5b4 --model "ollama/qwen2.5:14b" 2>&1 | tail -1
echo "  → Autoimprove Nightly (2) → 14B"
openclaw cron edit dcae7b06-e6fb-40d4-88bc-9bc618feb70d --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# OpenClaw release check → 14B
echo "  → OpenClaw release check → 14B"
openclaw cron edit b491ec4a-e1c3-4be8-b0a5-2ff291d99389 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# healthcheck:rkhunter → 14B
echo "  → healthcheck:rkhunter → 14B"
openclaw cron edit 78d3556f-a203-455d-b718-b9ac7c183dbc --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# healthcheck:lynis → 14B
echo "  → healthcheck:lynis → 14B"
openclaw cron edit edc0db6e-a1b3-4837-858a-68f859300614 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# notion:ideas-cleanup → 14B
echo "  → notion:ideas-cleanup → 14B"
openclaw cron edit f1e3103b-208d-4cab-9fbe-9eda0eb7acdb --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# healthcheck:security → 14B
echo "  → healthcheck:security → 14B"
openclaw cron edit fdf38b8f-6d68-4798-84ea-1e2a24c61e75 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# Seguimiento Autoresearch → 14B
echo "  → Seguimiento Autoresearch → 14B"
openclaw cron edit 4de42cb2-882b-47b5-99a0-38cb0d4dca27 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# security:rotate-gateway → 14B
echo "  → security:rotate-gateway → 14B"
openclaw cron edit 72d256fe-31f6-4821-8680-2d7c97faa52d --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# === 2. CRONS CON model=anthropic/claude-... → ollama/qwen2.5:14b ===
echo ""
echo "📋 Cambiando crons anthropic/claude → ollama/qwen2.5:14b..."

# Backup diario → 14B
echo "  → Backup diario → 14B"
openclaw cron edit ad742767-73f5-42e3-952d-4e566d17507b --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# Populate Google Sheets → 14B
echo "  → Populate Google Sheets → 14B"
openclaw cron edit 6344d609-2bfd-4295-8471-373125381779 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# Cleanup audit semanal → 14B
echo "  → Cleanup audit semanal → 14B"
openclaw cron edit 07256dbe-2161-4eb2-af22-059834407d54 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# Memory Guardian Pro → 14B
echo "  → Memory Guardian Pro → 14B"
openclaw cron edit a2cb9eec-19ab-45f8-ab18-7b1a979fec93 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# Tareas de fondo semanales → 14B
echo "  → Tareas de fondo semanales → 14B"
openclaw cron edit 496f6271-d947-4233-980b-327278a33611 --model "ollama/qwen2.5:14b" 2>&1 | tail -1

# === 3. MODELO DEFAULT ===
echo ""
echo "⚙️  Cambiando modelo default → ollama/qwen2.5:7b..."
openclaw config set agents.defaults.model.primary "ollama/qwen2.5:7b" 2>&1 | tail -1

echo ""
echo "✅ Migración completa. Resumen:"
echo "   Chat/default:  ollama/qwen2.5:7b  (local, gratis)"
echo "   Crons:         ollama/qwen2.5:14b (local, gratis)"
echo "   Reset nightly: ollama/qwen2.5:7b  (vuelve al default)"
echo "   Opus:          solo cuando Manu lo pida"
echo ""
echo "⚠️  Reinicia el gateway para aplicar el cambio de modelo default."
