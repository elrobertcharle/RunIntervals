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

Sesión de demostración: 1 minuto de calentamiento, 4 × 400 m con avisos cada 23,0 / 22,7 / 22,4 / 22,1 segundos, 1 minuto entre esfuerzos y 1 minuto de enfriamiento. No hay recuperación adicional después de la última repetición. START inicia o reinicia; BACK termina y guarda la sesión; otro BACK sale si no hay guardado pendiente. No hay pausa.

El plan está definido en `source/WorkoutController.mc`; todavía no existe editor ni persistencia. Esta entrega admite distancias positivas múltiplos de 100 m e intervalos positivos múltiplos de 100 ms. La fase 3 añade una única actividad FIT continua, GPS, frecuencia cardíaca y vueltas por fase. BACK guarda la actividad parcial. Véanse el comportamiento de errores y el protocolo en [FASE3.md](docs/FASE3.md).

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

## Laboratorio conservado

El laboratorio mantiene su identidad de aplicación y puede coexistir con la versión de entrenamiento. Compilar con `-Lab` (y opcionalmente `-Tests`) produce `RunIntervalsLab.prg` o `RunIntervalsLab-tests.prg`. El protocolo y los controles originales están en [LABORATORIO.md](docs/LABORATORIO.md).

```powershell
node --test tests/analyze-log.test.mjs
```

Los [requisitos](docs/REQUISITOS.md) conservan el alcance completo. Fase 2 validada por el usuario en el reloj. Fase 3 implementada y pendiente de validación física del FIT. Próximas etapas: interfaz y editor; perfiles guardados; validación en pista.
