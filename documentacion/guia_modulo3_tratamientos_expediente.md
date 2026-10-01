# 📋 Módulo 3: Tratamientos Clínicos, Carné Vital y Expediente Digital en PDF

> *"Ir al médico debería ser un encuentro tranquilo para cuidar de ti, no una carrera buscando papeles arrugados o tratando de recordar nombres difíciles de pastillas."*  
> Esta guía detalla cómo funciona el **Carné Vital de Salud**, la gestión de **Tratamientos Médicos** permanentes y temporales, el **Informe Médico en PDF** para citas clínicas y el algoritmo de predicción de adherencia.

---

## 💳 1. Carné Vital de Salud (`CarneVitalCard`)

Ubicado en la parte superior de la pantalla **Perfil** (👤), el **Carné Vital de Salud** es una tarjeta de identificación médica tipo pasaporte diseñada bajo el principio de **Triage Amable**:

```
+─────────────────────────────────────────────────────────────+
| 🩺 CARNÉ VITAL DE SALUD              👤 Paciente  ECB-1001  |
+─────────────────────────────────────────────────────────────+
| Santiago Casas                                              |
| CC 1.032.489.120 · 68 años · EPS Sanitas (Régimen Contributivo) |
|                                                             |
| [🩸 Tipo: O+]  [⚖️ IMC: 24.2 (Saludable)]                    |
| [⚠️ Alergia: Penicilina]  [🩺 Presión: 120/80 mmHg]         |
| [🚶 Movilidad: Marcha asistida con bastón]                  |
|                                                             |
| 🚨 CONTACTO SOS: María Casas (Hija) · 310 123 4567          |
| [ 📞 LLAMAR CONTACTO SOS DE INMEDIATO ] (Botón rojo 56dp)    |
+─────────────────────────────────────────────────────────────+
```

### Principios de Diseño y Accesibilidad:
* **Triage Amable:** Información vital categorizada visualmente sin utilizar colores alarmistas para evitar ansiedad.
* **Badges de Salud:**
  - 🩸 **Grupo Sanguíneo:** Resaltado en tono carmesí suave para rápida lectura médica.
  - ⚖️ **IMC Explicado:** Indica el valor numérico y su categoría (*"Saludable"*, *"Sobrepeso leve"*) con acceso a un diálogo educativo sobre qué significa ese número.
  - ⚠️ **Alergias Conocidas:** Banner ámbar cálido preventivo para advertir al personal sanitario antes de recetar medicamentos.
  - 🩺 **Signos y Movilidad:** Presión arterial habitual y condición de movilidad (*Independiente*, *Bastón*, *Silla de ruedas*).
* **Botón SOS Ergonómico:** Botón amplio de **56dp de altura táctil** en rojo institucional (`#E11D48`) para llamar al familiar responsable en un solo toque ante cualquier urgencia.

---

## 🩺 2. Gestión de Tratamientos Médicos (`TratamientoCard`)

Un tratamiento médico agrupa una condición clínica diagnosticada (por ejemplo: *Hipertensión arterial*, *Diabetes tipo 2*, *Artrosis*), el médico tratante, la institución de salud y los medicamentos asociados.

```
+──────────────────────────────────────────────────────────────────+
|  🩺 HIPERTENSIÓN ARTERIAL CRÓNICA          🟢 Tratamiento Activo |
|  Dr. Alejandro Morales · Fundación Cardioinfantil                |
+──────────────────────────────────────────────────────────────────+
|  💊 Medicamentos asociados:                                      |
|     • Losartán Potásico 50 mg (Cada 12 horas)                    |
|     • Hidroclorotiazida 25 mg (Cada mañana)                      |
|                                                                  |
|  📅 Tipo: Permanente (Monitoreo continuo)                        |
|  📊 Cumplimiento / Adherencia: 94%                               |
|     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸━               |
|                                                                  |
|  [ 📄 Ver Detalles Clínicos ]      [ ✏️ Modificar ]              |
+──────────────────────────────────────────────────────────────────+
```

### Clasificación de Tratamientos:
1. **Tratamientos Permanentes (Crónicos):**
   - Para condiciones que requieren acompañamiento a largo plazo (hipertensión, diabetes, tiroides).
   - No tienen fecha de fin obligatoria; muestran la barra de adherencia histórica y el tiempo transcurrido desde el diagnóstico.
2. **Tratamientos Temporales (Ciclos con Duración Fija):**
   - Para terapias antibióticas, post-operatorios o tratamientos desinflamatorios (ej. 7, 14 o 30 días).
   - Muestran una barra de progreso de días: **«Día 4 de 7 (3 días restantes)»**, permitiendo a la familia saber con certeza cuándo finaliza la prescripción.

---

## 📄 3. Expediente Digital en PDF (`PdfReportService`)

Una de las grandes ventajas de **Envejecer con Bienestar** es que elimina la necesidad de cargar carpetas físicas con papeles arrugados a las consultas médicas.

### ¿Cómo generar el Informe Médico?
1. En la pantalla de **Perfil**, pulsa el botón **"📄 Generar Informe Médico para Consulta"**.
2. **Selector de Privacidad:**
   - La aplicación pregunta: *«¿Deseas incluir tu número de documento de identidad en el informe?»*.
   - Si se genera para un médico tratante en hospital, se activa para incluir la CC completa.
   - Si se comparte con un acompañante o familiar lejano, se puede desactivar para resguardar la privacidad.
3. El servicio compila un documento PDF profesional con diseño editorial armónico en colores Teal institucionales:
   - **Encabezado Clínico:** Datos del paciente, edad, EPS, fecha y código familiar `ECB-XXXX`.
   - **Triage Vital:** Tipo de sangre, IMC, alergias y contacto de emergencia.
   - **Diagnósticos y Tratamientos Activos:** Lista detallada de tratamientos y prescripciones en curso.
   - **Esquema Farmacológico Actual:** Dosis, concentraciones y horarios de cada medicina.
   - **Firma y Fecha de Emisión:** Para constancia médica durante la consulta.

---

## 🤖 4. Predicción de Riesgo de Adherencia (`GALC-v1`)

El backend de Envejecer con Bienestar cuenta con un algoritmo de predicción de riesgo de adherencia (`/api/expediente-clinico/prediccion-adherencia-ml`):
- Evalúa factores de riesgo como:
  * Número de medicamentos prescritos simultáneamente (polifarmacia).
  * Frecuencia diaria de tomas (1 vs 4 veces al día).
  * Nivel de apoyo del círculo familiar (número de cuidadores vinculados).
  * Historial de tomas previas.
- Proporciona una clasificación preventiva (*Riesgo Bajo*, *Riesgo Moderado*, *Riesgo Alto*) acompañada de recomendaciones cálidas para optimizar la rutina y evitar olvidos involuntarios.
