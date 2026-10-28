# 🌿 Envejecer con Bienestar — Bitácora Oficial del Proyecto

> **Documento Oficial de Seguimiento, Arquitectura y Estado de Madurez**  
> **Última actualización:** Octubre 2026 | **Versión:** 1.7.0-dev  
> **Estado Global:** 🟢 Módulos 1 al 7 Certificados al 100% (107/107 Pruebas Pasando) | 🟡 Módulo 8 en Preparación

---

## 🌟 1. Visión y Propósito del Proyecto

**Envejecer con Bienestar** es un ecosistema digital integral de salud, estimulación cognitiva y acompañamiento afectivo diseñado específicamente para **personas mayores** y sus **círculos familiares y cuidadores**.

El proyecto nació con la premisa fundamental de devolver la tranquilidad y la autonomía en la rutina médica diaria, transformando el cuidado de la salud en un hábito amable, accesible y sereno, libre de tecnicismos intimidantes, interfaces recargadas o alertas que generen angustia.

### 🏛️ Arquitectura Tecnológica Moderna

El proyecto fue migrado y reestructurado sobre una arquitectura robusta, escalable y mantenible:

```
+─────────────────────────────────────────────────────────────────────────────+
|                          ARQUITECTURA DEL SISTEMA                           |
+─────────────────────────────────────────────────────────────────────────────+
|  📱 FRONTEND (Flutter 3.19+ / Dart 3.3+)                                    |
|     • Clean Architecture con separación estricta: Capa Core, Datos y UI.    |
|     • Gestión de Estado reactiva y desacoplada mediante Riverpod.           |
|     • Enrutamiento declarativo con GoRouter.                                |
|     • Notificaciones locales programadas en timezone nativo.                |
|     • Generación y exportación de documentos PDF vectoriales (printing).    |
+─────────────────────────────────────────────────────────────────────────────+
|  🔗 COMUNICACIÓN & SERVICIOS REST                                           |
|     • Protocolo REST / JSON con autenticación mediante JWT (Bearer).        |
|     • CORS optimizado para despliegues web locales (:3000 -> :5000) y móvil.|
+─────────────────────────────────────────────────────────────────────────────+
|  🖥️ BACKEND (Flask 3.x / Python 3.11+)                                      |
|     • API modular estructurada con Blueprints y Servicios de Negocio.       |
|     • ORM SQLAlchemy con soporte transparente para SQLite y PostgreSQL.      |
|     • Serialización y validación estricta de esquemas con Marshmallow.      |
|     • Seguridad con encriptación de contraseñas mediante bcrypt.            |
|     • Algoritmo de Inteligencia Artificial para predicción de adherencia.    |
+─────────────────────────────────────────────────────────────────────────────+
```

### 🎨 Principios de Diseño y Paleta Institucional "Calma y Vitalidad"

Siguiendo los estándares internacionales de accesibilidad **WCAG AAA** para usuarios de la tercera edad:
* **Ergonomía Táctil:** Altura de pulsación mínima de $\ge 56$dp en botones principales (botón SOS de $72$dp).
* **Tipografía Accesible:** Fuente tipográfica *Nunito* con tamaños $\ge 18$sp para cuerpos de texto y $\ge 22$sp para títulos.
* **Cero Desbordamientos:** Interfaz responsive certificada con 0 errores `RenderFlex overflowed` en dispositivos móviles desde 360×700 dp.
* **Paleta Cromática Terapéutica:**

| Muestra | Nombre | Valor Hex | Significado y Uso en la Interfaz |
| :---: | :--- | :---: | :--- |
| 🟩 | **Teal Institucional** | `#0D9488` | Identidad central del sistema: confianza, salud, serenidad y balance. |
| 🟪 | **Índigo Sereno** | `#818CF8` | Estimulación cognitiva, tarjetas del gimnasio mental y logros familiares. |
| 🟢 | **Verde Salud** | `#059669` | Acciones positivas cumplidas, confirmación de tomas e inventario óptimo. |
| 🟡 | **Ámbar Cálido** | `#D97706` | Avisos preventivos: alertas de alergias, repuesto de botiquín y posponer alarma (snooze). |
| 🔘 | **Slate Neutro** | `#475569` | Tipografía de lectura descansada sobre fondos claros contrastados. |
| 🔴 | **Carmesí Emergencia** | `#E11D48` | **Uso reservado de forma exclusiva para el Botón SOS y llamadas urgentes.** |

---

