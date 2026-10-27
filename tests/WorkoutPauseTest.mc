import Toybox.Test;
import Toybox.System;

(:test)
function pauseFreezesEffortAndReferenceMarks(logger) {
    var e = new WorkoutEngine([[400,1000,2000],[100,1000,0]],0,3000,0);
    Test.assert(e.update(1000)[1]);
    e.pause(1500);
    e.pause(2000); // Repeated pause requests do not move the frozen time.
    Test.assert(e.elapsed(50000) == 1500 && !e.update(50000)[1]);
    Test.assert(!e.lap(50000) && e.index == 0 && e.nextMark == 2);
    e.resume(51500);
    Test.assert(e.elapsed(51500) == 1500 && !e.update(51999)[1]);
    Test.assert(e.update(52000)[1] && e.skipped == 0);
    e.pause(52500);
    e.resume(62500);
    Test.assert(e.elapsed(62500) == 2500);
    Test.assert(e.lap(63000) && e.effortResults[0][1] == 3000);
    Test.assert(e.phase()[1] == 3000 && e.phase()[2] == 5000);
    return true;
}

(:test)
function pauseFreezesRecoveryCooldownAndTimerRollover(logger) {
    var e = new WorkoutEngine([[100,1000,2000],[100,1000,0]],0,3000,0);
    Test.assert(e.lap(1000));
    e.pause(1500);
    Test.assert(!e.update(100000)[0] && e.index == 1);
    e.resume(11500);
    Test.assert(!e.update(12999)[0]);
    Test.assert(e.update(13000)[0] && e.index == 2);
    Test.assert(e.lap(14000));
    e.pause(15000);
    Test.assert(!e.update(200000)[0] && !e.done());
    e.resume(25000);
    Test.assert(!e.update(26999)[0]);
    Test.assert(e.update(27000)[0] && e.done());

    e = new WorkoutEngine([[100,1000,0]],0,0,2147483000);
    e.pause(2147483500);
    Test.assert(e.elapsed(-2147483000) == 500);
    e.resume(-2147482796); // A 1000 ms pause across the signed timer boundary.
    Test.assert(e.elapsed(-2147482796) == 500);
    Test.assert(e.elapsed(-2147482296) == 1000 && e.update(-2147482296)[1]);
    return true;
}

(:test)
function resumeKeepsSessionPhaseAndLap(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    w.engine = new WorkoutEngine([[400,1000,2000],[100,1000,0]],0,0,System.getTimer());
    var originalSession = w.recording.session;
    var originalMetadata = w.recording.metadata;
    var delegate = new WorkoutDelegate(w);
    delegate.onSelect();
    Test.assert(w.paused && !w.running && w.confirmSave && w.endChoice == 2);
    var frozen = w.finishedMs;
    w.onTick();
    w.lap();
    Test.assert(w.engine.index == 0 && w.engine.elapsed(System.getTimer()) == frozen);
    Test.assert(f.stops == 1 && f.laps == 0 && f.saves == 0 && !f.active);
    Test.assert(w.recording.metadata.outcome.equals("INTERRUPTED"));
    delegate.onSelect();
    Test.assert(w.running && !w.paused && !w.confirmSave && f.active);
    Test.assert(w.recording.session == originalSession && w.recording.metadata == originalMetadata);
    Test.assert(f.starts == 2 && f.laps == 0 && w.engine.index == 0);
    delegate.onSelect();
    delegate.onNextPage(); // Save after a second pause.
    delegate.onSelect();
    Test.assert(f.starts == 2 && f.stops == 2 && f.saves == 1 && !w.paused);
    Test.assert(f.capturedResult.equals("CANCELLED"));
    return true;
}

(:test)
function pauseAndResumeFailuresCanBeRetried(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    f.stopOk = false;
    w.start();
    Test.assert(w.running && !w.paused && f.active && w.engine.pauseClock == null);
    f.stopOk = true;
    w.start();
    var frozen = w.finishedMs;
    f.startOk = false;
    w.start();
    Test.assert(w.paused && !w.running && w.confirmSave && !f.active);
    Test.assert(w.engine.elapsed(System.getTimer()) == frozen);
    Test.assert(w.recording.state.equals("FIT RESUME ERROR"));
    f.startOk = true;
    w.start();
    Test.assert(w.running && !w.paused && f.active && f.saves == 0 && f.laps == 0);
    w.shutdown();
    return true;
}
