import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

export function analyze(text) {
  const runs = [];
  let run;
  for (const line of text.split(/\r?\n/)) {
    const marker = line.indexOf('RI_');
    if (marker < 0) continue;
    const [type, ...v] = line.slice(marker).trim().split(',');
    if (type === 'RI_BEGIN') {
      if (run) throw new Error('Registro truncado antes del siguiente RI_BEGIN.');
      const [id, intervalMs, pollMs, origin] = v.slice(0, 4).map(Number);
      if (![id, intervalMs, pollMs, origin].every(Number.isFinite) || intervalMs <= 0 || pollMs <= 0) throw new Error('RI_BEGIN invalido.');
      run = { id, intervalMs, pollMs, origin, fit: v[4] === 'true', events: [] };
    } else if (type === 'RI_EVENT') {
      if (!run) throw new Error('Evento sin RI_BEGIN.');
      const [index, target, request, returned, gap] = v.slice(0, 5).map(Number);
      const result = v[5];
      if (![index, target, request, returned, gap].every(Number.isFinite)) throw new Error('Evento no numerico.');
      if (index !== run.events.length + 1 || index > 20 || target !== index * run.intervalMs) throw new Error('Secuencia u objetivo incorrecto: posible deriva de programacion.');
      if (!['REQUESTED', 'SKIPPED', 'ERROR'].includes(result)) throw new Error('Resultado desconocido.');
      if (result === 'SKIPPED' ? request !== -1 || returned !== -1 : request < target || returned < request) throw new Error('Instantes incoherentes.');
      run.events.push({ index, target, request, returned, gap, result });
    } else if (type === 'RI_END') {
      if (!run) throw new Error('RI_END sin inicio.');
      run.status = v[0];
      run.maxCallbackGapMs = Number(v[1]);
      if (!Number.isFinite(run.maxCallbackGapMs) || run.maxCallbackGapMs < 0) throw new Error('Separacion de callbacks invalida.');
      if (run.status === 'COMPLETO' && run.events.length !== 20) throw new Error('Prueba completa sin 20 marcas.');
      const requested = run.events.filter(e => e.result === 'REQUESTED');
      const lateness = requested.map(e => e.request - e.target);
      run.requested = requested.length;
      run.skipped = run.events.filter(e => e.result === 'SKIPPED').length;
      run.errors = run.events.filter(e => e.result === 'ERROR').length;
      run.meanRequestLatenessMs = lateness.length ? lateness.reduce((a, b) => a + b, 0) / lateness.length : null;
      run.maxRequestLatenessMs = lateness.length ? Math.max(...lateness) : null;
      run.requestLatenessChangeMs = lateness.length >= 2 ? lateness.at(-1) - lateness[0] : null;
      run.maxApiCallMs = requested.length ? Math.max(...requested.map(e => e.returned - e.request)) : null;
      runs.push(run);
      run = undefined;
    }
  }
  if (run) throw new Error('Registro incompleto: falta RI_END.');
  if (!runs.length) throw new Error('No hay pruebas RI completas.');
  return runs;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (!process.argv[2]) throw new Error('Uso: node tools/analyze-log.mjs ruta-al-registro.txt');
    console.log(JSON.stringify({ warning: 'Solo mide solicitudes de API. No mide sonido audible ni aisla latencia interna del sistema.', runs: analyze(readFileSync(process.argv[2], 'utf8')) }, null, 2));
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
