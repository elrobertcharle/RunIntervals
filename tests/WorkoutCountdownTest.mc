import Toybox.Test;
import Toybox.Attention;

(:test)
function recoveryCountdownHasFourTicksAndDistinctStart(logger) {
    var e = new WorkoutEngine([[100,1000,10000],[100,1000,0]],0,1000,0);
    Test.assert(e.lap(1500)); // Recovery is based on actual LAP time.
    Test.assert(!e.update(7499)[2]);
    for (var tick = 7500; tick <= 10500; tick += 1000) {
        var event = e.update(tick);
        Test.assert(event[2] && !event[0] && !event[1]);
        Test.assert(!e.update(tick)[2] && !e.update(tick + 50)[2]);
    }
    var start = e.update(11500);
    Test.assert(start[0] && !start[1] && !start[2] && e.phase()[0].equals("EFFORT"));
    Test.assert(!e.update(11550)[0] && !e.update(11550)[2]);
    Test.assert(e.update(12500)[1]); // Reference marks continue independently.
    return true;
}

(:test)
function recoveryCountdownSkipsStaleCuesAndRespectsPause(logger) {
    var e = new WorkoutEngine([[100,1000,10000],[100,1000,0]],0,0,0);
    Test.assert(e.lap(1000));
    Test.assert(e.update(7000)[2]);
    e.pause(7500);
    Test.assert(!e.update(100000)[2] && e.index == 1);
    e.resume(17500);
    Test.assert(!e.update(17500)[2]);
    Test.assert(e.update(18000)[2]);
    Test.assert(e.update(20500)[2]); // Late: only the last countdown second.
    Test.assert(!e.update(20500)[2]);
    var event = e.update(21000);
    Test.assert(event[0] && !event[2] && e.index == 2);
    return true;
}

(:test)
function countdownIgnoresEffortCooldownAndMissingRecovery(logger) {
    var e = new WorkoutEngine([[100,1000,0],[100,1000,0]],0,5000,0);
    Test.assert(!e.update(500)[2]);
    Test.assert(e.lap(1000) && e.phase()[0].equals("EFFORT"));
    Test.assert(!e.update(1500)[2]);
    Test.assert(e.lap(2000) && e.phase()[0].equals("COOL-DOWN"));
    for (var tick = 3000; tick <= 7000; tick += 1000) { Test.assert(!e.update(tick)[2]); }
    Test.assert(e.done());
    // Short recoveries emit only the cues for the seconds available.
    e = new WorkoutEngine([[100,1000,2000],[100,1000,0]],0,0,0);
    Test.assert(e.lap(1000));
    Test.assert(e.update(1050)[2] && !e.update(1100)[2]);
    Test.assert(e.update(2000)[2] && e.update(3000)[0]);
    return true;
}

(:test)
class CountdownController extends ConfirmationController {
    var tones = [];
    function initialize(f) { ConfirmationController.initialize(f); }
    function playTone(tone) { tones.add(tone); }
}

(:test)
function controllerPlaysFiveCountdownCuesWithoutExtraLaps(logger) {
    var f = new FakeWorkoutSession();
    var w = new CountdownController(f);
    w.engine = new WorkoutEngine([[100,1000,10000],[100,1000,0]],0,0,0);
    w.engine.lap(1000);
    w.recording.phaseChanged(w.engine.index);
    for (var tick = 7000; tick <= 10000; tick += 1000) {
        w.handleEvent(w.engine.update(tick), tick);
    }
    Test.assert(w.tones.size() == 4 && f.laps == 1);
    w.handleEvent(w.engine.update(11000), 11000);
    Test.assert(w.tones.size() == 5 && f.laps == 2 && f.starts == 1 && f.stops == 0);
    for (var i = 0; i < 4; i += 1) { Test.assert(w.tones[i] == Attention.TONE_LOUD_BEEP); }
    Test.assert(w.tones[4] == Attention.TONE_INTERVAL_ALERT);
    w.handleEvent(w.engine.update(11050), 11050);
    Test.assert(w.tones.size() == 5 && f.laps == 2);
    return true;
}
