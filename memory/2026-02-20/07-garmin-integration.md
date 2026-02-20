# Sesión 7: Garmin Integration

## Inicio del proyecto
**Hora:** 12:35 UTC

**Modelo confirmado:** Garmin Instinct 2S Solar Surf
- Solar (batería larga)
- Health tracking completo
- Surf edition con métricas deportivas

### Datos disponibles
- Heart rate 24/7
- Stress score
- Sleep tracking + score
- Steps, calories
- Pulse Ox
- Activities
- Body Battery
- Respiration rate

## Preocupación de seguridad
**Hora:** 12:37 UTC

Manu no quiere compartir password de Garmin Connect (correcto).

### Solución OAuth implementada
**Decisión:** Opción A (OAuth tokens)

Script `scripts/garmin-setup.sh` creado:
1. Manu lo ejecuta desde VPS vía SSH móvil
2. Pide email + password (solo él lo ve localmente)
3. Obtiene OAuth1 + OAuth2 tokens
4. Guarda tokens en ~/.openclaw/.env
5. Borra password (no se guarda nunca)

### Ventajas
- No necesita instalar Python en móvil
- Password nunca llega a mí
- Tokens renovables y revocables
- Proceso simple (1 comando)

**Estado:** Esperando ejecución del script por Manu
```bash
bash ~/.openclaw/workspace/scripts/garmin-setup.sh
```
