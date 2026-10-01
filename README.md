# 🌿 Envejecer con Bienestar — Flutter + Flask

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-3.x-000000?style=for-the-badge&logo=flask&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-91%2F91%20Passing%20(100%25)-10B981?style=for-the-badge)
![Accessibility](https://img.shields.io/badge/Accessibility-WCAG%20AAA-0D9488?style=for-the-badge)

**Envejecer con Bienestar** es una solución integral de salud, estimulación cognitiva y acompañamiento familiar concebida para mejorar la calidad de vida de las **personas mayores** y brindar tranquilidad absoluta a sus **cuidadores y seres queridos**.

> 🔄 **Arquitectura Moderna:** Migrada con éxito desde .NET MAUI a un ecosistema escalable, fluido y reactivo compuesto por **Flutter (Clean Architecture + Riverpod)** en el frontend y **Flask REST API (SQLAlchemy + SQLite/PostgreSQL)** en el backend.

---

## 🌟 Características y Módulos Implementados

La aplicación cuenta con **5 módulos principales concluidos y certificados al 100%**:

```
+─────────────────────────────────────────────────────────────────────────────────────────────+
|                                ENVEJECER CON BIENESTAR                                      |
+─────────────────────────────────────────────────────────────────────────────────────────────+
|  👤 MÓDULO 1: GESTIÓN DE USUARIOS Y ROLES                                                  |
|     • Roles diferenciados: Adulto Mayor (Paciente) vs. Familiar / Cuidador.                 |
|     • Código de Vinculación Familiar secuencial (ECB-1001, ECB-1002...).                    |
|     • Onboarding cálido con captura de Habeas Data y sincronización automática SOS.         |
|     • Panel de Supervisión para cuidadores con métricas de salud en tiempo real.            |
+─────────────────────────────────────────────────────────────────────────────────────────────+
|  💊 MÓDULO 2: GESTIÓN DE MEDICAMENTOS                                                       |
|     • Rutina diaria cronológica ("Tomas de Hoy": Mañana, Tarde, Noche).                     |
|     • Confirmación de dosis con un solo toque y retroalimentación positiva (🎉).           |
|     • Ficha detallada interactiva del medicamento con desglose en formato de 12 horas.      |
|     • Catálogo de sugerencias rápidas con los fármacos más formulados para adultos mayores. |
+─────────────────────────────────────────────────────────────────────────────────────────────+
|  📋 MÓDULO 3: TRATAMIENTOS CLÍNICOS Y CARNÉ VITAL                                           |
|     • Carné Vital de Salud tipo pasaporte con Triage Amable (Sangre, IMC, Alergias, SOS).   |
|     • Tratamientos Permanentes (crónicos) y Temporales (con barra de días restantes).       |
|     • Generador de Informe Médico Personal en PDF para citas clínicas (con privacidad CC).   |
|     • Algoritmo de Inteligencia Artificial para predicción de riesgo de adherencia.         |
+─────────────────────────────────────────────────────────────────────────────────────────────+
|  🧠 MÓDULO 4: GIMNASIO MENTAL (ESTIMULACIÓN COGNITIVA)                                      |
|     • Catálogo de 5 minijuegos adaptados: Sudoku, Buscar Pares, Sopa de Letras (Two-Tap y   |
|       Arrastre), Trivia de Cultura General (con 5 categorías) y Secuencia de Luces.         |
|     • 3 niveles de dificultad progresiva (Fácil 🌱, Medio 🌿, Desafío 🌳).                  |
|     • Botón universal de retorno seguro ("Volver a Juegos") en todas las cabeceras.         |
|     • Salón de la Fama y Clasificación Familiar por puntos acumulados totales con filtros.  |
+─────────────────────────────────────────────────────────────────────────────────────────────+
|  ⏰ MÓDULO 5: RECORDATORIOS Y NOTIFICACIONES INTEGRADOS                                     |
|     • Alarmas programadas con timezone nativo que suenan incluso sin conexión a internet.  |
|     • Diálogo en pantalla completa con 3 botones: Tomar, Recordarme en 10 min y Omitir.     |
|     • Arquitectura limpia de 2 pestañas (Tomas de Hoy | Mi Botiquín) sin menús complejos.   |
|     • Vista previa de notificación y prueba sonora integradas en la ficha de cada medicina. |
|     • Supervisión y recordatorio afectuoso vía WhatsApp desde la app del cuidador.          |
+─────────────────────────────────────────────────────────────────────────────────────────────+
|  📦 MÓDULO 6: INVENTARIO EN BOTIQUÍN VIRTUAL                                                |
|     • Control de blísteres y conteo automático de pastillas por cada dosis tomada.          |
|     • Semáforo de stock (🟢 Óptimo, ⚠️ Por Reponer, 🔴 Agotado) y días de autonomía.        |
|     • Botones de recarga rápida (+10, +30 pastillas) y llamada directa a farmacia.          |
+─────────────────────────────────────────────────────────────────────────────────────────────+
```

---

## 📚 Guías Detalladas por Módulo

Para profundizar en el diseño, ergonomía y funcionamiento paso a paso de cada área, consulta las guías de usuario dedicadas:

| Módulo | Documento de Guía | Descripción |
| :--- | :--- | :--- |
| **Módulo 1** | [🤝 Guía de Usuarios, Roles y Vinculación](./documentacion/guia_modulo1_usuarios_roles_vinculacion.md) | Roles de usuario, código ECB-XXXX, bienvenida y dashboard del cuidador. |
| **Módulo 2** | [💊 Guía de Medicamentos y Tomas](./documentacion/guia_modulo2_medicamentos.md) | Rutina de tomas del día, confirmación en 1 toque y ficha detallada. |
| **Módulo 3** | [📋 Guía de Tratamientos y Carné Vital](./documentacion/guia_modulo3_tratamientos_expediente.md) | Carné tipo pasaporte, triage amable, informe PDF y algoritmo ML. |
| **Módulo 4** | [🎮 Guía del Gimnasio Mental y Minijuegos](./documentacion/guia_modulo4_minijuegos_estimulacion.md) | 5 minijuegos, niveles de dificultad, pistas y podio familiar. |
| **Módulo 5** | [⏰ Guía de Recordatorios y Alarmas](./documentacion/guia_modulo5_recordatorios_alarmas.md) | Alarmas horarias, función snooze 10 min y notificaciones. |
| **Módulo 6** | [📦 Guía del Botiquín e Inventario](./documentacion/guia_botiquin_medicamentos.md) | Semáforo de existencias, cálculo de autonomía y recargas de pastillas. |

---

## 🎨 Principios de Accesibilidad y Paleta Institucional

La aplicación fue diseñada siguiendo estándares internacionales de accesibilidad para personas mayores (**WCAG AAA**):
* **Tipografía Grande y Legible:** Letra Nunito con tamaños $\ge 18$sp para cuerpos de texto y $\ge 22$sp para títulos.
* **Blancos Táctiles Generosos:** Botones de acción con alturas $\ge 56$dp y separación suficiente para evitar pulsaciones erróneas.
* **Lenguaje Positivo y Sereno:** Sin términos médicos intimidantes, sin cronómetros que generen ansiedad y con mensajes comprensivos.
* **Paleta Oficial "Calma y Vitalidad":**

| Muestra | Nombre | Hex | Propósito en la Aplicación |
| :---: | :--- | :---: | :--- |
| 🟩 | **Teal Institucional** | `#0D9488` | Color principal: tranquilidad, confianza y salud. |
| 🟪 | **Índigo Sereno** | `#818CF8` | Estimulación cognitiva, gimnasio mental y tarjetas. |
| 🟢 | **Verde Salud** | `#059669` | Acciones positivas: medicina tomada, stock óptimo. |
| 🟡 | **Ámbar Cálido** | `#D97706` | Avisos preventivos: alergias, posponer alarma (snooze), stock bajo. |
| 🔘 | **Slate Neutro** | `#475569` | Tipografía de lectura descansada y bordes suaves. |
| 🔴 | **Carmesí Emergencia** | `#E11D48` | **Uso exclusivo para el Botón SOS y llamadas urgentes.** |

---

## 🚀 Guía Paso a Paso para Levantar el Proyecto Localmente

Sigue estos sencillos pasos para ejecutar tanto el backend (API Flask) como el frontend (Flutter App) en tu equipo.

### 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:
* **Git:** Para clonar el código fuente.
* **Python 3.11+:** Verifícalo con `python --version`.
* **Flutter SDK 3.19+:** Verifícalo con `flutter --version`.
* **Google Chrome** (para probar en entorno web) o **Android Studio con Emulador** (para entorno móvil).

---

### 🖥️ Paso 1: Configurar y Levantar el Backend (Flask API)

El backend maneja la lógica de usuarios, sincronización familiar, medicamentos, tratamientos, minijuegos y expediente clínico.

#### En Windows (PowerShell):

```powershell
# 1. Abre tu terminal y navega a la carpeta del backend
cd backend

# 2. Si ya tienes el entorno virtual precreado (venv_backend), actívalo:
.\venv_backend\Scripts\activate

# (Si no tienes entorno virtual, créalo e instálalo con):
# python -m venv venv_backend
# .\venv_backend\Scripts\activate
# pip install -r requirements.txt

# 3. Inicializa y pobla la base de datos con usuarios y datos de prueba:
python seed.py

# 4. Inicia el servidor Flask en el puerto 5000:
python wsgi.py
# (O alternativamente: flask run --port=5000)
```

#### En macOS / Linux (Bash):

```bash
# 1. Navega a la carpeta del backend
cd backend

# 2. Crea y activa el entorno virtual
python3 -m venv venv_backend
source venv_backend/bin/activate

# 3. Instala las dependencias
pip install -r requirements.txt

# 4. Carga los datos de demostración
python seed.py

# 5. Inicia el servidor Flask
python wsgi.py
```

> 🌐 **Confirmación:** El servidor estará activo y respondiendo en `http://localhost:5000`. Puedes verificar que funciona abriendo `http://localhost:5000/api/health` en tu navegador.

---

### 📱 Paso 2: Configurar y Levantar el Frontend (Flutter App)

En una **nueva ventana de terminal** (manteniendo el backend corriendo):

```powershell
# 1. Navega a la carpeta de la aplicación móvil
cd app

# 2. Descarga todas las dependencias y paquetes de Flutter
flutter pub get

# 3. Ejecuta la aplicación en tu navegador Google Chrome:
flutter run -d chrome --web-port=3000

# (Si prefieres ejecutar en un emulador Android o dispositivo conectado):
# flutter run
```

> 💡 **Nota sobre el puerto:** Ejecutar con `--web-port=3000` garantiza que la app web se comunique fluidamente con el backend en `http://localhost:5000` con CORS preconfigurado.

---

## 👥 Credenciales de Prueba Preconfiguradas

Para explorar todas las funcionalidades de inmediato, el script `seed.py` deja listos dos perfiles conectados entre sí:

### 👵 1. Perfil Adulto Mayor (Paciente)
* **Correo:** `santiago@envejecer.com`
* **Contraseña:** `password123`
* **Código de Enlace Familiar:** `ECB-1001`
* **Qué puedes probar:**
  - Marcar las tomas de medicina del día con confeti interactivo.
  - Abrir cualquier medicina para ver su alarma programada, escuchar el sonido y simular la pantalla de alarma activa.
  - Consultar el carné vital en Perfil y generar el informe médico en PDF.
  - Jugar al Sudoku, Sopa de Letras (Two-Tap), Buscar Pares, Trivia de Cultura General y Secuencia de Luces.

### 🧑‍💼 2. Perfil Familiar / Cuidador
* **Correo:** `prueba@envejecer.com`
* **Contraseña:** `password123`
* **Qué puedes probar:**
  - Panel de supervisión en tiempo real del paciente Santiago (`ECB-1001`).
  - Visualizar la barra de progreso de tomas de hoy en vivo.
  - Alertas preventivas del botiquín si quedan pocas pastillas.
  - Botón de recordatorio afectuoso directo por WhatsApp.
  - Vincular nuevos familiares con su código `ECB-XXXX`.

---

## 🧪 Pruebas Automatizadas y Calidad Certificada

El proyecto cuenta con una cobertura de pruebas exhaustiva para certificar estabilidad, accesibilidad y ausencia total de desbordamientos visuales:

### Ejecutar Pruebas de Frontend (Flutter):
```bash
cd app
flutter test
```
> ✅ **55 pruebas unitarias y de widgets pasando al 100%** (incluye verificación de widgets de alarmas, minijuegos, expedientes, botiquín y 0 desbordamientos RenderFlex en 360×700 dp).

### Ejecutar Pruebas de Backend (Flask):
```bash
cd backend
.\venv_backend\Scripts\python -m pytest tests/ -v
```
> ✅ **36 pruebas unitarias y de endpoints pasando al 100%** (autenticación JWT, vinculación de cuidadores, medicamentos, tratamientos y actividades cognitivas).

**Total Global:** 🟢 **91 / 91 pruebas pasando exitosamente (100%)**.

---

## 📂 Estructura del Repositorio

```
envejecer_con_bienestar_flutter/
├── app/                                 ← Frontend Flutter (Dart)
│   ├── lib/
│   │   ├── config/                      ← Rutas (GoRouter) y Tema accesible (Nunito)
│   │   ├── core/                        ← Notificaciones (timezone), PDF y red API
│   │   └── features/
│   │       ├── auth/                    ← Login, Registro, Roles y Vinculación
│   │       ├── home/                    ← Pantalla principal y Panel del Cuidador
│   │       ├── medicamentos/            ← Tomas de Hoy, Botiquín y Alarmas
│   │       ├── perfil/                  ← Carné Vital, Edición y Habeas Data
│   │       ├── juegos/                  ← Gimnasio Mental (5 minijuegos y podio)
│   │       └── contactos/               ← Agenda y llamada SOS de emergencia
│   └── test/                            ← Suite de 55 pruebas automatizadas
│
├── backend/                             ← Backend Flask REST API (Python)
│   ├── app/
│   │   ├── api/                         ← Endpoints REST (auth, cuidadores, juegos...)
│   │   ├── models/                      ← Modelos SQLAlchemy (Usuario, Medicamento...)
│   │   ├── schemas/                     ← Esquemas Marshmallow para serialización
│   │   └── services/                    ← Lógica de negocio y algoritmo de ML
│   ├── tests/                           ← Suite de 36 pruebas con Pytest
│   ├── seed.py                          ← Script de datos iniciales de prueba
│   └── wsgi.py                          ← Servidor de entrada WSGI
│
├── documentacion/                       ← Guías familiares ilustradas (Módulos 1 al 6)
│   ├── guia_modulo1_usuarios_roles_vinculacion.md
│   ├── guia_modulo2_medicamentos.md
│   ├── guia_modulo3_tratamientos_expediente.md
│   ├── guia_modulo4_minijuegos_estimulacion.md
│   ├── guia_modulo5_recordatorios_alarmas.md
│   └── guia_botiquin_medicamentos.md
│
├── .gitignore                           ← Exclusión de compilados y carpeta ia/
└── README.md                            ← Este documento
```

---

*Envejecer con Bienestar — Cuidando a quienes nos cuidaron, con amor, tecnología y serenidad.* 🌸
