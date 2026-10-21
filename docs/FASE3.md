# Fase 3: actividad continua y vueltas

La fase 2 fue probada satisfactoriamente en el Forerunner 970 según confirmación del usuario el 20 de octubre de 2026. Esta entrega añade ActivityRecording a la misma aplicación y conserva su identificador. El laboratorio sigue separado.

## Funcionamiento

- Al abrir la aplicación se solicitan GPS continuo y frecuencia cardíaca. Se muestra su disponibilidad; esperar GPS OK al aire libre antes de START para registrar la ruta desde el principio. Se puede iniciar sin señal para una prueba interior.
- START crea una única sesión FIT de carrera y después fija el origen monotónico del entrenamiento. Calentamiento, esfuerzos, recuperaciones y enfriamiento quedan dentro de esa grabación sin pausas.
- Cada transición intermedia solicita una vuelta. El tono se solicita primero, antes del trabajo de grabación. La finalización detiene y guarda la sesión; stop/save cierra la última vuelta, sin añadir una vuelta vacía.
- BACK durante el entrenamiento termina y guarda la actividad parcial. Al finalizar correctamente aparece FIT GUARDADO. START permite otra sesión; BACK sale.
- Un fallo de stop/save conserva la sesión en memoria y bloquea un nuevo entrenamiento. START o BACK reintenta guardarla. onStop realiza otro intento al cerrar la aplicación. No se descarta la actividad automáticamente. Un cierre forzado, batería agotada o fallo persistente del sistema no garantiza recuperación.
- Los errores de vueltas se muestran al terminar. addLap no permite fechar vueltas en el pasado: un callback que cruce varias fases crea como máximo una vuelta actual y contabiliza límites omitidos como Saltos. No se reconstruyen vueltas ficticias. Esto no cambia los objetivos temporales del motor.

Los datos reales de distancia, velocidad/ritmo, GPS y FC dependen del dispositivo, la señal y los sensores. Los metros planificados de los esfuerzos no se inyectan como distancia medida. Las vueltas son vueltas normales de carrera; se identifican por orden, sin prometer etiquetas nativas de entrenamiento ni métricas avanzadas de Garmin.

## Prueba física

Copiar el nuevo RunIntervals.prg a GARMIN/APPS y abrir RunIntervals. Esperar GPS OK al aire libre y comprobar FC. START inicia la misma sesión de demostración de la fase anterior.

| Vuelta | Fase | Duración objetivo |
|---|---|---|
| 1 | Calentamiento | 1:00 |
| 2 | Esfuerzo 1 | 1:32 |
| 3 | Recuperación | 1:00 |
| 4 | Esfuerzo 2 | 1:30,8 |
| 5 | Recuperación | 1:00 |
| 6 | Esfuerzo 3 | 1:29,6 |
| 7 | Recuperación | 1:00 |
| 8 | Esfuerzo 4 | 1:28,4 |
| 9 | Enfriamiento | 1:00 |

Total planificado: 11:00,8. Las duraciones FIT corresponden a las solicitudes reales y a la resolución de Garmin; no se promete coincidencia al milisegundo. Al finalizar comprobar FIT GUARDADO, cero vueltas fallidas y cero saltos. Sincronizar Garmin Connect y revisar una sola actividad de carrera, nueve vueltas, tiempo de recuperación incluido, mapa al aire libre y curva de FC si hay datos.

Probar además BACK a mitad de sesión: debe guardar una actividad parcial. Después ejecutar otra sesión sin cerrar la app y comprobar que se guarda separada. Repetir con pantalla atenuada y verificar que los pitidos siguen comportándose como en fase 2. Compartir el FIT exportado o los resultados de Garmin Connect permite revisar la grabación real.

## Validación local

SDK 9.3.0, Java 21, destino fr970. Las diez pruebas Monkey C se ejecutaron satisfactoriamente en el simulador: siete del motor y tres de ciclo FIT con sesiones simuladas, incluyendo errores stop/save, excepción de guardado, reinicio, cancelación y callbacks perdidos. Estas pruebas no validan señal física, archivo FIT real ni sincronización con Garmin Connect. La prueba de dispositivo permanece pendiente.

APIs oficiales verificadas:

- https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording/Session.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Position.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Sensor.html

También se consultó el ejemplo RecordSample del SDK instalado para activación/desactivación de GPS y grabación.
