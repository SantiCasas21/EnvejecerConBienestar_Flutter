# CLAUDE.md — Contexto del Proyecto para Asistentes de IA

> **Este archivo es la fuente de verdad para cualquier IA** (Claude, Copilot, Gemini, ChatGPT)
> que trabaje en este proyecto. Léelo completo antes de hacer cambios.

---

## 📋 Descripción del Proyecto

**Envejecer con Bienestar** es una aplicación móvil diseñada para mejorar la calidad de vida
de los **adultos mayores** en Colombia. Combina gestión de salud, estimulación cognitiva y
comunicación de emergencia en una interfaz accesible y cálida.

### Propósito Social
- Facilitar el seguimiento de medicamentos y hábitos de salud
- Estimular la actividad cognitiva mediante juegos de memoria
- Proveer un sistema de contactos de emergencia (SOS) de fácil acceso
- Empoderar al adulto mayor con tecnología simple y amigable

### Público Objetivo
- Adultos mayores (60+ años) en Colombia
- Cuidadores y familiares como usuarios secundarios

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología | Versión |
|------|-----------|---------|
| **Frontend Móvil** | Flutter + Dart | Flutter 3.x, Dart 3.x |
| **Backend API** | Python + Flask | Python 3.11+, Flask 3.x |
| **Base de Datos** | PostgreSQL (prod) / SQLite (dev) | — |
| **ORM** | SQLAlchemy + Flask-Migrate | — |
| **Autenticación** | Flask-JWT-Extended (JWT) | — |
| **State Management** | Riverpod (flutter_riverpod) | — |
| **Navegación** | GoRouter (go_router) | — |
| **HTTP Client** | Dio | — |
| **Serialización** | freezed + json_serializable (Dart) / Marshmallow (Python) | — |

---

## 🏗️ Arquitectura

### Flutter (Frontend)
Usamos **Clean Architecture por Feature** con 3 capas:

```
features/<nombre>/
├── data/           ← Modelos JSON, repositorios (API calls)
│   ├── models/     ← Clases con fromJson/toJson (freezed)
│   └── repositories/
├── domain/         ← Entidades puras del negocio
│   └── entities/
└── presentation/   ← UI (screens, widgets, providers)
    ├── screens/
    ├── widgets/
    └── providers/  ← Riverpod StateNotifiers
```

### Flask (Backend)
Usamos **Application Factory Pattern** con capas separadas:

```
backend/app/
├── models/      ← SQLAlchemy models
├── schemas/     ← Marshmallow serialization/validation
├── api/         ← Flask Blueprints (routes)
├── services/    ← Lógica de negocio
└── utils/       ← Error handlers, decorators
```

---

## 🎨 Design System

### Paleta de Colores
| Nombre | Hex | Uso | ⚠️ Regla |
|--------|-----|-----|----------|
| `primaryOrange` | `#F97316` | Color primario, botones de acción, FABs | — |
| `primaryLight` | `#FDBA74` | Hover, estados activos | — |
| `primaryDark` | `#EA580C` | Pressed states | — |
| `background` | `#FFF7ED` | Fondo de TODAS las pantallas | — |
| `cardBackground` | `#FFFFFF` | Fondo de tarjetas | — |
| `healthGreen` | `#0D9488` | Medicamento tomado, progreso salud | — |
| `emergencyRed` | `#DC2626` | Botón SOS, badges emergencia | **⛔ SOLO para emergencia** |
| `gamesViolet` | `#7C3AED` | Sección de juegos | — |
| `contactsBlue` | `#1D4ED8` | Sección de contactos | — |
| `textPrimary` | `#1C1917` | Texto principal | — |
| `textSecondary` | `#78716C` | Texto secundario, descripciones | — |
| `completed` | `#16A34A` | Estados completados | — |
| `border` | `#E7E5E4` | Bordes de tarjetas | — |

### Tipografía
- **Fuente**: Nunito (Google Fonts)
- **Variantes**: Regular (400), SemiBold (600), Bold (700)
- **⚠️ Tamaño mínimo de fuente: 18sp** (accesibilidad para adultos mayores)

### Accesibilidad (OBLIGATORIO)
- Tamaño mínimo de fuente: **18sp**
- Área táctil mínima: **56dp × 56dp**
- Alto contraste en todos los textos
- Botón de emergencia siempre visible y grande (mínimo 70dp de alto)
- Emojis como indicadores visuales complementarios

