# 💊 Módulo 2: Gestión de Medicamentos, Tomas de Hoy y Adherencia

> *"Tomar los medicamentos a la hora exacta no tiene por qué ser complicado ni abrumador. Con una rutina visual ordenada y confirmaciones amorosas, cuidar de la salud se vuelve un hábito natural y sereno."*  
> Esta guía detalla cómo funciona la pantalla de Medicamentos de Envejecer con Bienestar, cómo se organizan las tomas del día, el registro de nuevos fármacos, la dosificación y la interacción con la ficha interactiva.

---

## 🌟 1. Filosofía de Navegación: Simplicidad con 2 Pestañas

Para evitar confusiones en personas mayores, la pantalla de **Medicamentos** (`MedicamentosScreen`) mantiene una interfaz minimalista y libre de desbordamientos con **exactamente dos pestañas**:

```
+──────────────────────────────────────────────────────────────────+
|           [ 📋 Tomas de Hoy ]        [ 📦 Mi Botiquín ]          |
+──────────────────────────────────────────────────────────────────+
```

1. **[ 📋 Tomas de Hoy ]:** Tu agenda cronológica del día.
2. **[ 📦 Mi Botiquín ]:** El control de cajas, pastillas restantes y semáforo de existencias.

---

## ☀️ 2. Pestaña "Tomas de Hoy": Tu Rutina Médica Diaria

En esta pestaña verás todos los medicamentos programados para el día actual, clasificados cronológicamente:

```
+──────────────────────────────────────────────────────────────────+
|  💊 TUS MEDICAMENTOS DE HOY (3)               Progreso: 66%      |
|  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸━━━━━━━━━          |
+──────────────────────────────────────────────────────────────────+
|                                                                  |
|  🟢 [08:00 AM] · Losartán Potásico (50 mg)                       |
|     1 comprimido con agua después de desayunar                   |
|     Estado: ✓ Tomada con éxito a las 08:05 AM                    |
|                                                                  |
|  🟡 [02:00 PM] · Calcio + Vitamina D (600 mg)                    |
|     1 cápsula con el almuerzo                                    |
|     Estado: ⏳ Próxima toma                                      |
|     [  ✓ Ya me la tomé  ]   (Botón táctil verde grande ≥ 56dp)   |
|                                                                  |
|  🔵 [08:00 PM] · Atorvastatina (20 mg)                           |
|     1 comprimido antes de dormir                                 |
|     Estado: ⏰ Programada para la noche                          |
|                                                                  |
+──────────────────────────────────────────────────────────────────+
```

### Elementos de cada Tarjeta (`MedicamentoCard`):
* **Tipografía Accesible:** Nombre del medicamento en 20sp, con dosis en miligramos resaltada.
* **Indicación Médica Amable:** Consejos de ingesta (*"Tomar con medio vaso de agua"*, *"Después de las comidas"*).
* **Confirmación con 1 Toque (`✓ Ya me la tomé`):**
  - Al presionar el botón verde de confirmación, la dosis pasa a estado tomada (`tomado = true`).
  - Se activa una agradable retroalimentación visual (`🎉`).
  - Se descuenta automáticamente 1 unidad del inventario en el botiquín.
  - El familiar o cuidador ve de inmediato el avance actualizado en su panel.

---

## 🔍 3. Ficha Interactiva del Medicamento (`MedicamentoPopupDialog`)

Al pulsar sobre cualquier medicamento de la lista, se abre su ventana detallada con 3 secciones especializadas:

