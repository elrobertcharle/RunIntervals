# Identificación de fases en el FIT

La aplicación conserva la misma sesión de demostración (11:00,8 planificados, nueve vueltas), el motor temporal y la interfaz en inglés. Se añaden campos de desarrollador; no se sobrescriben los campos nativos de Garmin.

## Campos

| ID | Nombre FIT | Mensaje | Significado |
|---|---|---|---|
| 0 | Phase name | Lap | Warm-up, Effort 1…N, Recovery, Cool-down o Mixed phases |
| 1 | Phase type | Lap | 0: varias fases; 1: calentamiento; 2: esfuerzo; 3: recuperación; 4: enfriamiento |
| 2 | Repetition | Lap | Número de esfuerzo; cero fuera de esfuerzos |
| 3 | Target duration | Lap | Duración planificada de la fase, en segundos; no sustituye la duración real de la vuelta |
| 4 | 100m interval | Lap | Intervalo objetivo en segundos; cero fuera de esfuerzos |
| 5 | Workout result | Session | COMPLETE, CANCELLED, APP STOP, START ERROR, SOUND ERROR o INTERRUPTED |
| 6 | Lap errors | Session | Solicitudes de vuelta fallidas |
| 7 | Missed boundaries | Session | Límites de fase omitidos por callbacks tardíos |

Si se cruzan varias fases sin registrar su límite o falla addLap, la vuelta que combina fases lleva Mixed phases y código 0. Repetition, Target duration y 100m interval son cero en esa vuelta para no adjudicarle un objetivo incorrecto.

Una cancelación guarda la vuelta parcial con el nombre de su fase y la duración objetivo completa; la duración real sigue siendo la calculada por Garmin. Workout result identifica la cancelación. Los reintentos de guardado conservan ese resultado y no vuelven a escribir campos de vuelta después de detener la grabación.

Los nombres de los campos y los valores de texto están en inglés. Se incluyen recursos para solicitar que Garmin Connect muestre los campos numéricos en vueltas y resumen; la presentación real, especialmente para una aplicación instalada por USB, debe comprobarse en Garmin Connect. Estos campos no convierten las vueltas en pasos de un entrenamiento nativo. Para revisarlos se debe usar el FIT original, sin depender de su conservación en TCX.

## Inicio y reinicio

El plan se construye antes de iniciar FIT; los campos se crean al empezar la grabación y el origen monotónico se fija después de esa preparación. La grabación FIT puede incluir ese pequeño tiempo de preparación en la primera vuelta. No se recortan ni se falsifican tiempos reales.

Después de guardar, la aplicación espera al menos un segundo antes de permitir una nueva sesión. Una pulsación demasiado rápida muestra PLEASE WAIT; pulsar START nuevamente una vez transcurrido ese segundo. Esto evita solicitar otra grabación mientras el sistema nativo está finalizando la anterior.

## Timestamps de resumen

No hay que reparar los timestamps del FIT proporcionado por el usuario. Garmin documenta que, en Summary First, los timestamps de los resúmenes pueden corresponder a la creación del archivo. El final de cada resumen se obtiene con start_time + total_elapsed_time.

Fuente: https://forums.garmin.com/developer/fit-sdk/b/news-announcements/posts/important-fit-activity-file-message-change

## Validación

- Compilación para fr970 con SDK 9.3.0 y Java 21.
- Trece pruebas Monkey C: motor, grabación y errores, campos por fase, vueltas combinadas, cancelación, reintentos, reinicio y espera tras guardado con desbordamiento del contador.
- Una sesión abreviada de simulador se guardó como FIT y se decodificó con el SDK oficial: cinco vueltas (Warm-up, Effort 1, Recovery, Effort 2, Cool-down), objetivos e intervalos correctos, COMPLETE y cero errores. No es una medición del dispositivo físico.
- Otra prueba abreviada guardó una sesión cancelada (4,515 s, tres vueltas, CANCELLED) y, tras esperar un segundo, una sesión completa (11,000 s, cinco vueltas, COMPLETE). Ambos FIT superaron el CRC. El intento inicial de reinicio sin espera falló en el simulador; de ahí la espera mínima añadida.
- Queda pendiente verificar en el 970 físico los campos nuevos, la presentación en Garmin Connect y la cancelación seguida de una nueva sesión.

API de campos: https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording/Session.html
