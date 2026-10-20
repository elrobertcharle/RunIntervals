import { test } from 'node:test';
import assert from 'node:assert/strict';
import { analyze } from '../tools/analyze-log.mjs';

// Synthetic records validate the analyzer, never represent watch measurements.
const begin = 'RI_BEGIN,1,22500,50,1000,false\n';
test('validates fixed targets despite changing callback delays', () => {
  const events = Array.from({ length: 20 }, (_, i) => {
    const n = i + 1, target = n * 22500, request = target + (i % 3) * 10;
    return `RI_EVENT,${n},${target},${request},${request + 1},50,REQUESTED`;
  }).join('\n');
  const [run] = analyze(begin + events + '\nRI_END,COMPLETO,60');
  assert.equal(run.requested, 20);
  assert.equal(run.maxRequestLatenessMs, 20);
  assert.equal(run.maxApiCallMs, 1);
});
test('counts omitted marks separately from sound requests', () => {
  const [run] = analyze(begin + 'RI_EVENT,1,22500,-1,-1,45010,SKIPPED\nRI_EVENT,2,45000,45010,45011,45010,REQUESTED\nRI_END,CANCELADO,45010');
  assert.equal(run.requested, 1);
  assert.equal(run.skipped, 1);
  assert.equal(run.meanRequestLatenessMs, 10);
  assert.equal(run.requestLatenessChangeMs, null);
});
test('rejects drift, early requests, missing rows and truncated runs', () => {
  for (const event of ['RI_EVENT,1,22501,22510,22511,50,REQUESTED', 'RI_EVENT,1,22500,22499,22500,50,REQUESTED', 'RI_EVENT,2,45000,45010,45011,50,REQUESTED']) {
    assert.throws(() => analyze(begin + event + '\nRI_END,CANCELADO,50'));
  }
  assert.throws(() => analyze(begin));
  assert.throws(() => analyze(begin + 'RI_END,COMPLETO,50'));
  assert.throws(() => analyze(''));
});
