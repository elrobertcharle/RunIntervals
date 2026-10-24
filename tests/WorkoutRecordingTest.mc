import Toybox.Test;

(:test)
class FakeWorkoutSession {
    var active = false;
    var starts = 0;
    var stops = 0;
    var saves = 0;
    var laps = 0;
    var startOk = true;
    var stopOk = true;
    var saveOk = true;
    var lapOk = true;
    var throwSave = false;
    var discards = 0;
    var discardOk = true;
    var throwDiscard = false;
    var fields = [];
    var capturedLaps = [];
    var capturedResult;
    function initialize() {}
    function start() { starts += 1; active = startOk; return startOk; }
    function isRecording() { return active; }
    function stop() { stops += 1; if (stopOk) { active = false; } return stopOk; }
    function save() {
        saves += 1;
        if (fields.size() > 0) { capturedResult = fields[5].value; }
        if (throwSave) { throw new Toybox.Lang.InvalidValueException("save"); }
        return saveOk;
    }
    function discard() {
        discards += 1;
        if (throwDiscard) { throw new Toybox.Lang.InvalidValueException("discard"); }
        return discardOk;
    }
    function createField(name, id, type, options) {
        var field = new FakeWorkoutField();
        fields.add(field);
        return field;
    }
    function addLap() {
        laps += 1;
        if (fields.size() > 0 && lapOk) {
            capturedLaps.add([fields[0].value, fields[1].value, fields[2].value, fields[3].value, fields[4].value]);
        }
        return lapOk;
    }
}

(:test)
class FakeWorkoutField {
    var value;
    function initialize() {}
    function setData(v) { value = v; }
}

(:test)
class FakeWorkoutRecording extends WorkoutRecording {
    var fake;
    function initialize(f) { WorkoutRecording.initialize(); fake = f; }
    function createSession() { return fake; }
    function canStart(tick) { return true; } // tests advance logical sessions immediately
}

(:test)
function recordingFullWorkout(logger) {
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    var e = new WorkoutEngine([[400,23000,60000],[400,22700,60000],[400,22400,60000],[400,22100,0]],60000,60000,0);
    Test.assert(r.start(e.phases));
    Test.assert(!r.start(null));
    Test.assert(e.phases.size() == 9 && e.totalMs == 660800);
    for (var i = 1; i < e.phases.size(); i += 1) {
        Test.assert(e.update(e.phases[i][1].toNumber())[0]);
        r.phaseChanged(e.index);
        r.phaseChanged(e.index); // no duplicate laps on repeated callbacks
    }
    Test.assert(e.update(660800)[0] && e.done());
    r.completed(e.index);
    // stop/save closes the final phase; no extra zero-length lap.
    Test.assert(r.finish("COMPLETE") && r.finish(null));
    Test.assert(f.starts == 1 && f.stops == 1 && f.saves == 1 && f.laps == 8);
    Test.assert(!r.pending() && r.state.equals("FIT SAVED"));
    Test.assert(r.lapErrors == 0 && r.missedBoundaries == 0);
    Test.assert(f.fields.size() == 8 && f.capturedLaps.size() == 8);
    Test.assert(f.capturedLaps[0][0].equals("Warm-up") && f.capturedLaps[0][1] == 1);
    Test.assert(f.capturedLaps[1][0].equals("Effort 1") && f.capturedLaps[1][2] == 1);
    Test.assert(f.capturedLaps[1][3] == 92.0 && f.capturedLaps[1][4] == 23.0);
    Test.assert(f.capturedLaps[2][0].equals("Recovery") && f.capturedLaps[2][2] == 0 && f.capturedLaps[2][4] == 0);
    Test.assert(f.fields[0].value.equals("Cool-down") && f.fields[1].value == 4);
    Test.assert(f.fields[3].value == 60.0 && f.capturedResult.equals("COMPLETE"));
    return true;
}

(:test)
function recordingSaveAndStopRetry(logger) {
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    Test.assert(r.start(null));
    f.stopOk = false;
    Test.assert(!r.finish(null) && r.pending() && f.saves == 0);
    f.stopOk = true;
    f.saveOk = false;
    Test.assert(!r.finish(null) && r.pending());
    Test.assert(!r.start(null) && f.starts == 1);
    f.saveOk = true;
    Test.assert(r.finish(null));
    Test.assert(f.stops == 2 && f.saves == 2);
    Test.assert(r.start(null));
    f.throwSave = true;
    Test.assert(!r.finish(null) && r.pending());
    f.throwSave = false;
    Test.assert(r.finish(null));
    return true;
}

(:test)
function recordingSkippedLapsAndCancellation(logger) {
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    Test.assert(r.start(null));
    r.phaseChanged(3);
    Test.assert(f.laps == 1 && r.missedBoundaries == 2);
    f.lapOk = false;
    r.phaseChanged(4);
    Test.assert(r.lapErrors == 1 && f.laps == 2);
    Test.assert(r.finish(null)); // cancellation keeps the partial recording
    Test.assert(r.start(null));
    Test.assert(r.lapErrors == 0 && r.missedBoundaries == 0 && r.phaseIndex == 0);
    r.completed(9);
    Test.assert(r.missedBoundaries == 8 && f.laps == 2);
    Test.assert(r.finish(null));
    f.startOk = false;
    Test.assert(!r.start(null));
    Test.assert(r.finish(null));
    return true;
}

(:test)
function recordingMetadataMixedAndRetry(logger) {
    var e = new WorkoutEngine([[400,23000,60000],[400,22700,0]],60000,60000,0);
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    Test.assert(r.start(e.phases));
    r.phaseChanged(2); // a missed boundary makes this native lap span two phases
    Test.assert(f.capturedLaps[0][0].equals("Mixed phases"));
    Test.assert(f.capturedLaps[0][1] == 0 && f.capturedLaps[0][3] == 0);
    f.lapOk = false;
    r.phaseChanged(3);
    f.lapOk = true;
    r.phaseChanged(4);
    Test.assert(f.capturedLaps[1][0].equals("Mixed phases"));
    f.saveOk = false;
    Test.assert(!r.finish("CANCELLED"));
    Test.assert(f.fields[0].value.equals("Cool-down"));
    Test.assert(f.fields[6].value == 1 && f.fields[7].value == 1);
    f.saveOk = true;
    Test.assert(r.finish(null) && f.capturedResult.equals("CANCELLED"));
    return true;
}

(:test)
function recordingMetadataLateFinish(logger) {
    var e = new WorkoutEngine([[400,23000,0]],60000,60000,0);
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    Test.assert(r.start(e.phases));
    r.completed(e.phases.size());
    Test.assert(r.finish("COMPLETE"));
    Test.assert(f.fields[0].value.equals("Mixed phases"));
    Test.assert(f.fields[7].value == 2);
    // A fresh recording resets both phase metadata and result.
    f = new FakeWorkoutSession();
    r.fake = f;
    Test.assert(r.start(e.phases));
    Test.assert(f.fields[0].value.equals("Warm-up"));
    Test.assert(f.fields[5].value.equals("INTERRUPTED"));
    Test.assert(r.finish("APP STOP"));
    return true;
}

(:test)
function recordingRestartCooldown(logger) {
    var r = new WorkoutRecording();
    Test.assert(r.canStart(0));
    r.saveClock = new DeadlineEngine(1,1,2147483640);
    Test.assert(!r.canStart(2147483640));
    Test.assert(!r.canStart(-2147482657)); // 999 ms across signed rollover
    Test.assert(r.canStart(-2147482656));
    return true;
}
