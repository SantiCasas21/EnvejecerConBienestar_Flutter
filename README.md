# 🌿 Envejecer con Bienestar — Flutter + Flask

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)

**Envejecer con Bienestar** es una aplicación móvil diseñada para mejorar la calidad de vida de los adultos mayores, combinando gestión de salud, estimulación cognitiva y comunicación de emergencia.

> 🔄 Migrada desde .NET MAUI a **Flutter (Dart)** + **Flask (Python)** para mayor escalabilidad y mantenibilidad.

---

## ✨ Características

- 💊 **Gestión de Medicamentos** — Recordatorios, seguimiento de dosis, sugerencias rápidas
- 🧠 **Juegos Cognitivos** — Juego de memoria de parejas para estimulación mental
- 👥 **Agenda de Contactos** — Contactos categorizados con llamada directa y SOS
- 🌿 **Hábitos Saludables** — Seguimiento diario de agua, caminata y ejercicio
- 🚨 **Botón de Emergencia** — Acceso rápido al contacto SOS

---

## 📁 Estructura del Proyecto

```
envejecer_con_bienestar_flutter/
├── app/                    ← Flutter Frontend (Dart)
├── backend/                ← Flask REST API (Python)
├── docs/                   ← Documentación
├── CLAUDE.md               ← Contexto para asistentes de IA
└── README.md               ← Este archivo
```

---

## 🚀 Configuración Rápida

### Requisitos Previos

| Herramienta | Versión mínima |
|-------------|---------------|
| Flutter SDK | 3.19+ |
| Dart SDK | 3.3+ |
| Python | 3.11+ |
| Android SDK | API 21+ |

### Backend (Flask)

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
flask db upgrade
flask run
```

El servidor estará disponible en `http://localhost:5000`

### Frontend (Flutter)

```bash
cd app
flutter pub get
dart run build_runner build    # Generar código (freezed/json)
flutter run
```

---

## 🎨 Paleta de Colores

| Color | Hex | Uso |
|-------|-----|-----|
| Naranja cálido | `#F97316` | Primario, botones de acción |
| Crema suave | `#FFF7ED` | Fondo de pantallas |
| Verde salud | `#0D9488` | Medicamento tomado, progreso |
| Rojo emergencia | `#DC2626` | **Solo** botón SOS |
| Violeta juegos | `#7C3AED` | Sección juegos |
| Azul contactos | `#1D4ED8` | Sección contactos |

---

## 🛠️ Stack Tecnológico

- **Frontend:** Flutter 3.x + Dart 3.x
- **Backend:** Python 3.11+ + Flask 3.x
- **Base de Datos:** PostgreSQL (prod) / SQLite (dev)
- **Arquitectura:** Clean Architecture por Feature (Flutter) + Factory Pattern (Flask)
- **State Management:** Riverpod
- **Navegación:** GoRouter

---

## 📖 Documentación

- [CLAUDE.md](./CLAUDE.md) — Contexto completo para asistentes de IA
- [API Reference](./docs/api_reference.md) — Documentación de endpoints
- [Architecture](./docs/architecture.md) — Diagramas de arquitectura

---

## 📝 Licencia

Este proyecto es de uso educativo y social.