### Componentes Reutilizables
- `EcbCard` — Tarjeta base con sombra y bordes redondeados (20dp)
- `EcbButton` — Botón con variantes: primario, secundario, emergencia, tomado
- `EcbEmptyState` — Estado vacío con emoji + mensaje
- `EcbLoading` — Indicador de carga con skeleton/shimmer

---

## 📊 Modelos de Datos

### Usuario
```
id: int (PK, autoincrement)
nombre: string (required)
email: string (unique, required)
password_hash: string
created_at: datetime
```

### Medicamento
```
id: int (PK, autoincrement)
usuario_id: int (FK → Usuario)
nombre: string (required)
miligramos: string
notas: string
frecuencia: int (horas entre dosis)
hora_alarma: time
esta_tomado: bool (default: false)
icono: string (emoji, default: "💊")
fecha_inicio: date
created_at: datetime
```

### Contacto
```
id: int (PK, autoincrement)
usuario_id: int (FK → Usuario)
nombre: string (required)
telefono: string
ubicacion: string
categoria: string (default: "Familia/Amigos")
icono: string (emoji, default: "👤")
es_favorito: bool (default: false)
es_emergencia: bool (default: false)
created_at: datetime
```

### Habito
```
id: int (PK, autoincrement)
usuario_id: int (FK → Usuario)
tipo: string ("Agua", "Caminata", "Ejercicio")
meta: int
progreso_actual: int (default: 0)
fecha: date
created_at: datetime
— Propiedad calculada: porcentaje = progreso_actual / meta
```

### ActividadCognitiva
```
id: int (PK, autoincrement)
usuario_id: int (FK → Usuario)
tipo_juego: string
puntaje: int
fecha_realizacion: datetime
created_at: datetime
```

---

## 🌐 API REST — Endpoints

Base URL: `http://localhost:5000/api`

### Autenticación
| Método | Endpoint | Body | Respuesta |
|--------|----------|------|-----------|
| POST | `/auth/register` | `{nombre, email, password}` | `{user, access_token}` |
| POST | `/auth/login` | `{email, password}` | `{access_token, refresh_token}` |
| POST | `/auth/refresh` | Header: `Authorization: Bearer <refresh>` | `{access_token}` |

### Medicamentos (requiere JWT)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/medicamentos` | Lista todos los medicamentos del usuario |
| POST | `/medicamentos` | Crear medicamento |
| GET | `/medicamentos/<id>` | Obtener medicamento por ID |
| PUT | `/medicamentos/<id>` | Actualizar medicamento |
| DELETE | `/medicamentos/<id>` | Eliminar medicamento |
| PATCH | `/medicamentos/<id>/toggle` | Toggle esta_tomado |

### Contactos (requiere JWT)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/contactos` | Lista todos los contactos del usuario |
| POST | `/contactos` | Crear contacto |
| GET | `/contactos/<id>` | Obtener contacto por ID |
| PUT | `/contactos/<id>` | Actualizar contacto |
| DELETE | `/contactos/<id>` | Eliminar contacto |
| GET | `/contactos/emergencia` | Obtener contacto SOS |

### Hábitos (requiere JWT)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/habitos?fecha=YYYY-MM-DD` | Hábitos del día |
| POST | `/habitos` | Crear hábito |
| PATCH | `/habitos/<id>/progreso` | Actualizar progreso `{valor: int}` |

### Juegos Cognitivos (requiere JWT)
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/juegos/puntaje` | Guardar puntaje `{tipo_juego, puntaje}` |
| GET | `/juegos/historial` | Historial de puntajes |

---

## 🗂️ Estructura de Archivos

### Flutter (`app/`)
```
lib/
├── main.dart                     ← Entry point + ProviderScope
├── app.dart                      ← MaterialApp.router + ThemeData
├── config/
│   ├── app_config.dart           ← URLs, constantes
│   ├── theme/
│   │   ├── app_colors.dart       ← Paleta de colores
│   │   ├── app_typography.dart   ← Estilos de texto Nunito
│   │   └── app_theme.dart        ← ThemeData completo
│   └── routes/
│       └── app_router.dart       ← GoRouter + tabs
├── core/
│   ├── network/
│   │   ├── api_client.dart       ← Dio singleton
│   │   ├── api_endpoints.dart    ← Constantes de URL
│   │   └── api_interceptors.dart ← JWT interceptor
│   ├── storage/
│   │   └── local_storage.dart    ← SharedPreferences wrapper
│   ├── utils/                    ← Helpers comunes
│   └── widgets/                  ← EcbCard, EcbButton, etc.
└── features/
    ├── home/                     ← Saludo, hábitos, SOS
    ├── medicamentos/             ← CRUD medicinas
    ├── juegos/                   ← Juego de memoria
    └── contactos/                ← CRUD contactos
