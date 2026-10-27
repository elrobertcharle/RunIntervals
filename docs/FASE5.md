# Fase 5: perfiles guardados y edición individual

Implementación disponible para el FR970. Interfaz en inglés, sin pausa.
Actualización de controles: START inicia y, durante el entrenamiento, detiene.
El final automático también detiene y abre el menú `ACTIVITY STOPPED`.
UP/DOWN elige `Save` o `Discard`; START selecciona. Save guarda; Discard pide
una segunda confirmación con START y BACK la cancela. BACK en el menú vuelve
al resumen sin guardar ni descartar; START en el resumen reabre el menú con Save
seleccionado. Durante el entrenamiento BACK no hace cambios. No hay reanudación.
La actividad pendiente bloquea nuevas sesiones, la edición y la salida con BACK
hasta guardar o descartar. No se guarda automáticamente al cerrar la app y un
cierre forzoso no garantiza recuperar una actividad pendiente. El flujo sustituye
las referencias anteriores a finalizar o guardar con BACK. Pruebas actualizadas:
28/28 aprobadas en el simulador, incluidos cancelación de descarte, fallos al
detener/guardar/descartar, reintentos y cierre sin guardar.
La validación manual de la nueva interfaz en simulador y reloj sigue pendiente;
esta fase no se considera validada físicamente.

## Sesión persistente

`Apply session` valida y guarda la sesión antes de sustituir la configuración activa.
La próxima apertura recupera esa sesión, incluidos los valores de cada repetición.
Si falla la escritura, aparece `Apply failed: retry`, el editor conserva el borrador
y la sesión activa no cambia. Aplicar queda bloqueado con actividad en curso o FIT pendiente.
Un registro ausente inicia la demo; uno inválido o ilegible inicia la demo con
`SAVED PLAN ERROR`. Los datos inválidos no se sobrescriben hasta aplicar otra sesión.

## Edición por repetición

1. UP o MENU desde inicio/resultado abre el editor.
2. Seleccionar `Edit each rep` con START.
3. En `Repetition`, START permite elegir 1–40 dentro de la cantidad configurada.
4. Editar `Distance`, `100 m interval` y `Recovery after` con START, UP/DOWN y START.
5. BACK cancela un valor sin confirmar. Fuera de un valor vuelve al editor general
   conservando los cambios en el borrador. También se puede usar `Session editor`.
6. `Apply session` aplica y guarda todo. BACK desde el editor general descarta el borrador.

Se mantienen los límites de fase 4: distancia 100–10 000 m por pasos de 100 m;
intervalo 1,0–120,0 s por pasos de 0,1 s; recuperación 0–60 min por pasos de 5 s.
La recuperación de la última repetición se conserva como dato pero nunca se ejecuta.
Los campos globales de distancia, intervalo y recuperación siguen modificando todas
las repeticiones. Cambiar la cantidad conserva las existentes; las nuevas copian
la primera. La pantalla inicial señala distancias y recuperaciones variadas.

## Tres perfiles

Los perfiles se identifican como `Slot 1`, `Slot 2` y `Slot 3`, sin nombres editables.

- `Profile slot`: elegir el número con START y UP/DOWN.
- `Save profile`: guarda el borrador completo en el slot elegido. Requiere START
  dos veces; sustituye cualquier contenido anterior. BACK o moverse cancela la confirmación.
- `Load profile`: carga el slot en el borrador; revisar y usar `Apply session`.
  Un slot vacío, inválido o ilegible muestra un mensaje y conserva el borrador.
- `Delete profile`: requiere START dos veces. Borra solo el slot; conserva el
  borrador y la sesión activa. BACK o moverse cancela la confirmación.

Guardar y borrar son acciones persistentes inmediatas: salir del editor con BACK
no deshace esas acciones. Cada slot es independiente de los demás
 y de la última sesión aplicada.

## Almacenamiento

Se usa [Application.Storage de Garmin](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html),
consultado el 21 de octubre de 2026. Cada clave contiene un registro versionado:
`[1, warmupMs, cooldownMs, repetitions]`, con arrays de tres enteros por repetición.
No se almacenan objetos de clases ni símbolos. Se validan tipos, versión, límites,
pasos y cronología al leer. Las copias independientes evitan que editar un borrador
modifique un perfil cargado. No se accede al almacenamiento durante el entrenamiento.

## Verificación realizada

21 de octubre de 2026, SDK 9.3.0, dispositivo `fr970`:

- Compilación normal y de pruebas correctas.
- 22 pruebas ejecutadas en el simulador: 22 aprobadas, 0 fallos, 0 errores.
- Incluyen lectura/escritura/borrado con Storage nativo en una clave exclusiva de prueba,
  aislamiento de perfiles y borradores, registros inválidos, límites, confirmaciones,
  errores simulados de almacenamiento, bloqueo durante actividad/FIT pendiente y
  preservación de la sesión activa cuando falla el guardado.
- Se conserva la batería del motor, alertas, rollover y grabación FIT.
- Persisten advertencias del compilador de contenedores sin tipado, icono escalado y unidad FIT vacía.

La prueba nativa abre otra instancia del repositorio de perfiles; no sustituye la
prueba manual de cerrar/reabrir la aplicación ni la comprobación en el reloj físico.

## Protocolo manual pendiente

1. Crear dos repeticiones sin calentamiento ni enfriamiento: primera 200 m a
   22,5 s/100 m y 10 s de recuperación; segunda 400 m a 22,1 s/100 m.
2. Guardar en Slot 1, aplicar, salir y reabrir. Comprobar que los valores persisten.
3. Ejecutar: esfuerzo 45,0 s → recuperación 10 s → esfuerzo 88,4 s → final.
   Total planificado: 2:23,4. Los avisos de referencia solo suenan en esfuerzos.
4. Crear un perfil diferente en Slot 2. Cargar Slot 1, revisar y aplicar; verificar
   que Slot 2 conserva su contenido.
5. Cambiar una repetición y cancelar el valor; luego cambiarla, confirmarla y
   descartar el borrador desde el editor general. Comprobar la sesión activa.
6. Cancelar una confirmación de borrado con BACK; después borrar Slot 2 y confirmar
   que Slot 1, la sesión activa y el borrador siguen intactos.
7. Revisar legibilidad de todas las pantallas en el círculo del FR970 y probar
   reinicio de la aplicación, FIT continuo y START para terminar una actividad parcial.
   Comprobar que BACK durante el entrenamiento no lo detiene. Elegir Save con
   START y verificar FIT parcial. Repetir al completar una sesión automáticamente.
8. En otra sesión, detener con START, elegir Discard con UP/DOWN y START;
   cancelar con BACK y verificar que sigue pendiente. Volver a elegir Discard y
   confirmar con START; comprobar que no aparece una actividad guardada y que
   se puede iniciar otra sesión. Los perfiles guardados deben permanecer intactos.

La latencia audible, el FIT físico y la validación en pista siguen pendientes.