## 🗺️ 2. Matriz General de los 10 Módulos del Sistema

| # | Módulo | Estado | Componentes Principales | Cobertura de Pruebas |
| :-: | :--- | :---: | :--- | :---: |
| **1** | **Gestión de Usuarios y Roles** | 🟢 Completado | Roles diferenciados (Adulto Mayor vs. Cuidador), Código de Vinculación `ECB-XXXX`, Onboarding adaptativo y Dashboard de Cuidador. | 🟢 27/27 pruebas (100%) |
| **2** | **Medicamentos y Tomas de Hoy** | 🟢 Completado | Rutina cronológica del día, confirmación en 1 toque, ficha interactiva (`MedicamentoPopupDialog`) y sugerencias rápidas. | 🟢 36/36 pruebas (100%) |
| **3** | **Tratamientos y Carné Vital** | 🟢 Completado | Carné Vital de Salud tipo pasaporte, Triage Amable, informe médico PDF con privacidad CC y algoritmo ML de adherencia. | 🟢 54/54 pruebas (100%) |
| **4** | **Gimnasio Mental (Minijuegos)** | 🟢 Completado | 5 minijuegos cognitivos (Sudoku, Pares, Sopa, Trivia, Simón), 3 niveles, botón "Volver a Juegos" y Podio Familiar. | 🟢 76/76 pruebas (100%) |
| **5** | **Recordatorios y Alarmas** | 🟢 Completado | Motor de alarmas nativo con timezone Bogotá, snooze 10 min, diálogo accesible (`AlarmaTomaDialog`) y aviso por WhatsApp. | 🟢 91/91 pruebas (100%) |
| **6** | **Inventario (Botiquín Virtual)** | 🟢 Completado | Semáforo de stock (🟢/⚠️/🔴), cálculo de días de autonomía, descuento automático por toma y recarga rápida (+10/+30). | 🟢 Pruebas Unitarias y UI OK |
| **7** | **Historial y Hábitos de Salud** | 🟢 Completado | Entidad inmutable `HistorialToma`, carrusel de fechas táctil, gauge de adherencia positiva, tomas cronológicas y hábitos de bienestar. | 🟢 107/107 pruebas (100%: 42 Flask + 65 Flutter) |
| **8** | **Estadísticas y Reportes** | 🟡 En Preparación | Gráficas semanales/mensuales de cumplimiento y reporte exportable en texto amigable para WhatsApp. | ⏳ Parcial (vía PDF) |
| **9** | **Inteligencia Artificial y Asistente**| ⏳ Próximo Paso | Asistente conversacional empático de acompañamiento con barreras de seguridad clínica estricta. | ⏳ Contexto preparado |
| **10**| **Seguridad y Accesibilidad** | 🟢 Transversal | Modo de alto contraste, llamada SOS directa, integración de agenda y cumplimiento estricto de Habeas Data. | 🟢 Verificado en Core |

---

## 📜 3. Registro Cronológico de Versiones e Hitos

```
                                      LÍNEA DE TIEMPO DE HITOS
  
  [ Hito 1 ] ───▶ [ Hito 2 & 6 ] ───▶ [ Hito 3 ] ───▶ [ Hito 4 ] ───▶ [ Hito 5 ] ───▶ [ Hito 7 ] ───▶ [ Hito 8 ]
  Usuarios & Roles Medicamentos &     Tratamientos &  Gimnasio Mental Recordatorios &  Historial &      Estadísticas &
  Vinculación ECB  Botiquín Virtual   Carné Vital PDF Podio Familiar  Alarmas Nativas  Hábitos          Reportes
  (27/27 Tests)    (36/36 Tests)      (54/54 Tests)   (76/76 Tests)   (91/91 Tests)    (107/107 Tests)  (Próximo)
```

### 🏆 Hito 1: Gestión de Usuarios, Roles y Vinculación Familiar (Módulo 1)
* **Fecha:** Septiembre 2026 | **Estado:** 🟢 Concluido y Certificado (27/27 pruebas).
* **Entregables:**
  - Registro e inicio de sesión con tokens JWT seguros y contraseñas hasheadas (`bcrypt`).
  - Distinción funcional total de roles: `👵 Adulto Mayor (Paciente)` frente a `🧑‍💼 Familiar / Cuidador`.
  - Onboarding inicial diferenciado: captura de ficha médica y Habeas Data para el paciente (`BienvenidaDialog`); enlace guiado para el cuidador (`BienvenidaCuidadorDialog`).
  - **Código de Vinculación Secuencial Familiar:** Asignación automática de identificadores de enlace únicos (ej. `ECB-1001`), con botones directos para compartir por WhatsApp o copiar al portapapeles.
  - Sincronización automática de contacto de emergencia SOS en la agenda telefónica del paciente.
  - Dashboard de Supervisión para Cuidadores (`CuidadorDashboardScreen`) con visualización de tomas en tiempo real, alertas de inventario y acceso a ficha clínica.

