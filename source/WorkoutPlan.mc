// Session settings shared by the editor, persistent profiles and timeline.
class WorkoutPlan {
    var repetitions;
    var cooldownMs = 60000;

    function initialize() {
        repetitions = [[400, 23000, 60000], [400, 22700, 60000], [400, 22400, 60000], [400, 22100, 60000]];
    }
    function copy() {
        var result = new WorkoutPlan();
        result.repetitions = [];
        for (var i = 0; i < repetitions.size(); i += 1) {
            var r = repetitions[i];
            result.repetitions.add([r[0], r[1], r[2]]);
        }
        result.cooldownMs = cooldownMs;
        return result;
    }
    // Values in editor units: count, metres, tenths, recovery seconds, cooldown seconds.
    function value(field) {
        if (field == 0) { return repetitions.size(); }
        if (field == 1) { return repetitions[0][0]; }
        if (field == 2) { return repetitions[0][1] / 100; }
        if (field == 3) { return repetitions[0][2] / 1000; }
        return cooldownMs / 1000;
    }
    function minimum(field) { return field == 0 ? 1 : (field == 1 ? 100 : (field == 2 ? 10 : 0)); }
    function maximum(field) { return field == 0 ? 40 : (field == 1 ? 10000 : (field == 2 ? 1200 : 3600)); }
    function step(field) { return field == 1 ? 100 : (field >= 3 ? 5 : 1); }
    function setValue(field, v) {
        if (field < 0 || field > 4 || v < minimum(field) || v > maximum(field) || v % step(field) != 0) { return false; }
        if (field == 0) {
            var resized = [];
            for (var i = 0; i < v; i += 1) {
                // New repetitions inherit the first repetition's settings.
                var r = repetitions[i < repetitions.size() ? i : 0];
                resized.add([r[0], r[1], r[2]]);
            }
            repetitions = resized;
        } else if (field <= 3) {
            for (var j = 0; j < repetitions.size(); j += 1) {
                repetitions[j][field - 1] = v * (field == 2 ? 100 : (field == 3 ? 1000 : 1));
            }
        } else { cooldownMs = v * 1000; }
        return true;
    }
    function mixed(field) {
        if (field < 1 || field > 3) { return false; }
        // The last recovery is unused by the engine.
        var count = repetitions.size() - (field == 3 ? 1 : 0);
        for (var i = 1; i < count; i += 1) {
            if (repetitions[i][field - 1] != repetitions[0][field - 1]) { return true; }
        }
        return false;
    }
    function repetitionValue(index, field) {
        return repetitions[index][field - 1] / (field == 2 ? 100 : (field == 3 ? 1000 : 1));
    }
    function setRepetitionValue(index, field, v) {
        if (index < 0 || index >= repetitions.size() || field < 1 || field > 3 ||
            v < minimum(field) || v > maximum(field) || v % step(field) != 0) { return false; }
        repetitions[index][field - 1] = v * (field == 2 ? 100 : (field == 3 ? 1000 : 1));
        return true;
    }
    function timeline() { return new WorkoutEngine(repetitions, 0, cooldownMs, 0); }
}

// Integer formatting avoids rounding a countdown up/down through floating point.
class WorkoutText {
    function initialize() {}
    function distance(metres) { return metres == null ? "--" : (metres / 1000.0).format("%.2f"); }
    function realPace(speed) {
        if (speed == null || speed <= 0) { return "--:--"; }
        var seconds = (1000.0 / speed + 0.5).toNumber();
        // Values above 99:59/km cannot fit the live data field.
        if (seconds > 5999) { return "--:--"; }
        return (seconds / 60).toNumber() + ":" + (seconds % 60).format("%02d");
    }
    function elapsedTime(ms) {
        var seconds = (ms / 1000).toNumber();
        return (seconds / 60).toNumber() + ":" + (seconds % 60).format("%02d") + "." + ((ms % 1000) / 100).toNumber();
    }
    function duration(ms) {
        var seconds = ((ms + 999) / 1000).toNumber();
        return (seconds / 60).toNumber() + ":" + (seconds % 60).format("%02d");
    }
    function interval(ms) { return (ms / 1000).toNumber() + "." + ((ms % 1000) / 100).toNumber(); }
    function pace(ms) {
        var seconds = (ms / 100).toNumber();
        return (seconds / 60).toNumber() + ":" + (seconds % 60).format("%02d") + "/km";
    }
}
