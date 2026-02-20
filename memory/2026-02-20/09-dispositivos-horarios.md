# Sesión 9: Dispositivos y Horarios de Disponibilidad

## Contexto recuperado
**Hora:** 13:09 UTC (post-overflow)

Audio de Manu que se perdió durante el overflow de contexto fue reenviado.

## Información documentada

### Horarios de trabajo (portátil del trabajo)
**Lunes a viernes, hora Madrid:**
- **Martes, miércoles, jueves:** 8:30-15:30 (7 horas)
- **Lunes, viernes:** 8:30-13:30 (5 horas)
- **Fuera de esos horarios:** Puede estar o no estar

### SSH keys en móvil
- **Estado:** No instaladas todavía
- **Preparación:** Clave privada lista, solo falta copiar y meter contraseña
- **Viabilidad:** Totalmente posible, pero de momento no prioritario

## Uso de esta información

### Para inferir dispositivo:
1. **Dentro de horario laboral** → Probablemente portátil trabajo
2. **Fuera de horario + audios** → Probablemente móvil
3. **Tareas SSH requeridas fuera de horario** → Avisar que necesita portátil o preguntar si puede esperar

### Para tareas automatizadas (crons):
- **Informes matutinos:** Enviar entre 7:00-8:30 (antes de entrar a trabajar)
- **Tareas que requieran confirmación SSH:** Mejor entre 8:30-15:30 martes-jueves
- **Notificaciones nocturnas:** Respetar horario silencioso 00:00-07:00

## Actualizado en USER.md
Sección "Dispositivos" ampliada con:
- Horarios típicos de cada dispositivo
- Lógica de inferencia mejorada
- Recomendaciones para tareas que requieren SSH