### 💊 Hito 2: Central de Medicamentos y Botiquín Virtual (Módulos 2 y 6)
* **Fecha:** Septiembre 2026 | **Estado:** 🟢 Concluido y Certificado (36/36 pruebas).
* **Entregables:**
  - CRUD integral de medicamentos (`/api/medicamentos`) y cálculo automático de tomas diarias (cada 6h, 8h, 12h, 24h).
  - Pestaña **"Tomas de Hoy"**: orden cronológico de tomas del día, botón táctil ergonómico de 1 toque (`✓ Ya me la tomé`, $\ge 56$dp) y animación de confeti interactivo (`🎉`).
  - Ficha flotante interactiva (`MedicamentoPopupDialog`) con desglose de horarios en formato accesible de 12 horas.
  - Carrusel de sugerencias rápidas autocompletables con los medicamentos más formulados para adultos mayores en Latinoamérica (Losartán, Metformina, Acetaminofén, etc.).
  - Pestaña **"Mi Botiquín"** (`BotiquinInventarioTab`): control de blísteres y conteo de pastillas, cálculo automático de días de autonomía restante, semáforo preventivo de existencias y botones de recarga rápida en 1 toque (+10 y +30 pastillas / 1 caja).

### 📋 Hito 3: Tratamientos Clínicos, Carné Vital y Expediente PDF (Módulo 3)
* **Fecha:** Septiembre 2026 | **Estado:** 🟢 Concluido y Certificado (54/54 pruebas).
* **Entregables:**
  - **Carné Vital de Salud:** Tarjeta médica tipo pasaporte (`CarneVitalCard`) con principios de *Triage Amable* (sangre, IMC explicado sin términos alarmistas, alergias conocidas, presión habitual y condición de movilidad).
  - Botón SOS de contacto prioritario ergonómico ($56$dp de altura táctil) en tono carmesí institucional.
  - Gestión de Tratamientos permanentes (crónicos) y temporales (con barra de progreso de días transcurridos y restantes).
  - Generador de Informe Médico Personal en PDF (`PdfReportService`) con selector de privacidad para ocultar/mostrar el documento de identidad del paciente.
  - Algoritmo de Inteligencia Artificial (`GALC-v1`) en backend para la predicción de riesgo de adherencia terapéutica según factores de polifarmacia y red de apoyo.
  - Auditoría y resolución del 100% de advertencias de overflow (0 desbordamientos RenderFlex en 360×700 dp).

### 🎮 Hito 4: Gimnasio Mental y Estimulación Cognitiva Familiar (Módulo 4)
* **Fecha:** Septiembre 2026 | **Estado:** 🟢 Concluido y Certificado (76/76 pruebas).
* **Entregables:**
  - Catálogo de 5 minijuegos adaptados sin presión de tiempo ni cronómetros angustiantes:
    1. **Sudoku Adaptado:** Cuadrículas 4x4, 6x6 y 9x9 con teclado táctil amplio y pistas didácticas explicativas (límites de 1, 2 y 3 pistas por nivel).
    2. **Buscar Pares:** Banco extendido de más de 40 ilustraciones temáticas en 4 categorías y botón de reinicio rápido en 1 toque (`🔄 Reiniciar`).
    3. **Sopa de Letras:** Doble modalidad de selección: arrastre continuo (*Drag*) y toque ergonómico inicial y final (*Two-Tap*) para manos con temblor de pulso.
    4. **Trivia de Cultura General:** Recibidor visual de 5 temáticas (*Deportes, Arte y Cultura, Geografía e Historia, Salud, Ciencia*) y pistas contextuales históricas.
    5. **Secuencia de Luces (Simón de Memoria):** Cuadrantes luminosos rítmicos y tiempos pausados para estimulación de neuroplasticidad.
  - Botón estandarizado de retorno seguro `[ Volver a Juegos ]` presente en todas las cabeceras.
  - **Salón de la Fama y Clasificación Familiar:** Pestaña "Mis Récords" con medallas y pestaña "Círculo Familiar" con podio ordenado por **puntos acumulados totales** (`totalPuntos`) y filtros por minijuego y periodos de tiempo.