```
+──────────────────────────────────────────────────────────────────+
|                   LOSARTÁN POTÁSICO (50 mg)                      |
|                     1 comprimido cada 12 horas                   |
+──────────────────────────────────────────────────────────────────+
|  ⏰ ALARMAS Y HORARIO DEL DÍA                 [ 2 tomas/día ]    |
+──────────────────────────────────────────────────────────────────+
|  🔔 Horarios programados:                                        |
|     • 08:00 AM  (Mañana)                                         |
|     • 08:00 PM  (Noche)                                          |
|                                                                  |
|  📱 Vista previa de notificación en tu teléfono:                 |
|     "🔔 Hora de tu medicina: Losartán (50 mg).                   |
|      Tomar con agua después de desayunar."                       |
|                                                                  |
|  [ 🔔 Ver Pantalla de Alarma Activa ]   (Prueba la ventana real) |
|  [ 🔊 Probar Sonido ]                   [ 🔄 Sincronizar ]       |
+──────────────────────────────────────────────────────────────────+
|  📦 INVENTARIO EN BOTIQUÍN                    🟢 28 pastillas    |
|     Autonomía estimada: 14 días restantes                        |
+──────────────────────────────────────────────────────────────────+
|  [ ✏️ Editar ]           [ 🗑️ Eliminar ]         [ Cerrar ]      |
+──────────────────────────────────────────────────────────────────+
```

### Funciones destacadas en la ficha:
1. **Resumen de Horarios (12 horas):** Indica exactamente cuántas tomas corresponden al día (`${horas.length} tomas/día`) y en qué momentos (`08:00 AM`, `08:00 PM`).
2. **Previsualización de Notificación Móvil:** Muestra el texto exacto con el que el teléfono alertará al adulto mayor.
3. **Botón "Ver Pantalla de Alarma Activa":** Permite desplegar y familiarizarse con la ventana de alarma en pantalla completa (`AlarmaTomaDialog`) en cualquier momento.
4. **Prueba Sonora y Sincronización:** Botones para verificar el volumen del timbre y sincronizar con el reloj del teléfono.

---

## ➕ 4. Registro y Edición de Nuevos Medicamentos (`AddMedicamentoDialog`)

Para registrar una nueva medicina o ajustar una prescripción médica:

1. Presiona el botón flotante grande **"➕ Agregar Medicamento"**.
2. **Campos del Formulario Ergonómico:**
   - **Nombre comercial o genérico:** (ej. *Losartán*, *Metformina*, *Acetaminofén*).
   - **Concentración:** En miligramos o gramos (ej. *50 mg*, *500 mg*).
   - **Forma farmacéutica:** Comprimido, cápsula, gotas, jarabe o ampolla.
   - **Frecuencia y Horario:** Selección de tomas por día (1, 2, 3 o 4 veces) y horas exactas mediante selectores amigables.
   - **Instrucciones médicas:** Notas breves para evitar olvidos (ej. *"Con el estómago lleno"*).
   - **Cantidad inicial en Botiquín:** Número de pastillas con las que inicia la caja (ej. *30 pastillas*).
3. Pulsa **"Guardar Medicamento"**: El backend almacena la medicina, recalcula el botiquín y programa automáticamente las alarmas en el reloj del dispositivo.

---

## 💡 5. Sugerencias Rápidas y Catálogo Frecuente

Para que los adultos mayores no tengan que escribir nombres largos y complejos en teclados pequeños:
* La pantalla incluye un carrusel de **Sugerencias Frecuentes** con los medicamentos más prescritos para personas mayores en Colombia y Latinoamérica (ej. *Losartán*, *Enalapril*, *Metformina*, *Atorvastatina*, *Levotiroxina*, *Omeprazol*).
* Al tocar una sugerencia, los campos de nombre, concentración y forma se autocompletan en un instante.

---

## 🛡️ 6. Acompañamiento Familiar ante Tomas Pendientes

Si una dosis de la mañana o de la tarde no se ha marcado después de su horario habitual:
- La tarjeta del medicamento resalta su estado pendiente con un color distintivo.
- En la aplicación del familiar o cuidador aparece el botón directo de **WhatsApp**, el cual permite enviar un saludo respetuoso y amoroso para recordar la toma con serenidad y sin angustias.
