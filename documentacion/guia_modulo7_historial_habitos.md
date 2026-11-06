# 🗓️ Módulo 7: Historial de Tomas, Adherencia y Hábitos de Bienestar

> *"El camino del bienestar se construye día a día, paso a paso y con amor. Mirar hacia atrás en nuestras rutinas no es para juzgarnos ni exigirnos perfección, sino para celebrar cada esfuerzo y darnos tranquilidad a nosotros y a quienes nos cuidan."*  
> Esta guía detalla cómo opera el **Historial de Tomas**, la **Racha de Bienestar ("El Fueguito")**, el **Centro de Hábitos Interactivos de los 8 Pilares de la Geriatría**, el **Cronómetro de Estiramientos con Guía Articular**, y las herramientas de personalización, edición y eliminación de metas.

---

## 🌟 1. Filosofía: Recordar con Serenidad y Psicología Positiva

En **Envejecer con Bienestar**, el historial y el seguimiento diario no son un examen ni una lista de reproches. Están diseñados bajo los principios de la **psicología positiva, la geriatría humanista y la serenidad**:

```
+─────────────────────────────────────────────────────────────────────────────+
|                     FILOSOFÍA DEL HISTORIAL DE BIENESTAR                    |
+─────────────────────────────────────────────────────────────────────────────+
|   🌱 Sin Culpa ni Ansiedad              |   🤝 Transparencia Familiar       |
|   • Si olvidaste una pastilla o no      |   • Tus hijos y cuidadores pueden |
|     pudiste caminar hoy, la app jamás   |     revisar con amor cómo fue tu  |
|     te regaña ni te castiga.            |     semana sin necesidad de hacer |
|   • Mensajes siempre constructivos      |     interrogatorios incómodos.    |
|     y alentadores que valoran tu salud. |                                   |
|                                         |                                   |
|   🕒 Registro Fiel en el Tiempo         |   💧 8 Pilares de Vida Plena      |
|   • Guarda la hora exacta de cada toma. |   • El bienestar va más allá de   |
|   • Permite contrastar la hora recetada |     las pastillas: agua, sol,     |
|     con la hora real en que la tomaste. |     movimiento, mente y afecto.   |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## 🔥 2. La Racha de Bienestar ("El Fueguito"): Constancia que Motiva

Ubicada en la esquina superior derecha del inicio (`HomeScreen`), la **Racha de Bienestar** (inspirada en la gamificación positiva estilo Duolingo/TikTok) premia la constancia diaria del adulto mayor de una forma alegre, visual y reconfortante:

```
+─────────────────────────────────────────────────────────────+
|  👵 ¡Buenos días, Santiago!             [ 🔥 5 Días ]       |
|  Miércoles, 28 de octubre             (Insignia Destacada)  |
+─────────────────────────────────────────────────────────────+
```

### ¿Cómo funciona la Llama de la Salud?
1. **Animación Suave y Reconfortante:** El icono del fueguito palpita delicadamente en la pantalla con un gradiente anaranjado y dorado cuando tienes una racha activa.
2. **Psicología Positiva sin Castigo:** 
   - Si por alguna razón un día no pudiste registrar tus tomas o hábitos, la aplicación **no muestra cruces rojas ni mensajes de fracaso**.
   - Al tocar el fueguito inactivo, te recibe con una invitación amorosa: *«¡Enciende tu llama de bienestar hoy! 🔥 Cada nuevo día es una hermosa oportunidad para cuidarte.»*
3. **Diálogo Motivacional Semanal (`_RachaInfoDialog`):**
   - Al pulsar sobre el fueguito se abre una ventana modal accesible con un fueguito central dorado y el contador de días continuos.
   - **Semana de Constancia:** Muestra los 7 días de la semana (`L M M J V S D`) con círculos luminosos en los días cumplidos y un resalte especial en el día de **Hoy**.
   - Incluye el récord histórico: *«Tu mejor racha: 12 días seguidos. ¡Eres un ejemplo de dedicación!»*.

---

## 🌿 3. Los 8 Pilares de la Salud Geriátrica

Para evitar saturar la pantalla principal, el inicio cuenta con dos pestañas ordenadas: **[ ☀️ Mi Día y Salud ]** y **[ 🌿 Hábitos Vitales ]**. En esta última encontrarás tarjetas interactivas adaptadas para los 8 grandes pilares de la longevidad saludable:

```
+─────────────────────────────────────────────────────────────────────────────+
|                         LOS 8 PILARES DEL BIENESTAR                         |
+─────────────────────────────────────────────────────────────────────────────+
|  1. 💧 Hidratación Vital           |  5. 😴 Sueño y Descanso Reparador      |
|  2. 🚶 Caminata y Movimiento       |  6. 🥗 Nutrición y Fruta Fresca        |
|  3. ☀️ Baño de Sol y Vitamina D    |  7. 📞 Afecto y Conexión Familiar      |
|  4. 🧘 Pausas y Estiramientos      |  8. 🧠 Gimnasio Mental y Memoria       |
+─────────────────────────────────────────────────────────────────────────────+
```

### Detalle de cada Tarjeta Interactiva (`HabitoInteractivoCard`):

1. **💧 Hidratación Vital:**
   - **Dinámica:** Presenta 8 vasitos interactivos táctiles que se llenan de color azul cielo al tocarlos uno a uno, acompañados de un botón táctil amplio `[ Tomar 1 Vaso ]`.
   - **Elogio Médico al Completar:** *«¡Excelente hidratación! Tus riñones, tu piel y tu energía te lo agradecen profundamente hoy. 💧»*

2. **🚶 Caminata y Movimiento Diario:**
   - **Dinámica:** Fomenta paseos suaves y seguros en el hogar o al aire libre. Dispone de botones de incremento rápido de un toque: `[ +10 min ]`, `[ +15 min ]` y `[ +30 min ]`.
   - **Elogio Médico al Completar:** *«¡Meta de movimiento alcanzada! Caminar mantiene tu corazón joven y tus articulaciones bien lubricadas. 🚶»*

3. **☀️ Baño de Sol y Vitamina D:**
   - **Dinámica:** Recordatorio para tomar entre 10 y 15 minutos de luz solar suave en la mañana (antes de las 10 AM) para activar la síntesis natural de vitamina D y sincronizar el reloj biológico.
   - **Elogio Médico al Completar:** *«¡Sol radiante recibido! La vitamina D fortalece tus huesos y llena de vitalidad tu estado de ánimo. ☀️»*

4. **🧘 Pausas Activas y Estiramientos Suaves:**
   - **Dinámica:** Integra un cronómetro interactivo y una guía visual de ejercicios articulares para evitar la rigidez corporal (ver Sección 4).
   - **Elogio Médico al Completar:** *«¡Maravilloso estiramiento! Tus músculos y articulaciones están flexibles, previniendo tropiezos y rigidez. 🧘»*

5. **😴 Sueño y Descanso Reparador:**
   - **Dinámica:** Selector de 3 caritas sonrientes para calificar la calidad del descanso matutino (*Tranquilo*, *Interrumpido*, *Pesado*) y registro de horas dormidas.
   - **Elogio Médico al Completar:** *«¡Descanso reparador! Un sueño de calidad regenera tus neuronas y fortalece tu sistema inmune. 😴»*

6. **🥗 Nutrición Sana y Fruta Fresca:**
   - **Dinámica:** Contador de 3 a 5 porciones de frutas o verduras con chips visuales interactivos (*Manzana*, *Papaya*, *Ensalada*).
   - **Elogio Médico al Completar:** *«¡Nutrición ejemplar! Vitaminas, antioxidantes y fibra natural para cuidar tu digestión. 🥗»*

7. **📞 Afecto y Conexión Familiar:**
   - **Dinámica:** Fomenta la llamada o el saludo a un familiar o amigo para combatir la soledad no deseada. Incluye un botón para abrir WhatsApp o llamar directamente.
   - **Elogio Médico al Completar:** *«¡Hermosa conexión! El cariño de tus seres queridos y una buena charla son la mejor medicina para el corazón. 📞»*

8. **🧠 Gimnasio Mental y Memoria:**
   - **Dinámica:** Enlace directo para sumar minutos de lectura o partidas completadas en Sudoku, Sopa de Letras, Trivia o Simón de Memoria.
   - **Elogio Médico al Completar:** *«¡Mente brillante y activa! Ejercitar tu cerebro crea nuevas conexiones neuronales cada día. 🧠»*

---

## ⏱️ 4. Cronómetro Interactivo de Estiramientos y Guía Articular

Para facilitar las pausas activas sin tener que mirar un reloj de pared ni forzar la vista, la tarjeta de **Pausas Activas y Estiramientos** incorpora un cronómetro especialmente diseñado para adultos mayores:

```
+──────────────────────────────────────────────────────────────────────────+
|  🧘 Pausas Activas y Estiramientos                      [ 10 min meta ]  |
+──────────────────────────────────────────────────────────────────────────+
|  ⏱️ Cronómetro de Estiramiento                              [ EN CURSO ] |
|                                                                          |
|                            04:35                                         |
|                 (Pantalla con números de 34sp)                           |
|                                                                          |
|   [ ⏸️ Pausar ]    [ ✓ Sumar +5 min a mi meta ]    [ 🔄 Reiniciar ]      |
+──────────────────────────────────────────────────────────────────────────+
|  💡 Ver 4 Ejercicios Suaves Sugeridos                                [▼] |
+──────────────────────────────────────────────────────────────────────────+
```

### ¿Cómo utilizar el Cronómetro?
1. **Iniciar:** Pulsa el botón verde `[ Iniciar Estiramiento ]`. El reloj comenzará a contar segundo a segundo con dígitos extra grandes ($34$sp) de alto contraste.
2. **Pausar o Continuar:** Si necesitas tomar agua o descansar, pulsa `[ Pausar ]` en cualquier momento.
3. **Guardar el Progreso:** Al finalizar tu sesión, pulsa `[ Sumar +X min ]`. La aplicación sumará automáticamente los minutos completados a tu meta diaria y desplegará un mensaje de felicitación.

### 🧘 Los 4 Ejercicios Articulares Suaves Sugeridos:
Al pulsar el botón desplegable `💡 Ver 4 Ejercicios Suaves Sugeridos`, la tarjeta enseña paso a paso 4 movimientos seguros y avalados por geriatras:

```
+──────────────────────────────────────────────────────────────────────────+
|  🧘 1. Cuello y Nuca Relajados                                           |
|     Sentado derecho, inclina suavemente la cabeza hacia un hombro por    |
|     15 segundos. Respira hondo y cambia al otro lado.                    |
+──────────────────────────────────────────────────────────────────────────+
|  🔄 2. Círculos con Hombros                                              |
|     Mueve tus hombros en círculos lentos hacia atrás 5 veces y luego      |
|     hacia adelante para soltar la espalda alta y el pecho.               |
+──────────────────────────────────────────────────────────────────────────+
|  🦶 3. Movilidad de Tobillos                                             |
|     Sentado, eleva ligeramente un pie y gira el tobillo en círculos       |
|     despacio. Favorece la circulación sanguínea y previene caídas.       |
+──────────────────────────────────────────────────────────────────────────+
|  ✨ 4. Estrellas con las Manos                                           |
|     Abre bien los dedos de tus manos como una estrella brillante y       |
|     ciérralos en un puño suave 10 veces seguidas. Alivia la artrosis.    |
+──────────────────────────────────────────────────────────────────────────+
```

---

## ✏️ 5. Personalización, Modificación y Eliminación de Hábitos

Cada persona mayor tiene necesidades y gustos diferentes. Por eso, el sistema permite adaptar completamente la rutina diaria:

### A. Modificar una Meta Existente (`AddMetaDialog`):
1. En cualquier tarjeta de hábito, toca el botón de tres puntos o el icono de **Editar** `[ ✏️ ]`.
2. Se abrirá la ventana con los datos actuales:
   - **Botones Numéricos Ergonómicos:** Puedes subir o bajar tu objetivo diario con botones anchos `[-]` y `[+]` de $48$dp, sin lidiar con teclados virtuales difíciles.
   - **Cambio de Unidad:** Puedes elegir entre *minutos*, *vasos*, *horas*, *veces* o *porciones*.
   - **Personalización de Emoji:** Puedes seleccionar entre 16 emojis expresivos (`💧`, `🚶`, `☀️`, `🧘`, `🍎`, `🎨`, `🎵`, `❤️`, etc.).
3. Pulsa **"Guardar Cambios"** y tu meta se actualizará de inmediato.

### B. Deselección Limpia al Crear Nuevos Hábitos:
- Al presionar el botón `[ ➕ Agregar Hábito ]`, puedes pulsar una sugerencia del catálogo (ej. *Tomar agua* o *Paseo*).
- **Deselección Táctil:** Si pulsas una recomendación y luego cambias de opinión, al volver a tocarla se deselecciona limpiamente, permitiéndote escribir un nombre 100% propio (ej. *"Regar mis plantitas"*, *"Escuchar música clásica"*, *"Pasear a Toby"*).

### C. Eliminar un Hábito con Confirmación Segura:
- Si ya no deseas seguir un hábito en tu día a día, pulsa el botón **Eliminar** `[ 🗑️ ]` en la tarjeta.
- **Diálogo de Seguridad:** La aplicación te consultará: *«¿Deseas eliminar el hábito "X" de tu rutina diaria? Podrás volver a agregarlo en cualquier momento.»*
- Para evitar eliminaciones accidentales por temblor de pulso, se requiere confirmar en el botón rojo `[ Sí, Eliminar ]`.

---

## 📅 6. Consulta del Historial Cronológico y Fechas Pasadas

Desde la pantalla de **Historial** (`HistorialScreen`), el usuario o su familia pueden viajar en el tiempo para revisar el cumplimiento de días anteriores:

```
+─────────────────────────────────────────────────────────────────────────────+
| [ ⭐ Hoy ]     [ ⏪ Ayer ]     [  MAR  ]     [  LUN  ]     [ 📅 Calendario ]|
|    28             27             26            25                           |
|     🟢             🟢             🟡            ⚪        (Hasta 180 días)  |
+─────────────────────────────────────────────────────────────────────────────+
```

### Elementos del Historial:
1. **Carrusel Táctil de 28 Días:** Botones amplios ($\ge 70$dp) con accesos rápidos a `[ ⭐ Hoy ]` y `[ ⏪ Ayer ]`, más semáforo de punto por día.
2. **Selector de Calendario Modal:** Permite saltar a cualquier fecha de los últimos 6 meses (180 días) con un calendario completo en español.
3. **Tarjeta de Adherencia con Psicología Positiva:**
   - **$\ge 80\%$ (Verde Salud):** *«¡Excelente constancia! 🌟 Has cumplido tus tomas de este día.»*
   - **$50\% - 79\%$ (Ámbar Cálido):** *«¡Buen avance! ☀️ Sigues cuidando tu salud con dedicación.»*
   - **$< 50\%$ (Teal / Slate Amable):** *«🌱 Día en proceso. ¡Cada toma cuenta para tu bienestar!»*
4. **Tarjetas de Medicamentos con Hora Real:** Muestra la hora programada por el doctor frente a la hora real en que se tomó (`Prog: 08:00 AM • Real: 08:05 AM`), estados (*Tomada*, *Pospuesta +10 min*, *Omitida*) y notas médicas.
5. **Resumen de Hábitos del Día:** Gráficas de hidratación, caminata y gimnasio mental correspondientes a esa fecha.

---

## 🛡️ 7. Supervisión para Cuidadores y Familiares

El familiar o cuidador vinculado mediante el código secuencial `ECB-XXXX`:
1. Puede ingresar a la ficha de su ser querido desde su **Panel de Supervisión**.
2. Al tocar **"🗓️ Ver Historial y Hábitos"**, visualiza el mismo historial con los 8 pilares, la racha activa y las tomas de medicamentos en tiempo real.
3. Esto le permite felicitar a su familiar por sus rachas de bienestar y llevar datos concretos y ordenados a las consultas médicas geriátricas.

---

*Envejecer con Bienestar — Cuidando a quienes nos cuidaron, con amor, tecnología y serenidad.* 🌸