### ⏰ Hito 5: Motor de Recordatorios y Alarmas Nativas (Módulo 5)
* **Fecha:** Octubre 2026 | **Estado:** 🟢 Concluido y Certificado (91/91 pruebas).
* **Entregables:**
  - **Motor de Notificaciones Nativas:** Programación de alarmas horarias con `zonedSchedule` y paquete `timezone` (`exactAllowWhileIdle` en zona horaria local de Bogotá), garantizando timbre puntual con vibración incluso sin conexión a internet.
  - **Resiliencia ante Reinicios:** Mecanismo `reprogramarTodasLasAlarmas` para recalcular y reactivar todas las alarmas automáticamente cuando el dispositivo móvil se enciende.
  - **Ventana de Alarma en Pantalla Completa (`AlarmaTomaDialog`):** Diálogo prioritario con 3 botones táctiles ergonómicos ($\ge 56$dp):
    1. `[ ✓ Ya me la tomé ]`: Marca la dosis, anima confeti y descuenta stock del botiquín.
    2. `[ ⏰ Recordarme en 10 min ]`: Función snooze con cálculo dinámico y programación de alarma secundaria.
    3. `[ ✕ Omitir por ahora ]`: Cierra la ventana con serenidad sin alterar el plan médico.
  - **Arquitectura Limpia de 2 Pestañas:** Preservación estricta de las 2 pestañas principales (`Tomas de Hoy` y `Mi Botiquín`), concentrando la prueba sonora, la sincronización y la vista previa del mensaje telefónico dentro de la ficha de cada medicina.
  - **Supervisión Afectuosa por WhatsApp:** Botón directo en la aplicación del cuidador para redactar y enviar un mensaje amoroso de recordatorio.

### 🗓️ Hito 7: Historial de Tomas, Adherencia y Hábitos de Bienestar (Módulo 7)
* **Fecha:** Octubre 2026 | **Estado:** 🟢 Concluido y Certificado (107/107 pruebas: 42 Flask + 65 Flutter).
* **Entregables:**
  - **Entidad y Persistencia Inmutable `HistorialToma`:** Modelo SQLAlchemy y tabla en base de datos para almacenar el registro histórico inmutable de cada toma (fecha, hora programada, hora real de confirmación, estado tomada/pospuesta/omitida y notas médicas) superando el booleano simple previo (`/api/historial`).
  - **Carrusel Horizontal de Fechas Táctil:** Navegación por 28 días retrospectivos con botones de altura $\ge 70$dp, accesos directos `[ ⭐ Hoy ]` y `[ ⏪ Ayer ]`, semáforo de punto por día y selector de calendario modal en español (hasta 180 días atrás).
  - **Tarjeta de Adherencia Diaria con Psicología Positiva:** Gauge circular porcentual con mensajes constructivos sin culpa (≥80% Verde Salud *"¡Excelente constancia! 🌟"*, ≥50% Ámbar Cálido *"¡Buen avance! ☀️"*, <50% Slate/Teal *"🌱 Día en proceso"*), y badges resumen de tomas tomadas, pospuestas y omitidas.
  - **Tarjetas Cronológicas de Tomas (`TarjetaTomaHistorial`):** Comparación de hora programada vs hora real, badge de estado, dosis, presentación y notas explicativas.
  - **Metas de Hábitos Diarios (`SeccionHabitosDia`):** Barras de progreso de Hidratación / Agua 💧, Caminata y Movimiento 🚶, y Gimnasio Mental 🧠.
  - **Supervisión Familiar a Distancia:** Consulta de historial y adherencia en tiempo real para cuidadores vinculados mediante `pacienteId`.

---

## 🧪 4. Certificación de Calidad y Pruebas Automatizadas

El proyecto mantiene un estándar de pruebas automatizadas exhaustivo ejecutado periódicamente en entornos limpios:

```
+─────────────────────────────────────────────────────────────────────────────+
|                     ESTADO ACTUAL DE LA SUITE DE PRUEBAS                    |
+─────────────────────────────────────────────────────────────────────────────+
|  🐍 Backend Flask (Pytest):   42 / 42 pruebas pasando al 100%  (0 fallos)   |
|  🐦 Frontend Flutter (Test):  65 / 65 pruebas pasando al 100%  (0 fallos)   |
+─────────────────────────────────────────────────────────────────────────────+
|  🟢 TOTAL GLOBAL CERTIFICADO: 107 / 107 pruebas pasando exitosamente (100%) |
|  📐 DESBORDAMIENTOS (RenderFlex Overflow): CERO (0) en viewport 360×700 dp  |
+─────────────────────────────────────────────────────────────────────────────+
```

