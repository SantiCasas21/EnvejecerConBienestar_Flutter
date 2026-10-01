# ⏰ Módulo 5: Recordatorios, Alarmas y Notificaciones Integradas

> *"La puntualidad en los medicamentos no tiene por qué ser motivo de angustia ni olvidos. Con una alarma cariñosa a tiempo y el acompañamiento de quienes te aman, cuidar de tu salud se convierte en un hábito de serenidad y vida plena."*  
> Esta guía detalla cómo opera el motor de alarmas sonoras, la ventana accesible de toma de pastillas en pantalla completa, la función de posponer (snooze), la previsualización de notificaciones móviles y la sincronización con el reloj del teléfono.

---

## 🌟 1. ¿Cómo funcionan las Alarmas en tu Teléfono?

A diferencia de un simple mensaje de texto que puede pasar desapercibido, el sistema de recordatorios de **Envejecer con Bienestar** fue diseñado especialmente para personas mayores:

* **Sonido Claro y Reconfortante:** Emite un tono audible que no asusta pero se hace notar, incluso si tienes el teléfono sobre la mesa de noche o en la sala.
* **Vibración Notoria:** Alerta rítmica en el bolsillo si estás en un lugar silencioso o en un evento familiar.
* **Funciona sin Conexión a Internet:** Las alarmas se programan directamente en el reloj interno del sistema operativo (`exactAllowWhileIdle` en zona horaria local). Aunque se caiga el Wi-Fi o estés de viaje, la alarma sonará con puntualidad británica.
* **Reprogramación Automática ante Reinicios:** Si el teléfono se apaga o se descarga la batería, el servicio (`reprogramarTodasLasAlarmas`) reactiva y recalcula todas las citas horarias tan pronto el móvil enciende.

---

## 🔔 2. Ventana de Alarma en Pantalla Completa (`AlarmaTomaDialog`)

Cuando llega la hora exacta de tomar tu medicina, la aplicación presenta una ventana accesible de alta visibilidad con **3 botones táctiles ergonómicos ($\ge 56$dp de altura)**:

```
+──────────────────────────────────────────────────────────────────+
|                    🔔 ¿Es hora de tu medicina?                   |
|                  Recordatorio prioritario de salud               |
+──────────────────────────────────────────────────────────────────+
|  💊 [ Losartán Potásico 50 mg ]      ⏰ Horario: 08:00 AM        |
|  📋 Indicación médica: "Tomar con un vaso de agua tras comer"    |
|  📦 Stock en botiquín: 🟢 Quedan 28 pastillas (14 días)          |
+──────────────────────────────────────────────────────────────────+
|                                                                  |
|   [  ✓ Ya me la tomé  ]      --> (Verde: marca tomada y descuenta)|
|                                                                  |
|   [ ⏰ Recordarme en 10 min ] --> (Ámbar: pospone con cariño)    |
|                                                                  |
|   [  ✕ Omitir por ahora  ]   --> (Gris: cierra sin presiones)    |
|                                                                  |
+──────────────────────────────────────────────────────────────────+
```

### Opciones de Acción Amigable:
1. **Botón Verde: *"✓ Ya me la tomé"***
   - Marca la dosis como tomada en el registro del día con confeti visual (`🎉`).
   - Descuenta automáticamente 1 pastilla del botiquín virtual.
   - Informa en tiempo real al familiar o cuidador que la dosis fue cumplida.
2. **Botón Ámbar: *"⏰ Recordarme en 10 minutos"* (Función Snooze)**
   - Si estás ocupado, almorzando o necesitas agua fresca, la aplicación pospone la alarma exactamente 10 minutos.
   - Programa una alarma secundaria automática para timbrar suavemente sin generar frustración.
3. **Botón Gris: *"✕ Omitir por ahora"***
   - Si el médico ordenó suspender la toma por un examen o prefieres revisarlo después, cierra la ventana con respeto sin alterar tu rutina.

---

## 📋 3. Gestión y Personalización Integrada en Cada Medicamento

Para mantener la pantalla de Medicamentos limpia, accesible y fácil de navegar, se conservan estrictamente **2 pestañas**:

```
+──────────────────────────────────────────────────────────────────+
|           [ 📋 Tomas de Hoy ]        [ 📦 Mi Botiquín ]          |
+──────────────────────────────────────────────────────────────────+
```

Al tocar cualquier medicamento, se abre su ficha detallada (`MedicamentoPopupDialog`) donde encontrarás el módulo de alarmas:

```
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
```

### Herramientas accesibles en cada medicina:
* **Botón `[ 🔔 Ver Pantalla de Alarma Activa ]`:** Permite simular y familiarizarse con la ventana de alarma en cualquier momento.
* **Botón `[ 🔊 Probar Sonido ]`:** Emite el timbre para ajustar el volumen del teléfono junto a tus seres queridos.
* **Botón `[ 🔄 Sincronizar ]`:** Vuelve a alinear las alarmas con el reloj del teléfono tras editar la dosis o viajar a otra zona.
* **Previsualización de Notificación Telefónica:** Muestra exactamente el texto que se desplegará en la barra de notificaciones del dispositivo móvil.

---

## 🛡️ 4. Supervisión para Cuidadores y Familiares

Desde el **Panel de Supervisión** del cuidador (`CuidadorDashboardScreen`):
1. **Seguimiento en Vivo:** Barra de tomas del día (ej. *2 de 3 tomas cumplidas - 66%*).
2. **Acompañamiento por WhatsApp:** Botón que redacta un mensaje cariñoso listo para enviar:  
   *«¡Hola Papá! 🌸 Te escribo con cariño para recordarte tomar tu Losartán. ¡Un abrazo enorme!»*
3. **Semáforo del Botiquín:** Alerta con días de anticipación antes de que las pastillas se agoten para comprar el repuesto en farmacia a tiempo.
