# RunIntervals 970 — laboratorio de precisión

Primera fase del proyecto para Garmin Forerunner 970. El documento original se conserva en [docs/REQUISITOS.md](REQUISITOS.md).

Estado actualizado: primera etapa completada según confirmación del usuario. SDK 9.3.0 y Java 21 disponibles localmente. La compilación se verifica por separado de la medición física; los archivos de medición no están versionados.

## Qué incluye

- Aplicación independiente Monkey C dirigida a `fr970`.
- Selección de intervalos de 22,0 / 22,5 / 23,0 segundos y 20 marcas por prueba (7:20 / 7:30 / 7:40).
- Objetivos `origen + índice × intervalo_ms`, con aritmética entera y tratamiento del desbordamiento del reloj.
- Comprobación experimental cada 50 ms y pantalla solicitada cada 250 ms. La cadencia real depende del dispositivo.
- Registro de objetivos, solicitudes, retorno de la API, omisiones y separación entre callbacks. Se vuelca al finalizar para no escribir durante la prueba.
- Grabación FIT opcional para comparar la carga del sistema durante una actividad. Es solo una prueba básica de grabación; GPS, sensores y vueltas corresponden a fases posteriores.
- Pruebas del motor para ejecutar con el SDK y analizador de registros ejecutable con Node.

START inicia; UP cambia el intervalo; DOWN activa/desactiva FIT; BACK termina anticipadamente y guarda el FIT si está activo. Otro BACK sale. No existe pausa/reanudación en el laboratorio: cada ejecución usa un origen nuevo. Las pruebas no tienen calentamiento ni recuperación. No se generan sonidos de transición para evitar confundir el recuento acústico.

Si faltan callbacks, se registran las marcas antiguas como `SKIPPED` y se solicita solo la última vencida, siempre que no lleve un intervalo entero de retraso. Un estado `COMPLETO` significa que se procesaron las 20 marcas, no garantiza 20 solicitudes ni 20 sonidos. Una omisión invalida la prueba para evaluar 20 avisos consecutivos.

## Preparación y compilación

1. Instalar el [SDK oficial de Connect IQ](https://developer.garmin.com/connect-iq/sdk/), el Java requerido por esa versión y la extensión Monkey C de VS Code.
2. Descargar el dispositivo Forerunner 970 con SDK Manager y configurar una clave privada de desarrollador mediante la extensión. No guardar la clave en este proyecto.
3. Abrir esta carpeta en VS Code, compilar y ejecutar en el simulador para `fr970`. Revisar errores, recursos, botones y pantalla antes de copiar al reloj.
4. Alternativamente, con rutas reales al SDK y clave:

```powershell
.\tools\build.ps1 -SdkPath 'C:\ruta\al\sdk' -DeveloperKey 'C:\ruta\privada\developer_key.der' -Lab
.\tools\build.ps1 -SdkPath 'C:\ruta\al\sdk' -DeveloperKey 'C:\ruta\privada\developer_key.der' -Lab -Tests
```

Para las pruebas Monkey C usar la función de pruebas de la extensión, o iniciar el simulador y ejecutar `monkeydo bin\RunIntervalsLab-tests.prg fr970 /t` desde el entorno del SDK. Las pruebas ejercitan el motor real, pero no el altavoz ni el temporizador del dispositivo.

5. Copiar `bin/RunIntervalsLab.prg` a `GARMIN/APPS` del reloj mediante USB. Antes de desconectar, crear un archivo vacío `GARMIN/APPS/LOGS/RunIntervalsLab.TXT`. El nombre base debe coincidir con el PRG. Consultar la guía oficial de [instalación de prueba](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/) y [depuración](https://developer.garmin.com/connect-iq/core-topics/debugging/).
6. Ejecutar el [protocolo físico](PROTOCOLO.md) y copiar el registro al equipo al terminar. El búfer se pierde si el sistema cierra la aplicación de forma abrupta antes del volcado; una prueba sin `RI_END` es incompleta.

## Analizar los registros

```powershell
node --test tests/analyze-log.test.mjs
node tools/analyze-log.mjs 'C:\ruta\RunIntervalsLab.TXT'
```

El analizador comprueba cada objetivo contra la fórmula, rechaza registros truncados y distingue solicitudes, errores y omisiones. Calcula retrasos de solicitud y cambio entre el primer y último retraso; esto último no demuestra por sí solo una deriva. Sus pruebas usan datos sintéticos, nunca mediciones del reloj.

## Orden del proyecto

La primera etapa fue confirmada como completada por el usuario. Orden posterior: motor automático de esfuerzos/recuperaciones; FIT continuo con GPS, frecuencia cardíaca y vueltas; interfaz y editor; perfiles guardados; pruebas de pista. No avanzar al producto completo sin evaluar primero los resultados de precisión. Los requisitos completos y las decisiones técnicas están en `docs/`.

