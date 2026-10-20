// No hardware calls: the same engine is exercised by SDK unit tests.
class DeadlineEngine {
    var intervalMs;
    var count;
    var nextIndex = 1;
    var origin;

    function initialize(interval, total, startTick) {
        intervalMs = interval;
        count = total;
        origin = startTick;
    }

    // Promote BEFORE subtraction to handle signed 32-bit timer rollover.
    // Valid for runs shorter than one full timer cycle (~49.7 days).
    function elapsed(tick) {
        var delta = tick.toLong() - origin.toLong();
        if (delta < 0) { delta += 4294967296l; }
        return delta;
    }

    function target(index) { return index * intervalMs; }
    function done() { return nextIndex > count; }

    // Returns [first due, last due]. Controller skips stale marks, never bursts.
    function due(tick) {
        if (done() || elapsed(tick) < target(nextIndex)) { return null; }
        var first = nextIndex;
        var last = (elapsed(tick) / intervalMs).toNumber();
        if (last > count) { last = count; }
        nextIndex = last + 1;
        return [first, last];
    }
}
