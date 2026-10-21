// Pure timeline. All offsets are relative to one monotonic session origin.
// Repetitions: [distance in metres, milliseconds per 100 m, recovery ms].
class WorkoutEngine {
    var phases = [];
    var index = 0;
    var clock;
    var nextMark = 1;
    var skipped = 0;
    var totalMs = 0l;

    function initialize(repetitions, warmupMs, cooldownMs, startTick) {
        if (repetitions.size() == 0 || warmupMs < 0 || cooldownMs < 0) {
            throw new Toybox.Lang.InvalidValueException("Empty workout or negative duration");
        }
        clock = new DeadlineEngine(1, 1, startTick);
        addPhase("WARM-UP", warmupMs, -1, 0);
        for (var i = 0; i < repetitions.size(); i += 1) {
            var r = repetitions[i];
            if (r[0] <= 0 || r[0] % 100 != 0 || r[1] <= 0 || r[1] % 100 != 0 || r[2] < 0) {
                throw new Toybox.Lang.InvalidValueException("Invalid repetition");
            }
            addPhase("EFFORT", (r[0] / 100) * r[1].toLong(), i, r[1]);
            // Recovery belongs between repetitions, never after the final one.
            if (i + 1 < repetitions.size()) { addPhase("RECOVERY", r[2], i + 1, 0); }
        }
        addPhase("COOL-DOWN", cooldownMs, -1, 0);
        if (totalMs >= 4294967296l) {
            throw new Toybox.Lang.InvalidValueException("Workout too long");
        }
    }

    // phase = [name, planned start, planned end, repetition index, interval].
    function addPhase(name, duration, repetition, interval) {
        if (duration == 0) { return; }
        phases.add([name, totalMs, totalMs + duration, repetition, interval]);
        totalMs += duration;
    }
    function done() { return index >= phases.size(); }
    function phase() { return done() ? null : phases[index]; }
    function elapsed(tick) { return clock.elapsed(tick); }

    // Return [phase changed, reference mark]. Never replay expired phases.
    // The end-of-effort transition replaces its coincident final 100 m tone.
    function update(tick) {
        var now = elapsed(tick);
        var changed = false;
        while (!done() && now >= phase()[2]) {
            var old = phase();
            if (old[0].equals("EFFORT")) {
                var remaining = ((old[2] - old[1]) / old[4]).toNumber() - nextMark;
                if (remaining > 0) { skipped += remaining; }
            }
            index += 1;
            nextMark = 1;
            changed = true;
        }
        if (done() || !phase()[0].equals("EFFORT")) { return [changed, false]; }
        var p = phase();
        var due = ((now - p[1]) / p[4]).toNumber();
        if (due < nextMark) { return [changed, false]; }
        skipped += due - nextMark;
        nextMark = due + 1;
        return [changed, true];
    }
}
