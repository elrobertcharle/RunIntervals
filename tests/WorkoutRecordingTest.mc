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
    function initialize() {}
    function start() { starts += 1; active = startOk; return startOk; }
    function isRecording() { return active; }
    function stop() { stops += 1; if (stopOk) { active = false; } return stopOk; }
    function save() {
        saves += 1;
        if (throwSave) { throw new Toybox.Lang.InvalidValueException("save"); }
        return saveOk;
    }
    function addLap() { laps += 1; return lapOk; }
}

(:test)
class FakeWorkoutRecording extends WorkoutRecording {
    var fake;
    function initialize(f) { WorkoutRecording.initialize(); fake = f; }
    function createSession() { return fake; }
}

(:test)
function recordingFullWorkout(logger) {
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    var e = new WorkoutEngine([[400,23000,60000],[400,22700,60000],[400,22400,60000],[400,22100,0]],60000,60000,0);
    Test.assert(r.start());
    Test.assert(!r.start());
    Test.assert(e.phases.size() == 9 && e.totalMs == 660800);
    for (var i = 1; i < e.phases.size(); i += 1) {
        Test.assert(e.update(e.phases[i][1].toNumber())[0]);
        r.phaseChanged(e.index);
        r.phaseChanged(e.index); // no duplicate laps on repeated callbacks
    }
    Test.assert(e.update(660800)[0] && e.done());
    r.completed(e.index);
    // stop/save closes the final phase; no extra zero-length lap.
    Test.assert(r.finish() && r.finish());
    Test.assert(f.starts == 1 && f.stops == 1 && f.saves == 1 && f.laps == 8);
    Test.assert(!r.pending() && r.state.equals("FIT SAVED"));
    Test.assert(r.lapErrors == 0 && r.missedBoundaries == 0);
    return true;
}

(:test)
function recordingSaveAndStopRetry(logger) {
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    Test.assert(r.start());
    f.stopOk = false;
    Test.assert(!r.finish() && r.pending() && f.saves == 0);
    f.stopOk = true;
    f.saveOk = false;
    Test.assert(!r.finish() && r.pending());
    Test.assert(!r.start() && f.starts == 1);
    f.saveOk = true;
    Test.assert(r.finish());
    Test.assert(f.stops == 2 && f.saves == 2);
    Test.assert(r.start());
    f.throwSave = true;
    Test.assert(!r.finish() && r.pending());
    f.throwSave = false;
    Test.assert(r.finish());
    return true;
}

(:test)
function recordingSkippedLapsAndCancellation(logger) {
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    Test.assert(r.start());
    r.phaseChanged(3);
    Test.assert(f.laps == 1 && r.missedBoundaries == 2);
    f.lapOk = false;
    r.phaseChanged(4);
    Test.assert(r.lapErrors == 1 && f.laps == 2);
    Test.assert(r.finish()); // cancellation keeps the partial recording
    Test.assert(r.start());
    Test.assert(r.lapErrors == 0 && r.missedBoundaries == 0 && r.phaseIndex == 0);
    r.completed(9);
    Test.assert(r.missedBoundaries == 8 && f.laps == 2);
    Test.assert(r.finish());
    f.startOk = false;
    Test.assert(!r.start());
    Test.assert(r.finish());
    return true;
}
