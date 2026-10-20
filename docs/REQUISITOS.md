# Proyecto RunIntervals 970
**Aplicación de entrenamiento en pista para Garmin Forerunner 970**

## 1. Objetivo principal

Desarrollar una aplicación nativa para el Garmin Forerunner 970 utilizando Garmin Connect IQ y Monkey C.

La aplicación permitirá ejecutar entrenamientos con múltiples repeticiones, ritmos diferentes, tiempos de recuperación configurables y alertas sonoras de paso cada 100 metros.

El objetivo fundamental es eliminar la necesidad de detener, guardar y reiniciar actividades para modificar los intervalos de las alertas.

## 2. Requisito más importante: precisión temporal

**PRINCIPIO TÉCNICO INNEGOCIABLE:**

Cada aviso sonoro debe calcularse respecto al instante de inicio de la repetición activa, nunca respecto al momento en que se reprodujo el pitido anterior.

Ejemplo: repetición con intervalo de 22,5 segundos.

- 100 m: 22,5 s
- 200 m: 45,0 s
- 300 m: 67,5 s
- 400 m: 90,0 s
- 500 m: 112,5 s

Fórmula:

`instante_objetivo = inicio_repeticion + numero_aviso × intervalo_ms`

El motor utilizará un reloj monotónico con resolución de milisegundos y comprobará los vencimientos con la mayor frecuencia práctica que permita Connect IQ.

Los avisos programados no deben acumular el retraso de avisos anteriores.

Los tiempos de los pitidos deberán poder introducirse con precisión de al menos una décima de segundo: 22,1; 22,2; 22,3; etc.

Es necesario distinguir entre precisión de los cálculos y precisión audible real. La latencia y variabilidad del sonido deben medirse físicamente en el Forerunner 970.

No se asumirá que un temporizador de alta frecuencia puede ejecutarse sin restricciones en el dispositivo. Se investigarán los límites del SDK, los modos de ahorro de energía y el comportamiento durante actividades prolongadas.

## 3. Alertas exclusivamente durante las repeticiones

Los pitidos de referencia cada 100 metros SOLO estarán activos durante una repetición de esfuerzo.

Durante calentamiento, recuperación y enfriamiento no se emitirán pitidos de referencia cada 100 metros.

Sí podrán existir sonidos diferenciados para indicar los cambios de fase: inicio de repetición, final de repetición, inicio de recuperación y finalización del entrenamiento.

En cada nueva repetición se reiniciará el origen temporal y se utilizará el intervalo configurado para esa repetición.

## 4. Repeticiones configurables

Cada repetición podrá tener:

- Distancia objetivo en metros.
- Ritmo objetivo en min/km.
- Intervalo sonoro cada 100 m, con décimas de segundo.
- Duración objetivo calculada.
- Tiempo de recuperación posterior.
- Opción de sonido, vibración o ambos.

Se admitirán repeticiones con diferentes ritmos dentro de una misma sesión, por ejemplo:

| Repetición | Ritmo | Aviso cada 100 m |
|---|---|---|
| 1 | 3:50/km | 23,0 s |
| 2 | 3:47/km | 22,7 s |
| 3 | 3:44/km | 22,4 s |
| 4 | 3:41/km | 22,1 s |

## 5. Transiciones completamente automáticas

Secuencia de entrenamiento:

1. Calentamiento.
2. Inicio automático de la primera repetición.
3. Pitidos cada 100 m según intervalo configurado.
4. Final automático de la repetición.
5. Inicio automático de la recuperación, sin pitidos de referencia.
6. Fin automático de la recuperación.
7. Inicio automático de la siguiente repetición con nuevo intervalo sonoro.
8. Repetición del ciclo hasta completar todas las series.
9. Enfriamiento.
10. Finalización y guardado de la actividad.

La transición debe utilizar los tiempos planificados sin acumular retrasos innecesarios.

En una primera versión se priorizará la finalización por tiempo objetivo calculado, para evitar que los errores del GPS alteren la sincronización de las marcas de la pista.

## 6. Grabación de actividad

Se pretende registrar el entrenamiento completo en una única actividad FIT compatible con Garmin Connect.

Deberá incluir, en la medida que permita la API:

- Tiempo total.
- Distancia y datos GPS.
- Ritmo.
- Frecuencia cardíaca.
- Vueltas o segmentos que permitan diferenciar esfuerzos y recuperaciones.

Las recuperaciones deben contar dentro del tiempo total de la actividad.

Se verificará el comportamiento real de ActivityRecording y la compatibilidad con las métricas y archivos FIT de Garmin.

## 7. Interfaz de usuario

Durante una repetición mostrar:

- Número de repetición actual y total.
- Tiempo restante de la repetición.
- Cuenta regresiva hasta el siguiente pitido de 100 m.
- Intervalo sonoro configurado.
- Ritmo objetivo.
- Indicador visual de esfuerzo.

Durante una recuperación mostrar:

- Estado de recuperación.
- Tiempo restante.
- Número de la próxima repetición.
- Ritmo e intervalo sonoro de la próxima repetición.

La pantalla debe ser legible mientras se corre.

## 8. Validación de precisión antes del desarrollo completo

La primera entrega será una aplicación experimental mínima que permita:

1. Configurar intervalos de 22,0; 22,5 y 23,0 segundos.
2. Emitir al menos 20 avisos consecutivos.
3. Registrar los instantes objetivo y los instantes de solicitud de sonido.
4. Comparar los avisos audibles mediante una grabación externa.
5. Comparar el comportamiento con las alertas nativas de Garmin.
6. Comprobar si hay variabilidad, retrasos o errores acumulados.
7. Realizar pruebas durante una actividad y con la pantalla en sus distintos estados.

La prueba debe distinguir entre:
- Error de programación del aviso.
- Retraso del planificador del sistema.
- Latencia de reproducción del sonido.
- Deriva temporal acumulada.

No se inventarán métricas de precisión antes de disponer de mediciones reales.

## 9. Orden de desarrollo

**Fase 1:** investigación de las APIs y prototipo experimental de precisión de pitidos.

**Fase 2:** motor de repeticiones y recuperaciones automáticas.

**Fase 3:** grabación de una actividad FIT continua y comprobación de vueltas.

**Fase 4:** interfaz de entrenamiento y editor de sesiones.

**Fase 5:** perfiles guardados y configuración de intervalos diferentes por repetición.

**Fase 6:** pruebas reales en pista y optimización.

## 10. Acuerdos y preferencias

- Dispositivo objetivo: Garmin Forerunner 970.
- Aplicación independiente para el reloj como punto de partida.
- Alertas temporales que representan marcas de 100 metros, no disparadas por GPS.
- Precisión en décimas de segundo configurable.
- Pitidos de referencia exclusivamente durante esfuerzos.
- Cambios de ritmo entre repeticiones sin intervención del corredor.
- Recuperaciones cronometradas y automáticas.
- Una única actividad de principio a fin.
- La exactitud temporal es prioritaria sobre las funciones estéticas.

**Instrucción para ChatGPT:** actuar como colaborador técnico del desarrollo. Preservar estos requisitos, verificar la documentación de Garmin antes de elegir APIs y priorizar una prueba experimental de precisión en el dispositivo físico antes de construir el resto de la aplicación.