# RunIntervals 970

Aplicación Monkey C para Garmin Forerunner 970. Desarrollo de la versión definitiva en `codex/version-definitiva`.

La primera etapa de precisión está completada según confirmación del usuario. Los archivos de medición no están versionados; no se atribuyen cifras de precisión audible sin esos datos.

## Fase 2: motor automático

- Calentamiento → esfuerzos y recuperaciones → enfriamiento → finalización.
- Cronología absoluta desde un reloj monotónico: una transición tardía no desplaza los objetivos posteriores.
- Origen planificado propio para cada esfuerzo y avisos con décimas de segundo.
- Avisos de 100 m solo durante esfuerzos. El tono de cambio de fase reemplaza el aviso coincidente con el final del esfuerzo, para evitar dos sonidos simultáneos.
- Ante callbacks perdidos, solo se solicita el último aviso vencido de la fase vigente. Las fases vencidas no se reproducen; se cuentan las marcas interiores omitidas.
- Pantalla básica con fase, repetición, tiempo restante, siguiente marca, ritmo e intervalo.

Sesión de demostración: 1 minuto de calentamiento, 4 × 400 m con avisos cada 23,0 / 22,7 / 22,4 / 22,1 segundos, 1 minuto entre esfuerzos y 1 minuto de enfriamiento. No hay recuperación adicional después de la última repetición. START inicia y, durante el entrenamiento, detiene. No hay pausa/reanudación.

Al terminar automáticamente o con START, se detiene la grabación y aparece `ACTIVITY STOPPED`, con `Save` seleccionado por defecto. UP/DOWN elige `Save` o `Discard`; START selecciona. `Save` guarda la actividad. `Discard` abre una segunda confirmación: START descarta y BACK cancela el descarte. BACK desde el menú vuelve al resumen sin guardar ni descartar; START desde el resumen reabre el menú. Durante el entrenamiento BACK no detiene ni guarda. La actividad pendiente bloquea nuevas sesiones, la edición y la salida con BACK hasta guardarla o descartarla. Cerrar forzosamente la aplicación no guarda automáticamente y no garantiza recuperar una actividad sin confirmar. Este cambio está verificado con 28 pruebas aprobadas en el simulador; falta validarlo en el reloj.

La fase 4 añade un editor en el reloj (UP o MENU antes de iniciar), un borrador con aplicar/cancelar y una pantalla de entrenamiento con cuenta regresiva grande y progreso por fase. Controles y límites en [FASE4.md](docs/FASE4.md). La fase 5 conserva la última sesión aplicada al salir, añade tres perfiles persistentes y permite editar distancia, intervalo y recuperación por repetición. Uso y protocolo en [FASE5.md](docs/FASE5.md). La fase 3 conserva una única actividad FIT continua, GPS, frecuencia cardíaca y vueltas por fase. START permite terminar la actividad parcial y elegir guardar o descartar. El flujo de guardado descrito en documentos de fases anteriores queda sustituido por el indicado arriba.

## Compilar

Requiere Connect IQ SDK, dispositivo `fr970`, Java en PATH y clave de desarrollador fuera del control de versiones. El equipo dispone de SDK 9.3.0 y Java 21; configurar sus rutas en cada terminal.

```powershell
.\tools\build.ps1 -SdkPath 'C:\ruta\al\sdk' -DeveloperKey 'C:\ruta\privada\developer_key'
.\tools\build.ps1 -SdkPath 'C:\ruta\al\sdk' -DeveloperKey 'C:\ruta\privada\developer_key' -Tests
```

Resultados: `bin/RunIntervals.prg` y `bin/RunIntervals-tests.prg`. Con el simulador abierto, ejecutar desde el SDK:

```powershell
monkeydo.bat bin\RunIntervals-tests.prg fr970 /t
```

Las pruebas Monkey C cubren objetivos absolutos, límites de fase, cambios de intervalo, omisiones, finalización, configuración inválida y desbordamiento del contador. Compilar el paquete de pruebas no equivale a ejecutarlo.

Para instalar en el reloj, copiar `bin/RunIntervals.prg` a `GARMIN/APPS`. Validar primero en simulador y después comprobar las transiciones en el 970 físico.

## Iniciar el simulador en Windows

Desde PowerShell, abrir el simulador como un proceso independiente:

```powershell
cd C:\Users\merom\source\repos\RunIntervals
$sdk = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
Start-Process -FilePath "$sdk\bin\simulator.exe"
```

Cuando aparezca la ventana del simulador, cargar la aplicación desde la misma terminal:

```powershell
& "$sdk\bin\monkeydo.bat" .\bin\RunIntervals.prg fr970
```

`Start-Process` deja la terminal disponible sin pulsar Ctrl+C. La variable `$sdk` debe definirse de nuevo al abrir otra terminal. La ventana gris inicial del simulador es normal hasta cargar la aplicación. Pulsar START para iniciar el entrenamiento, o UP/MENU para editar la sesión antes de empezar.

## Laboratorio conservado

El laboratorio mantiene su identidad de aplicación y puede coexistir con la versión de entrenamiento. Compilar con `-Lab` (y opcionalmente `-Tests`) produce `RunIntervalsLab.prg` o `RunIntervalsLab-tests.prg`. El protocolo y los controles originales están en [LABORATORIO.md](docs/LABORATORIO.md).

```powershell
node --test tests/analyze-log.test.mjs
```

Los [requisitos](docs/REQUISITOS.md) conservan el alcance completo. Fase 2 validada por el usuario en el reloj. Fase 3 implementada y pendiente de validación física del FIT. Fase 4 validada por el usuario en el simulador; queda pendiente su validación física. Fase 5 implementada: compilaciones correctas y 22 pruebas aprobadas en el simulador; pendiente de validación manual de la nueva interfaz y de persistencia al cerrar/reabrir en el reloj. Fase 6: validación en pista y optimización.

La fase 3 añade ahora nombres de fase, objetivos y resultado de la sesión como campos FIT de desarrollador. Detalles y límites en [FIT-METADATA.md](docs/FIT-METADATA.md).