```

### Flask (`backend/`)
```
backend/
├── run.py                        ← Entry point
├── config.py                     ← Config por entorno
├── requirements.txt
├── app/
│   ├── __init__.py               ← create_app factory
│   ├── extensions.py             ← db, jwt, migrate, cors, ma
│   ├── models/                   ← SQLAlchemy models
│   ├── schemas/                  ← Marshmallow schemas
│   ├── api/                      ← Blueprints (routes)
│   ├── services/                 ← Lógica de negocio
│   └── utils/                    ← Error handlers
├── migrations/                   ← Alembic
└── tests/                        ← pytest
```

---

## ✅ Convenciones de Código

### Dart/Flutter
- **Naming**: `snake_case` para archivos, `camelCase` para variables/funciones, `PascalCase` para clases
- **Widgets**: Siempre `const` cuando sea posible
- **State**: Usar `StateNotifier<AsyncValue<T>>` para estados async
- **Imports**: Orden → dart:, package:, relative
- **Modelos**: Usar `@freezed` para inmutabilidad
- **Archivos**: Un widget/clase principal por archivo
- **Null safety**: Nunca usar `!` sin validar primero

### Python/Flask
- **Naming**: `snake_case` para todo excepto clases (`PascalCase`)
- **Type hints**: En TODOS los parámetros y retornos
- **Docstrings**: En español, formato Google style
- **Imports**: Orden → stdlib, third-party, local
- **Models**: Siempre definir `__repr__` y `to_dict`
- **Routes**: Blueprint por recurso, prefijo `/api/`

### Commits (Conventional Commits en español)
```
feat(medicamentos): agregar endpoint de toggle tomado
fix(contactos): corregir validación de teléfono
style(theme): ajustar paleta de colores para accesibilidad
docs(claude): actualizar endpoints del API
refactor(home): extraer widget de saludo dinámico
test(backend): agregar tests de hábitos
```

---

## 🚀 Comandos Útiles

### Flutter
```bash
cd app
flutter pub get                    # Instalar dependencias
flutter run                        # Correr en dispositivo/emulador
flutter test                       # Correr tests
flutter analyze                    # Análisis estático
dart run build_runner build        # Generar código (freezed, json)
dart run build_runner watch        # Generar código en modo watch
```

### Flask
```bash
cd backend
python -m venv venv                # Crear virtual environment
venv\Scripts\activate              # Activar (Windows)
pip install -r requirements.txt    # Instalar dependencias
flask run                          # Correr servidor (dev)
flask db init                      # Inicializar migraciones
flask db migrate -m "mensaje"      # Crear migración
flask db upgrade                   # Aplicar migraciones
python -m pytest tests/ -v         # Correr tests
```

---

## ⚠️ Reglas Importantes para IAs

1. **NUNCA** cambiar los colores sin autorización del diseñador
2. **SIEMPRE** respetar el tamaño mínimo de fuente (18sp) y área táctil (56dp)
3. **NUNCA** usar el rojo (#DC2626) para algo que no sea emergencia/SOS
4. **SIEMPRE** escribir comentarios y documentación en **español**
5. **NUNCA** hacer imports absolutos en Flutter; usar imports relativos dentro de features
6. **SIEMPRE** usar `const` en widgets cuando sea posible
7. **NUNCA** almacenar contraseñas en texto plano; usar `werkzeug.security`
8. **SIEMPRE** validar datos de entrada tanto en frontend como en backend
9. **NUNCA** exponer endpoints sin autenticación JWT (excepto `/auth/register` y `/auth/login`)
10. **SIEMPRE** manejar estados de error y loading en la UI
11. **SIEMPRE** seguir el patrón de Clean Architecture por feature
12. **NUNCA** mezclar lógica de negocio en la capa de presentación
