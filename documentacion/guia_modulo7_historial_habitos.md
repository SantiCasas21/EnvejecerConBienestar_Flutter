# 🗓️ Módulo 7: Historial de Tomas, Adherencia y Hábitos de Bienestar

> *"El camino del bienestar se construye día a día, paso a paso y con amor. Mirar hacia atrás en nuestras rutinas no es para juzgarnos ni exigirnos perfección, sino para celebrar cada esfuerzo y darnos tranquilidad a nosotros y a quienes nos cuidan."*  
> Esta guía detalla cómo opera el **Historial de Tomas y Hábitos**, el carrusel táctil de fechas pasadas, el indicador de adherencia con psicología positiva, el desglose de medicamentos tomados, pospuestos u omitidos, el seguimiento de hábitos saludables y la supervisión familiar a distancia.

---

## 🌟 1. Filosofía: Recordar con Serenidad y Psicología Positiva

En **Envejecer con Bienestar**, el historial médico no es un examen ni una lista de reproches. Está diseñado bajo los principios de la **psicología positiva y la serenidad**:

```
+─────────────────────────────────────────────────────────────────────────────+
|                     FILOSOFÍA DEL HISTORIAL DE BIENESTAR                    |
+─────────────────────────────────────────────────────────────────────────────+
|   🌱 Sin Culpa ni Ansiedad              |   🤝 Transparencia Familiar       |
|   • Si olvidaste una pastilla o la      |   • Tus hijos y cuidadores pueden |
|     pospusiste, la app no te regaña.    |     revisar con amor cómo fue tu  |
|   • Mensajes siempre constructivos      |     semana sin necesidad de hacer |
|     y alentadores que valoran tu salud. |     interrogatorios incómodos.    |
|                                         |                                   |
|   🕒 Registro Fiel en el Tiempo         |   💧 Salud Integral de Vida       |
|   • Guarda la hora exacta de cada toma. |   • Acompaña tus medicinas con tu |
|   • Permite contrastar la hora recetada |     consumo de agua, tus pasos y  |
|     con la hora real en que la tomaste. |     tus ejercicios de memoria.    |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## 📅 2. Carrusel de Fechas Táctil y Selector de Calendario

Al ingresar a la pantalla de **Historial** (`HistorialScreen`), encontrarás en la parte superior un selector horizontal diseñado especialmente para manos de personas mayores:

```
+─────────────────────────────────────────────────────────────────────────────+
| [ ⭐ Hoy ]     [ ⏪ Ayer ]     [  MAR  ]     [  LUN  ]     [ 📅 Calendario ]|
|    28             27             26            25                           |
|     🟢             🟢             🟡            ⚪        (Selector Modal)  |
+─────────────────────────────────────────────────────────────────────────────+
```

### Características Ergonómicas:
1. **Botones Amplios y Cómodos ($\ge 70$dp de altura):**
   - No necesitas atinarle a números diminutos. Cada día es una tarjeta táctil ancha y acolchada.
2. **Acceso Inmediato a "Hoy" y "Ayer":**
   - Las dos primeras tarjetas están marcadas claramente como `[ ⭐ Hoy ]` y `[ ⏪ Ayer ]` para consultar lo más reciente con un solo toque.
3. **Semáforo Discreto de Cumplimiento:**
   - Un pequeño punto de color debajo del número del día indica visualmente el ritmo del día:
     * 🟢 **Verde:** Cumplimiento excelente ($\ge 80\%$).
     * 🟡 **Ámbar:** Buen avance ($\ge 50\%$).
     * ⚪ **Gris suave:** Día en proceso o sin tomas pendientes.
4. **Selector de Calendario Modal:**
   - El botón flotante con ícono de calendario permite abrir una ventana mensual completa en español para consultar días de hace semanas o meses (hasta 180 días atrás).

---

## 📊 3. Tarjeta de Adherencia Diaria con Psicología Positiva

Justo debajo de la fecha elegida, se despliega la **Tarjeta de Adherencia Diaria** (`TarjetaAdherenciaDiaria`). Su diseño evita los números fríos y utiliza palabras cálidas y alentadoras:

```
+──────────────────────────────────────────────────────────────────────────+
|  📅 Hoy (28/10/2026)                                               🌟     |
+──────────────────────────────────────────────────────────────────────────+
|      ╭───────╮                                                           |
|     │  100%  │   ¡Excelente constancia! 🌟                                |
|      ╰───────╯   Has cumplido tus tomas de este día con gran dedicación. |
|                  3 de 3 dosis registradas                                |
+──────────────────────────────────────────────────────────────────────────+
|   [ ✓ 3 Tomadas ]       [ ⏰ 0 Pospuestas ]       [ ✕ 0 Omitidas ]       |
+──────────────────────────────────────────────────────────────────────────+
```

### Escala de Mensajes Amables:
* **$\ge 80\%$ (Verde Salud):**  
  *«¡Excelente constancia! 🌟 Has cumplido tus tomas de este día.»* — Reconoce el compromiso con el autocuidado.
* **$50\% - 79\%$ (Ámbar Cálido):**  
  *«¡Buen avance! ☀️ Sigues cuidando tu salud con dedicación.»* — Motiva a seguir adelante sin reproches.
* **$< 50\%$ (Teal / Slate Amable):**  
  *«🌱 Día en proceso. ¡Cada toma cuenta para tu bienestar!»* — Enfatiza que cada esfuerzo suma y que siempre es un buen momento para cuidarse.

---

## 💊 4. Tarjetas Cronológicas de Tomas (`TarjetaTomaHistorial`)

A continuación, la aplicación desglosa cada medicamento programado para esa fecha, ordenado cronológicamente desde la mañana hasta la noche:

```
+──────────────────────────────────────────────────────────────────────────+
|  💊  Losartán Potásico                                  [ ✓ Tomada ]     |
|      50 mg · 1 comprimido                                                |
|                                                                          |
|  ⏰ Horario: Prog: 08:00 AM  •  Real: 08:05 AM                           |
|                                                                          |
|  📝 Nota médica: "Tomada con medio vaso de agua tras el desayuno"        |
+──────────────────────────────────────────────────────────────────────────+
|  🟡  Calcio + Vitamina D                     [ ⏰ Pospuesta (+10 min) ]  |
|      600 mg · 1 cápsula                                                  |
|                                                                          |
|  ⏰ Horario: Prog: 02:00 PM  •  Real: 02:10 PM                           |
+──────────────────────────────────────────────────────────────────────────+
```

### Elementos Destacados en Cada Registro:
1. **Ícono y Color de la Medicina:** Facilita identificar el remedio de un vistazo según la caja o color que la persona reconoce.
2. **Comparativa de Horas:** Muestra tanto la hora programada originalmente por el médico (`Prog: 08:00 AM`) como la hora exacta en que la persona confirmó la toma en el móvil (`Real: 08:05 AM`).
3. **Estados Amigables de la Toma:**
   - **`[ ✓ Tomada ]` (Verde):** Dosis ingerida y descontada del botiquín.
   - **`[ ⏰ Pospuesta (+10 min) ]` (Ámbar):** El usuario activó el recordatorio cariñoso de descanso temporal.
   - **`[ ✕ Omitida ]` (Gris Neutro):** La dosis se suspendió (por ejemplo, por indicación médica para un examen de laboratorio o ayuno).
4. **Notas del Paciente o Cuidador:** Si se agregó una aclaración (*"Tomada con jugo de naranja"*, *"Indicación del doctor de pausar hoy"*), se muestra en un recuadro destacado con borde Teal.

---

## 💧 5. Sección de Metas y Hábitos Saludables (`SeccionHabitosDia`)

La salud de una persona mayor no depende únicamente de las pastillas; el agua, el movimiento y la actividad cerebral son igualmente vitales. Al final del historial de cada día, se presenta la sección de **Hábitos de Bienestar**:

```
+──────────────────────────────────────────────────────────────────────────+
|  🌿 Metas y Hábitos de este Día                                          |
+──────────────────────────────────────────────────────────────────────────+
|  💧 Hidratación               5 / 6 vasos (83%)                          |
|     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸━━━━                     |
|                                                                          |
|  🚶 Caminata y Movimiento     25 / 30 minutos (83%)                      |
|     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸━━━━                     |
|                                                                          |
|  🧠 Gimnasio Mental           2 / 2 ejercicios (100%)                    |
|     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                     |
+──────────────────────────────────────────────────────────────────────────+
```

* **💧 Hidratación (Vasos de Agua):** Barra azul que registra el consumo de líquido a lo largo del día para prevenir deshidrataciones en personas mayores.
* **🚶 Caminata y Movimiento (Minutos Activos):** Barra verde que fomenta paseos suaves y seguros en el hogar o parque.
* **🧠 Gimnasio Mental (Ejercicios Cognitivos):** Barra índigo que premia las partidas completadas en Sudoku, Sopa de Letras o Trivia.

---

## 🛡️ 6. Supervisión para Familiares y Cuidadores

Los familiares o cuidadores vinculados mediante el código `ECB-XXXX` pueden consultar este mismo historial directamente desde su **Panel de Supervisión**:

1. Ingresan al perfil del paciente desde su aplicación.
2. Tocan la opción **"🗓️ Ver Historial y Adherencia"**.
3. Pueden consultar cualquier día de la semana para verificar si su ser querido tomó sus medicamentos a tiempo.
4. Si detectan tomas pospuestas u omitidas frecuentes, pueden conversar amorosamente con el médico tratante en la siguiente cita médica llevando datos reales y precisos.

---

*Envejecer con Bienestar — Cuidando a quienes nos cuidaron, con amor, tecnología y serenidad.* 🌸
