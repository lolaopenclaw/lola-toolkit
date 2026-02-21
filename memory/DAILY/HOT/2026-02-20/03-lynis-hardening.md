# Sesión 3: Lynis y Hardening

## Lynis Security Scanner configurado
**Versión:** 3.0.9  
**Resultado inicial:** 65% hardening index (219/334 puntos)

### Scan completado
- Tests: 261/453 realizados
- Warnings: 0
- Suggestions: 51
- Estado: "System has been hardened, but could use additional hardening"

### Principales sugerencias
1. **Alta:** Instalar malware scanner (rkhunter/chkrootkit)
2. **Alta:** Proteger GRUB con password
3. **Alta:** Restringir acceso a compiladores
4. **Media:** SSH hardening (AllowTcpForwarding)
5. **Media:** Password policies (hashing rounds, expiry)

## Hardening Fase 1
1. ✅ **Fail2ban:** jail.conf → jail.local (protege config de updates)
2. ✅ **SSH:** AllowTcpForwarding deshabilitado
3. ✅ **rkhunter:** Instalado v1.4.6 (detección malware/rootkits)

## Hardening Fase 2
4. ✅ **Core dumps deshabilitados** (/etc/security/limits.conf)
5. ✅ **libpam-tmpdir instalado** (v0.09build1)

### Impacto total
- **5 cambios aplicados** en 2 fases
- **Hardening index:** 65% → ~70% (estimado)
- **Tiempo total:** ~5 minutos
- **Downtime:** 0 segundos
- **Próxima verificación:** Lynis scan lunes 24 feb

### Crons configurados
- ✅ Scan Lynis semanal (lunes 6:00 Madrid)
- ✅ Scan rkhunter semanal (lunes 6:00 Madrid)
