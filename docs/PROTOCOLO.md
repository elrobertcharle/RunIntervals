# Prueba física de precisión — Forerunner 970

Estado inicial: sin datos reales. No se ha fijado un umbral de aceptación audible; acordarlo a partir del uso en pista y de la primera medición, antes de decidir si continuar con el producto completo.

## Preparación

Registrar fecha, modelo, firmware, SDK, versión del código, batería inicial/final, ajuste de ahorro, sonido, vibración, pantalla siempre activa y gestos. Usar el mismo tono y distancia al micrófono. Desactivar sonidos de botones si interfieren y anotar cambios en los ajustes. Verificar que se oye el tono antes de medir. Mantener Bluetooth/auriculares en un estado conocido y constante.

Compilar, pasar las pruebas Monkey C y comprobar primero una ejecución de 20 marcas en simulador. Instalar en el reloj y preparar el archivo de registro descrito en README. Anotar el orden de las ejecuciones: el identificador numérico se reinicia cuando se vuelve a abrir la aplicación.

## Matriz mínima

Para cada intervalo (22,0 / 22,5 / 23,0 s), hacer al menos tres ejecuciones completas de 20 avisos por condición:

| Condición | FIT del laboratorio | Pantalla |
|---|---|---|
| Base | No | Visible según ajustes normales |
| Pantalla en reposo | No | Dejar apagar/atenuar sin interacción |
| Actividad | Sí | Visible según ajustes normales |
| Actividad y reposo | Sí | Dejar apagar/atenuar sin interacción |

No mantener la pantalla encendida con llamadas continuas. Si una condición no es posible en ese firmware, documentarla. Después repetir con gestos y notificaciones controladas, ahorro activado si permite ejecutar la app y una sesión prolongada de pruebas consecutivas. Registrar huecos de callbacks, errores y consumo por separado. El laboratorio dura menos de ocho minutos por ejecución; no constituye por sí solo una validación de actividad prolongada continua.

Grabar externamente el audio completo y, preferentemente, vídeo del inicio/pantalla. No tocar el reloj durante cada ejecución salvo que la condición lo requiera. Cada ejecución debe producir 20 sonidos distinguibles y 20 solicitudes sin omisiones para considerarse válida para el ensayo consecutivo.

## Comparación nativa

Repetir con alertas temporales nativas de Garmin en condiciones equivalentes y guardar el audio y FIT aparte. No presuponer que admiten décimas: usar los valores nativos disponibles (por ejemplo, 22 o 23 segundos solo si el menú los admite). No presentar una alerta nativa de segundos enteros como comparación directa de 22,5 s. Anotar tono, duración y configuración utilizada, porque pueden cambiar el resultado acústico.

## Análisis

1. Conservar el TXT y audio originales; ejecutar el analizador sobre el TXT completo. Un registro truncado, error o marca omitida debe quedar visible y no eliminarse de los resultados.
2. Localizar manualmente el comienzo de cada sonido en el audio y exportar una tabla `prueba,indice,audible_ms`. Estimar incertidumbre de detección y de la frecuencia de muestreo. No confundir armónicos de un mismo tono con avisos distintos.
3. Sin sincronización absoluta, calcular `audible_n − audible_1 − (n−1) × intervalo_ms`. Esto mide error relativo desde el primer pitido, oculta su latencia inicial y no mide latencia absoluta de reproducción.
4. Para medir latencia absoluta, diseñar y documentar una sincronización independiente entre el origen monotónico y la grabación. Una pulsación filmada o el cambio de pantalla tienen latencia propia y no bastan para atribuir milisegundos al altavoz. Sin esa sincronización declarar la latencia absoluta **no medida**.
5. Comparar error relativo audible, retraso de solicitudes y su evolución. Reportar media, dispersión, máximo, errores y omisiones por condición; no mezclar pruebas nativas con el prototipo.
6. Revisar el FIT opcional: existencia, duración y apertura en Garmin Connect. La ausencia de GPS o frecuencia cardíaca en este laboratorio no cierra la validación de fase 3.

## Cierre de fase

Guardar resultados reales y archivos originales, documentar incertidumbre y decidir si la variabilidad audible permite el uso previsto. Si no lo permite, investigar los límites antes de implementar el motor completo. La prueba del ordenador verifica lógica y análisis; la validación de precisión queda abierta hasta medir físicamente el 970.