### Comandos de Verificación en Entorno Local:

```powershell
# 1. Pruebas de Frontend (Flutter):
cd app
flutter test

# 2. Pruebas de Backend (Flask):
cd backend
.\venv_backend\Scripts\python -m pytest tests/ -v
```

---

## 📚 5. Mapeo de Documentación Oficial de Usuario

Toda la documentación dirigida a usuarios finales, familiares y cuidadores se encuentra organizada en la carpeta `documentacion/`:

| Módulo | Guía Oficial | Aspectos Clave Explicados |
| :--- | :--- | :--- |
| **Módulo 1** | [🤝 Guía de Usuarios, Roles y Vinculación](./documentacion/guia_modulo1_usuarios_roles_vinculacion.md) | Creación de cuenta, código `ECB-XXXX`, bienvenida y supervisión del familiar. |
| **Módulo 2** | [💊 Guía de Medicamentos y Tomas](./documentacion/guia_modulo2_medicamentos.md) | Agenda diaria, confirmación con 1 toque, ficha interactiva y catálogo. |
| **Módulo 3** | [📋 Guía de Tratamientos y Carné Vital](./documentacion/guia_modulo3_tratamientos_expediente.md) | Pasaporte Carné Vital, Triage Amable, reporte en PDF y privacidad. |
| **Módulo 4** | [🎮 Guía del Gimnasio Mental](./documentacion/guia_modulo4_minijuegos_estimulacion.md) | 5 minijuegos cognitivos, niveles de reto, ayudas y podio familiar. |
| **Módulo 5** | [⏰ Guía de Recordatorios y Alarmas](./documentacion/guia_modulo5_recordatorios_alarmas.md) | Alarmas horarias en el móvil, snooze de 10 min y previsualización. |
| **Módulo 6** | [📦 Guía del Botiquín e Inventario](./documentacion/guia_botiquin_medicamentos.md) | Semáforo de pastillas, conteo automático, recargas y llamada a farmacia. |
| **Módulo 7** | [🗓️ Guía de Historial y Hábitos](./documentacion/guia_modulo7_historial_habitos.md) | Carrusel táctil de fechas, adherencia positiva, tomas cronológicas y hábitos de vida. |

*Guías de apoyo y consulta complementaria:*
- [🤝 Guía Familiar de Vinculación de Cuidadores](./documentacion/guia_vinculacion_cuidadores.md)
- [🩺 Guía del Expediente Clínico y Carné](./documentacion/guia_expediente_clinico.md)
- [🧠 Guía de Minijuegos de Estimulación](./documentacion/guia_minijuegos_estimulacion.md)
- [🔔 Guía de Recordatorios y Alarmas Diarias](./documentacion/guia_recordatorios_alarmas.md)

---

## 🚀 6. Estado Actual y Hoja de Ruta (Roadmap)

### 📍 Estado Actual Inmediato
- Conclusión satisfactoria y certificación de calidad de los **Módulos 1, 2, 3, 4, 5, 6 y 7** (107/107 pruebas pasando al 100%).
- **Apertura Oficial del Módulo 8: Estadísticas y Reportes**.

### 🛠️ Objetivos del Módulo 8 (En Preparación):
1. **Gráficas Visuales Simplificadas:** Visualización de tendencias de adherencia semanal y mensual con alto contraste y sin gráficos recargados que confundan al adulto mayor.
2. **Reporte Formateado para WhatsApp:** Generación de resúmenes ejecutivos en texto plano estructurado con emojis para compartir por chat sin requerir abrir PDFs.
3. **Métricas de Impacto Familiar:** Resumen de apoyo del círculo de cuidadores y evolución de hábitos de bienestar.

### 🔮 Hitos Subsiguientes:
* **Módulo 9 (Asistente Virtual con IA):** Chat accesible de acompañamiento y educación en salud con directrices estrictas de seguridad médica.
* **Módulo 10 (Seguridad y Accesibilidad Avanzada):** Selector de contactos nativo de libreta telefónica y perfeccionamiento biométrico opcional.

---

*Envejecer con Bienestar — Cuidando a quienes nos cuidaron, con amor, tecnología y serenidad.* 🌸
