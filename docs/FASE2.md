# Validación de la fase 2

La primera etapa fue confirmada como completada por el usuario el 20 de octubre de 2026. No se han añadido mediciones físicas al repositorio.

## Decisiones

Se mantienen las APIs de Timer y Attention verificadas en la documentación oficial de Garmin. Timer puede omitir callbacks; el motor calcula la fase vigente sobre una cronología absoluta, sin encadenar duraciones a la hora efectiva del callback.

- https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html
- https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html

Los objetivos de esfuerzo son `inicio_planificado_esfuerzo + n × intervalo`. El final del esfuerzo tiene un único tono de transición que sustituye la última marca coincidente. No se solicita ningún tono de referencia de una fase ya terminada. Los tonos de transición sí pueden sonar en recuperación y enfriamiento.

Cada callback produce como máximo un tono. Si se cruzaron varias fases, se notifica únicamente el estado vigente. No hay corrección acústica supuesta ni cambios al protocolo del laboratorio.

## Comprobación en dispositivo

Validación local del 20 de octubre de 2026: compilaciones de entrenamiento, laboratorio y paquete de pruebas de entrenamiento correctas con SDK 9.3.0, Java 21 y destino `fr970`. El compilador avisa sobre accesos a contenedores sin tipos explícitos y escalado del icono de 80 a 65 píxeles. Las tres pruebas Node del analizador pasan. Las siete pruebas Monkey C (tres del motor original y cuatro del motor de entrenamiento) se compilan, pero no se han ejecutado: el simulador termina con código `-1` y monkeydo no puede conectarse. La verificación física de esta fase sigue pendiente.

1. Verificar el calentamiento sin avisos de referencia y el inicio automático de la serie 1.
2. Comprobar marcas interiores a 23,0 s y transición a recuperación a los 92,0 s del origen planificado del esfuerzo.
3. Comprobar recuperación de 60 s sin avisos de referencia; después serie 2 con intervalo de 22,7 s.
4. Repetir con series 3 y 4; la última va directamente a enfriamiento y finaliza tras 60 s.
5. Comprobar cancelación, reinicio con origen nuevo y salida.
6. Repetir con pantalla atenuada; comparar los objetivos con los sonidos externos. Los límites físicos siguen dependiendo del dispositivo y del firmware.

Esta fase no valida grabación FIT, GPS, frecuencia cardíaca, editor ni perfiles.
