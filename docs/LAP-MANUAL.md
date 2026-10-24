# Final de esfuerzo con LAP

El tiempo objetivo guía los avisos; el final real de cada esfuerzo lo marca el corredor con BACK/LAP (botón inferior derecho del FR970).

- El calentamiento, las recuperaciones y el enfriamiento siguen siendo automáticos.
- El esfuerzo muestra tiempo transcurrido con décimas y espera LAP sin límite asociado al objetivo.
- Los avisos se mantienen en los tiempos previstos para cada 100 m, incluido el último parcial. Después quedan en silencio hasta LAP.
- LAP cierra la vuelta FIT del esfuerzo e inicia la recuperación completa desde esa pulsación. Tras el último esfuerzo inicia el enfriamiento, sin recuperación adicional.
- El campo FIT de objetivo conserva la duración programada. La duración nativa de la vuelta es la medida real; no se sustituye por el objetivo.
- Durante recuperación y enfriamiento, LAST muestra el tiempo de la última repetición.
- LAP fuera de un esfuerzo no adelanta fases. Con recuperación cero, el siguiente esfuerzo comienza inmediatamente.
- START sigue deteniendo la sesión completa y abre las opciones de guardar o descartar. Si se detiene a mitad de esfuerzo, su vuelta es parcial.

## Comprobación antes de la pista

1. Configurar dos repeticiones cortas con recuperación y enfriamiento.
2. En la primera, esperar más allá del objetivo: el esfuerzo debe continuar y el cronómetro seguir avanzando, sin nuevos avisos tras el último parcial.
3. Pulsar BACK/LAP: comprobar el tiempo LAST y que comienza la recuperación completa. Volver a pulsar durante la recuperación: no debe adelantarla.
4. En la segunda, pulsar LAP antes del objetivo: debe comenzar directamente el enfriamiento y mostrar el tiempo real.
5. Al terminar el enfriamiento, guardar con START. Revisar las vueltas de esfuerzo en el FIT: tiempos reales distintos de los objetivos, con sus nombres y números de repetición.
6. Repetir una sesión corta en el reloj físico antes de usarla en pista; el simulador no valida botones, audio, GPS ni FIT del dispositivo real.

Las descripciones de transiciones automáticas de esfuerzo en los documentos de fases anteriores quedan sustituidas por este comportamiento.

## Validación local

- 31 pruebas Monkey C ejecutadas y aprobadas en el simulador FR970: incluyen LAP temprano/tardío, recuperación completa, esfuerzos sin recuperación, último LAP sin enfriamiento, desbordamiento del reloj, límites FIT, objetivos sin alterar y confirmación de guardado.
- Comprobación visual con una aplicación de prueba de identidad separada: el esfuerzo continuó tras el objetivo; BACK/LAP inició la recuperación, la recuperación inició el siguiente esfuerzo automáticamente y el último LAP inició el enfriamiento. La sesión terminó con COMPLETE, FIT SAVED y cero errores de vuelta o límites omitidos.
- Cronómetro con décimas revisado en pantalla. La validación en el reloj físico y la lectura de sus tiempos FIT siguen pendientes.
