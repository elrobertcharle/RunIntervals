// All offsets use one monotonic origin. LAP rebases future phases only.
// Repetitions: [distance in metres, milliseconds per 100 m, recovery ms].
class WorkoutEngine {
    var phases = [];
    var index = 0;
    var clock;
    var nextMark = 1;
    var skipped = 0;
    var totalMs = 0l;
    var effortResults = [];
    var pauseClock;
    var pausedMs = 0l;
    var lastCountdownSecond = 11;

    function initialize(repetitions, warmupMs, cooldownMs, startTick) {
        if (repetitions.size() == 0 || warmupMs < 0 || cooldownMs < 0) {
            throw new Toybox.Lang.InvalidValueException("Empty workout or negative duration");
        }
        clock = new DeadlineEngine(1, 1, startTick);
        addPhase("WARM-UP", warmupMs, -1, 0);
        for (var i = 0; i < repetitions.size(); i += 1) {
            var r = repetitions[i];
            if (r[0] <= 0 || r[0] % 100 != 0 || r[1] <= 0 || r[1] % 50 != 0 || r[2] < 0) {
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
    function elapsed(tick) {
        return clock.elapsed(pauseClock == null ? tick : pauseClock.origin) - pausedMs;
    }
    function pause(tick) {
        if (pauseClock == null) { pauseClock = new DeadlineEngine(1, 1, tick); }
    }
    function resume(tick) {
        if (pauseClock == null) { return; }
        pausedMs += pauseClock.elapsed(tick);
        pauseClock = null;
    }

    // Keep the effort target unchanged for FIT metadata and reference marks.
    // Recovery starts at the actual button time, whether early or late.
    function lap(tick) {
        if (pauseClock != null || done() || !phase()[0].equals("EFFORT")) { return false; }
        var now = elapsed(tick);
        var p = phase();
        if (now < p[1]) { return false; }
        effortResults.add([p[3], now - p[1]]);
        var shift = now - p[2];
        for (var i = index + 1; i < phases.size(); i += 1) {
            phases[i][1] += shift;
            phases[i][2] += shift;
        }
        totalMs += shift;
        index += 1;
        nextMark = 1;
        lastCountdownSecond = 11;
        return true;
    }

    // Approach cue at 10, then countdown at 4, 3, 2, 1.
    // At 0, use the existing phase-change alert.
    // Delayed callbacks emit only the current cue, never a burst of stale beeps.
    function countdownDue(now) {
        if (done() || !phase()[0].equals("RECOVERY") ||
            index + 1 >= phases.size() || !phases[index + 1][0].equals("EFFORT")) { return false; }
        var left = phase()[2] - now;
        if (left <= 0 || left > 10000) { return false; }
        var second = ((left + 999) / 1000).toNumber();
        if (second > 4 && (second != 10 || phase()[2] - phase()[1] < 10000)) { return false; }
        if (second >= lastCountdownSecond) { return false; }
        lastCountdownSecond = second;
        return true;
    }

    // Return [phase changed, reference mark, recovery countdown]. Efforts wait for LAP.
    function update(tick) {
        if (pauseClock != null) { return [false, false, false]; }
        var now = elapsed(tick);
        var changed = false;
        while (!done() && !phase()[0].equals("EFFORT") && now >= phase()[2]) {
            index += 1;
            nextMark = 1;
            lastCountdownSecond = 11;
            changed = true;
        }
        if (done() || !phase()[0].equals("EFFORT")) { return [changed, false, countdownDue(now)]; }
        var p = phase();
        var due = ((now - p[1]) / p[4]).toNumber();
        var count = ((p[2] - p[1]) / p[4]).toNumber();
        if (due > count) { due = count; }
        if (due < nextMark) { return [changed, false, false]; }
        skipped += due - nextMark;
        nextMark = due + 1;
        return [changed, true, false];
    }
}
