# Fase 4: pantalla de entrenamiento y editor

La sesión se configura en el reloj antes de iniciar. La interfaz sigue en inglés.
Se conservan el motor de tiempos absolutos, las alertas de esfuerzo y la grabación FIT continua.
No hay pausa. BACK durante una actividad termina y guarda la parte realizada.

## Controles

- Inicio o resultado: START inicia; UP o MENU abre el editor; BACK sale.
- Actividad: START no reinicia; UP/MENU no abre el editor; BACK termina y guarda.
- FIT pendiente: START o BACK reintenta el guardado; el editor queda bloqueado.
- Editor: UP/DOWN recorre campos; START entra a cambiar el valor.
- Cambiando un valor: UP suma y DOWN resta; START confirma en el borrador;
  BACK cancela ese cambio de valor.
- `Apply session` aplica el borrador y vuelve al inicio. BACK desde la navegación
  de campos descarta todo el borrador.

## Campos y alcance

| Campo | Valores | Paso |
|---|---|---|
| Repeticiones | 1–40 | 1 |
| Distancia por repetición | 100–10 000 m | 100 m |
| Intervalo de 100 m | 1,00–120,00 s | 0,05 s |
| Recuperación | 0–60 min | 5 s |
| Calentamiento | 0–60 min | 5 s |
| Enfriamiento | 0–60 min | 5 s |

El ritmo se calcula a partir del intervalo: 22,5 s/100 m equivale a 3:45/km.
La distancia, el intervalo y la recuperación editados se aplican a todas las
repeticiones. Cambiar otro campo conserva los intervalos variados de la demo.
El editor indica cuando los valores son mixtos. Al ampliar la cantidad, las nuevas
repeticiones copian los parámetros de la primera, sin compartir sus arrays.
La última repetición nunca tiene recuperación posterior. Cero omite las fases opcionales.

Comportamiento original de fase 4 (sustituido por [FASE5.md](FASE5.md)):
la configuración aplicada se conserva al reiniciar una sesión dentro de la app,
pero se pierde al salir de ella. Los perfiles persistentes y la edición individual
por repetición corresponden a la fase 5.

## Pantalla de entrenamiento

Nombre y color de fase, repetición actual o próxima, tiempo restante grande,
cuenta regresiva de 100 m durante el esfuerzo, ritmo e intervalo objetivo,
barra de progreso de fase, GPS y frecuencia cardíaca. En calentamiento y recuperación
se muestran los datos de la próxima repetición. La última marca del esfuerzo se
etiqueta `End`: allí suena el cambio de fase. El resultado congela el tiempo al terminar
y muestra estado FIT, avisos omitidos y errores de vueltas.

## Validación

`WorkoutPlanTest.mc` cubre aislamiento del borrador, cancelación de un valor,
navegación del editor, límites, copias independientes y una cronología editada:
dos esfuerzos de 800 m a 22,5 s/100 m, recuperación de 30 s, sin calentamiento
y 10 s de enfriamiento (6:40 total).

Comprobar en el FR970 antes de validar en pista:

1. Abrir el editor, cambiar un valor y cancelar con BACK; comprobar que no se aplica.
2. Aplicar una sesión corta: 2 × 100 m, 5,0 s/100 m, recuperación 5 s,
   calentamiento 0 s y enfriamiento 5 s (20 s total).
3. Confirmar que UP aumenta y DOWN reduce al editar, y que el texto cabe en el círculo.
4. Confirmar esfuerzo → recuperación → esfuerzo → enfriamiento → guardado;
   solo los esfuerzos producen avisos de referencia.
5. Reiniciar, terminar con BACK y comprobar FIT parcial y duración congelada.
6. Confirmar que después de `Apply session` aparece `Edit each rep`.
7. Revisar GPS, frecuencia cardíaca y vueltas del FIT en Garmin Connect.

Compilar y usar el simulador no verifica la latencia audible ni el FIT físico.

Validación del 21 de octubre de 2026: compilación normal y de pruebas correcta
con SDK 9.3.0 para `fr970`; 16 pruebas ejecutadas, 16 aprobadas, sin fallos ni errores.
La ventana vacía del simulador se recuperó cerrando el proceso bloqueado y
reiniciándolo. Se verificó la pantalla inicial y se acortaron sus instrucciones
inferiores para evitar recortes. El usuario confirmó el funcionamiento de la
interfaz y el editor en el simulador y aprobó cerrar la fase 4. La validación
física en el FR970 y en pista sigue pendiente. El compilador
mantiene advertencias de tipado de contenedores, escala del icono y unidad FIT vacía.

APIs de UI verificadas en la documentación oficial de Garmin:
[BehaviorDelegate](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html),
[Graphics.Dc](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html).
