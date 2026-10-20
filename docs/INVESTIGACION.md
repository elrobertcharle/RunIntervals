# Decisiones para la fase 1

Consulta de documentación oficial: 20 de octubre de 2026. Estas conclusiones describen APIs, no mediciones del Forerunner 970.

| Tema | Evidencia y decisión |
|---|---|
| Reloj | [System.getTimer](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function) proporciona un contador en milisegundos desde el arranque que desborda periódicamente. Se usa para tiempo transcurrido, convirtiendo a Long antes de restar y corrigiendo el ciclo de 32 bits; no se usa hora civil. Validar continuidad física con firmware y estados de pantalla. |
| Temporizador | [Timer.Timer](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html) indica un mínimo por defecto de 50 ms y tres temporizadores, dependientes del sistema; los callbacks repetidos perdidos se omiten. Se emplea un temporizador de 50 ms como hipótesis experimental, no como límite confirmado específico del 970 ni garantía de puntualidad. |
| Sonido | [Attention.playTone](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#playTone-instance_function) solicita un tono predefinido y devuelve Void. No aporta un instante de comienzo audible. Se verifica disponibilidad con `has`; se usa siempre el mismo tono para comparar ejecuciones. |
| Grabación | [ActivityRecording](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html) y [Session](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording/Session.html) permiten iniciar, detener, guardar y crear vueltas. Se añade una grabación opcional mínima exclusivamente para ensayar carga durante la fase 1. No se garantiza presencia de todas las métricas nativas. |
| Permisos | [Manifest and Permissions](https://developer.garmin.com/connect-iq/core-topics/manifest-and-permissions) documenta `Fit` para ActivityRecording. No se solicitan aún sensores ni ubicación. |
| Pantalla y energía | [Timer](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html) restringe temporizadores en esferas de reloj en bajo consumo. El prototipo es una watch-app: esa restricción no demuestra su comportamiento con pantalla apagada. No se fuerza retroiluminación ni se asumen callbacks de sueño de WatchFace para esta aplicación. |

## Límites de interpretación

El contador tiene resolución nominal de milisegundos; su exactitud respecto a un reloj externo y el instante audible requieren medición. El periodo de sondeo de 50 ms introduce cuantización y puede excederse por planificación, carga o suspensión. No es una promesa de ±50 ms.

Se separan cuatro magnitudes:

1. **Error de cálculo:** el objetivo debe ser exactamente `n × intervalo_ms` relativo al origen. Comprobar con el analizador y pruebas del motor.
2. **Retraso de solicitud:** `request_ms − target_ms`. Incluye cuantización del sondeo, planificación y ejecución anterior a la llamada. El registro por sí solo no permite aislarlas.
3. **Duración de llamada:** `return_ms − request_ms`. No equivale a latencia del altavoz.
4. **Tiempo audible:** se obtiene de audio externo. La variación entre periodos se puede medir sin sincronización; la latencia absoluta necesita sincronizar el reloj externo y el origen de la aplicación.

La separación entre callbacks ayuda a detectar bloqueos; no es una medida exclusiva del planificador. Una pendiente en el error acústico puede incluir diferencias entre osciladores del reloj y del grabador. No corregir anticipadamente el sonido mediante una latencia supuesta.

## Pendiente de investigar con SDK y dispositivo

- Mínimo aceptado por `fr970`, cadencia efectiva, consumo y continuidad durante apagado de pantalla, gestos y notificaciones.
- Comportamiento con actividad grabándose, modo de ahorro y ajustes de sonido/silencio.
- Registro de GPS y sensores, calidad de ritmo/distancia, vueltas, mensajes FIT y sincronización a Garmin Connect en fase 3.
- Soporte efectivo del proyecto, recurso SVG y compilación para la definición instalada de `fr970`.
- Medición audible y comparación nativa. Ningún resultado del simulador permite cerrar esta validación.
