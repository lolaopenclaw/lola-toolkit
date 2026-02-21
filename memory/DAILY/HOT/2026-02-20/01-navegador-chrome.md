# Sesión 1: Configuración Navegador y Rollback OpenClaw

## Problema: Extensión Chrome Browser Relay
- Intentamos configurar la extensión Chrome para tener navegador "attach" permanente
- Error persistente: "invalid handshake" / "invalid request frame"
- Problema: extensión envía eventos CDP antes de completar handshake WebSocket
- **Issue reportado:** GitHub #21758 con logs completos
- **Workaround:** Usar navegador headless (openclaw profile) como default

## Problema crítico: OpenClaw 2026.2.19-2 breaking changes
- Versión 2026.2.19-2 introdujo cambios de seguridad que rompieron:
  - ❌ Subagentes (error "pairing required")
  - ❌ CLI commands (scope-upgrade restrictions)
  - ❌ Posiblemente extensión Chrome
- **Decisión:** Rollback a 2026.2.17
- **Resultado:** ✅ CLI y subagentes funcionando, extensión sigue igual (problema independiente)

## Comandos ejecutados
```bash
npm install -g openclaw@2026.2.17
systemctl --user restart openclaw-gateway
openclaw config set meta.lastTouchedVersion 2026.2.17
```

## Decisión técnica
- **Navegador:** Priorizar headless, Chrome como fallback manual cuando sea necesario
- **Versión OpenClaw:** Mantener 2026.2.17 hasta que 2026.2.20+ solucione breaking changes
