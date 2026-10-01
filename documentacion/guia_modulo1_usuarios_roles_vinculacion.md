# 🤝 Módulo 1: Gestión de Usuarios, Roles y Vinculación Familiar

> *"El cuidado familiar es el mayor acto de amor y tranquilidad. Conectar a quienes cuidamos con quienes los aman crea un círculo de protección y paz mental."*  
> Esta guía detalla paso a paso el funcionamiento del sistema de cuentas, los roles diferenciados (Adulto Mayor vs. Cuidador), el código único de vinculación secuencial (`ECB-XXXX`), el proceso de bienvenida y la supervisión familiar en tiempo real.

---

## 🌟 1. Filosofía de Roles: Adulto Mayor vs. Cuidador

En **Envejecer con Bienestar**, la aplicación se adapta automáticamente según el rol de la persona que inicia sesión:

```
+─────────────────────────────────────────────────────────────────────────────+
|                             SELECCIÓN DE ROL                                |
+─────────────────────────────────────────────────────────────────────────────+
|   👵 Adulto Mayor (Paciente)            |   🧑‍💼 Cuidador / Familiar           |
|   • Interfaz simplificada con letras    |   • Panel de supervisión en tiempo |
|     grandes y botones amplios.          |     real de sus seres queridos.     |
|   • Gestión de sus medicamentos,        |   • Monitoreo de tomas de hoy y     |
|     alarmas, carné vital y juegos.      |     alertas de botiquín bajo.       |
|   • Posee un Código Familiar único      |   • Acceso rápido a fichas médicas  |
|     (ej. ECB-1001) para ser enlazado.   |     y contacto SOS / WhatsApp.      |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## 🔑 2. Registro e Inicio de Sesión Seguro

1. **Pantalla de Registro (`RegisterScreen`):**
   - El usuario ingresa su nombre, correo electrónico y contraseña segura.
   - Selecciona claramente su rol mediante dos opciones visuales con íconos grandes:
     - `👵 Soy Adulto Mayor (Quiero gestionar mi salud)`
     - `🧑‍💼 Soy Familiar o Cuidador (Quiero acompañar a mi familiar)`
   - La aplicación almacena de forma segura las credenciales con hash en el backend (`bcrypt`) y autentica mediante tokens JWT.

2. **Cuentas de Demostración Preconfiguradas:**
   - **Adulto Mayor:** `santiago@envejecer.com` / `password123` (Código: `ECB-1001`).
   - **Cuidador / Familiar:** `prueba@envejecer.com` / `password123`.

---

## 💌 3. Onboarding y Bienvenida Diferenciada

Al iniciar sesión por primera vez, el sistema detecta el rol para brindar una bienvenida personalizada:

* **Para el Adulto Mayor (`BienvenidaDialog`):**
  - Presenta un diálogo cálido explicando los beneficios de la aplicación.
  - Solicita sus datos basales de salud (EPS, tipo de sangre, alergias conocidas y contacto de emergencia).
  - Incluye la autorización de Habeas Data y protección de datos sensibles de salud.
  - **Sincronización Automática SOS:** Al registrar el contacto de emergencia en la bienvenida, la aplicación lo añade automáticamente a su agenda de contactos con la etiqueta `🚨 Emergencia SOS`.

* **Para el Cuidador (`BienvenidaCuidadorDialog`):**
  - Explica en 3 pasos cómo funciona el acompañamiento a distancia.
  - Ofrece un campo inmediato para ingresar el parentesco (*Hijo/a, Nieto/a, Cónyuge, Cuidador Principal*) y el código `ECB-XXXX` de su ser querido.
  - Persiste el estado de bienvenida mediante almacenamiento local (`SharedPreferences`) para no interrumpir inicios de sesión futuros.

---

## 🔗 4. Código Único de Vinculación Familiar (`ECB-XXXX`)

Para garantizar la privacidad sin depender de números de identificación sensibles, cada adulto mayor recibe un **Código de Enlace Secuencial Único**:

```
      Paso 1                            Paso 2                           Paso 3
 👵 Adulto Mayor                  🧑‍💼 Familiar / Cuidador           ❤️ Ambos Unidos
[Consulta su código en Perfil] ──▶ [Ingresa el código ECB-XXXX] ──▶ [¡Supervisión en Tiempo Real!]
```

### ¿Cómo lo consulta el Adulto Mayor?
1. Abre la pestaña **"Perfil"** (👤) en la barra de navegación inferior.
2. En la sección **"🤝 Tu Código de Vinculación Familiar"**, encontrará su código destacado en tipografía de 24sp (por ejemplo, `ECB-1001`).
3. Opciones de 1 toque:
   - **Boton WhatsApp (`Compartir por WhatsApp`):** Abre un mensaje prediseñado:  
     *«¡Hola! 🌸 Este es mi código en Envejecer con Bienestar: ECB-1001. Úsalo para acompañarme en mi rutina de salud.»*
   - **Botón Copiar (`Copiar Código`):** Copia el código al portapapeles del teléfono para dictarlo o enviarlo por SMS.

### ¿Cómo lo enlaza el Cuidador?
1. Desde el **Panel de Supervisión** del cuidador, presiona el botón **"➕ Vincular Nuevo Adulto Mayor"**.
2. Escribe el código (por ejemplo, `ECB-1001`).
3. Selecciona el parentesco y pulsa **"Vincular"**.
4. El backend valida la existencia del paciente, previene duplicados y establece el enlace de supervisión en menos de 1 segundo.

---

## 🛡️ 5. Panel de Supervisión del Cuidador (`CuidadorDashboardScreen`)

Cuando un familiar inicia sesión, es recibido por su panel de control en tiempo real:

```
+──────────────────────────────────────────────────────────────────+
|                 PANEL DE SUPERVISIÓN FAMILIAR                    |
+──────────────────────────────────────────────────────────────────+
|  👤 Santiago Casas (ECB-1001)                     Parentesco: Hijo |
|                                                                  |
|  💊 Tomas de Hoy: 2 de 3 cumplidas (66%)                         |
|     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸━━━━━━━━━━                     |
|                                                                  |
|  ⚠️ Alertas de Botiquín:                                         |
|     • Losartán 50 mg: 🟢 Quedan 28 pastillas (14 días)           |
|     • Atorvastatina: ⚠️ Quedan 4 pastillas (¡Reponer pronto!)    |
|                                                                  |
|  [ 💬 Recordar por WhatsApp ]   [ 📞 Llamada Directa ]           |
|  [ 📋 Ver Ficha Médica ]        [ 📦 Ver Botiquín Completo ]     |
+──────────────────────────────────────────────────────────────────+
```

### Herramientas del Cuidador:
1. **Métricas en Vivo:** Barra porcentual de adherencia del día que refleja instantáneamente cada vez que el adulto mayor pulsa *"✓ Ya me la tomé"*.
2. **Semáforo del Botiquín:** Detección automática de medicinas con stock crítico ($\le 5$ pastillas).
3. **Recordatorio Cariñoso por WhatsApp:** Redacta y abre en WhatsApp un recordatorio empático con un solo toque, evitando que la persona mayor se sienta juzgada o presionada.
4. **Consulta de Expediente Clínico:** Visualización de tipo de sangre, diagnósticos, EPS y tratamientos sin necesidad de pedir papeles físicos.
