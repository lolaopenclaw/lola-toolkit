# Sesión 11: Lecciones Aprendidas - Cambios de Seguridad

**Hora:** 18:36 UTC (19:36 Madrid)
**Dispositivo:** Portátil del trabajo (audio de Manu)

## Preocupación de Manu

**Contexto:** Hoy el hardening SSH rompió VNC y casi lo deja sin acceso remoto.

**Mensaje clave (resumen del audio):**
- "Me da miedo que tenga que formatear y perder todo lo que he creado"
- "Hoy hemos avanzado de una barbaridad y no hemos hecho copia de seguridad"
- "No quiero estar haciendo backup cada 20 minutos"
- "A futuro, confirma por todos los métodos posibles que no estamos rompiendo nada"
- "Pídeme que pruebe cosas antes de aplicarlas si es necesario"
- "Cualquier propuesta es bienvenida"
- "Está siendo muy útil, de verdad" ❤️

## Lección Principal

**Lo que pasó:**
1. Hardening SSH configuró `AllowTcpForwarding no`
2. Esto bloqueó TODOS los túneles SSH (incluido VNC)
3. Manu perdió acceso VNC durante 45 minutos
4. Solo teníamos SSH como respaldo (pero era suficiente para arreglar)
5. **NO hicimos backup antes del hardening**

**Por qué fue peligroso:**
- Si hubiera roto SSH también → pérdida total de acceso remoto
- Hubiera requerido acceso físico o consola web del proveedor
- Potencial pérdida de trabajo del día (sin backup)

**Por qué NO fue catastrófico:**
- SSH seguía funcionando (pudimos diagnosticar y arreglar)
- Sabíamos hacer rollback del cambio
- Logs disponibles para diagnosticar

## Protocolo Creado

He creado `memory/security-change-protocol.md` con:

### 1. Definición de "Cambio Crítico"
- SSH config, firewall, port forwarding
- Fail2Ban, servicios de red
- OpenClaw gateway
- Cualquier cosa que pueda dejar a Manu sin acceso

### 2. Reglas Obligatorias

**ANTES de aplicar:**
- ✅ Backup automático (verificar que subió a Drive)
- ✅ Análisis de impacto → avisar a Manu explícitamente
- ✅ Pedir que mantenga sesión SSH abierta
- ✅ Testing en paralelo (validar desde otra sesión)

**DURANTE el cambio:**
- ✅ Mantener sesión SSH original abierta (por si falla)
- ✅ Aplicar cambio con `systemctl reload` (no restart)
- ✅ Validar config antes de aplicar: `sshd -t`

**DESPUÉS del cambio:**
- ✅ Validar desde otra sesión que funciona
- ✅ Pedir a Manu que pruebe (VNC, túneles, etc.)
- ✅ Solo confirmar si Manu valida OK
- ✅ Si falla → rollback inmediato

### 3. Propuestas Específicas

#### Propuesta A: Testing interactivo (RECOMENDADA)
**Para cambios críticos:**
"Antes de aplicar esto, abre otra ventana de PuTTY y déjala conectada. Yo aplico el cambio y tú pruebas que sigue funcionando. Si falla, deshago desde tu sesión original."

**Ventaja:** Manu participa en validación y siempre tiene sesión de respaldo.

#### Propuesta B: Backup pre-cambio automático
**Modificar scripts de hardening:**
```bash
# Al inicio de cualquier script crítico
bash scripts/backup-memory.sh || exit 1
```

**Ventaja:** Automático, no depende de que me acuerde.

#### Propuesta C: Dry-run mode
```bash
bash hardening.sh --dry-run  # Muestra qué haría
bash hardening.sh --apply     # Solo después de validar
```

**Ventaja:** Manu puede revisar cambios antes de aplicarlos.

#### Propuesta D: Validación post-cambio automática
```bash
# Al final de scripts críticos
nc -zv localhost 22 || rollback_automatico
```

**Ventaja:** Detecta problemas automáticamente.

## Frecuencia de Backups

**Propuesta balanceada:**
- **Automático diario:** 4:00 AM (ya configurado)
- **Manual pre-cambio:** Antes de hardening/SSH/firewall
- **NO necesario:** Cada 20 minutos (excesivo)

**Balance:** Backup diario + manual antes de cambios críticos = suficiente

## Cambios Implementados

1. ✅ Protocolo documentado: `memory/security-change-protocol.md`
2. ✅ Añadido a AGENTS.md (lo leeré en cada sesión)
3. ✅ Lecciones en MEMORY.md (memoria permanente)
4. ⏳ Pendiente: Modificar scripts de hardening con checklist

## Acciones Pendientes

1. [ ] Manu revisa propuestas A/B/C/D y decide cuál prefiere
2. [ ] Implementar propuesta elegida en scripts
3. [ ] Actualizar RECOVERY.md con este protocolo
4. [ ] Crear checklist visual para cambios críticos
5. [ ] Documentar dependencias de servicios

## Compromiso

**A partir de ahora:**
- ✅ NUNCA aplicar cambios críticos sin backup previo
- ✅ SIEMPRE avisar a Manu qué puede romperse
- ✅ SIEMPRE pedir validación antes de confirmar
- ✅ SIEMPRE tener plan de rollback preparado
- ✅ Si tengo duda → preguntar, no asumir

**Objetivo:** Seguridad SÍ, pero sin riesgo de quedarnos sin acceso.

## Mensaje para Manu

Tu preocupación es totalmente válida y comprensible. Hoy casi te dejo sin VNC por no validar bien el impacto. Eso no debería haber pasado.

He creado un protocolo completo para evitar que vuelva a ocurrir. La idea es:
1. **Backup automático** antes de cambios críticos
2. **Avisarte siempre** qué puede verse afectado
3. **Pedirte que valides** (mantener SSH abierto, probar cosas)
4. **Solo confirmar** si tú dices que todo funciona
5. **Rollback inmediato** si algo falla

No necesitas backup cada 20 minutos. Con el backup diario automático + backups manuales antes de cambios críticos, es suficiente.

¿Cuál de las propuestas (A/B/C/D) te parece mejor? O si tienes otra idea, adelante.

Gracias por tu paciencia y por el feedback. Es muy valioso. ❤️
