import Toybox.Test;
import Toybox.System;

(:test)
class ConfirmationTimer {
    var stops = 0;
    var callback;
    var delay;
    var repeating;
    function initialize() {}
    function start(cb, ms, repeat) { callback = cb; delay = ms; repeating = repeat; }
    function stop() { stops += 1; }
}

(:test)
class ConfirmationRecording extends FakeWorkoutRecording {
    function initialize(f) { FakeWorkoutRecording.initialize(f); }
    function prepare() {}
    function release() {}
}

(:test)
class ConfirmationController extends WorkoutController {
    function initialize(f) {
        plan = new WorkoutPlan();
        repetitions = plan.repetitions;
        timer = new ConfirmationTimer();
        recording = new ConfirmationRecording(f);
        engine = new WorkoutEngine([[100,1000,0]],1000,0,System.getTimer());
        recording.start(engine.phases);
        running = true;
    }
}

(:test)
function lapButtonClosesOnlyEffort(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    w.engine = new WorkoutEngine([[400,23000,60000],[400,23000,0]],0,1000,System.getTimer() - 95000);
    f.fields = [];
    w.recording.metadata = new WorkoutFitMetadata(f, w.engine.phases);
    var delegate = new WorkoutDelegate(w);
    delegate.onBack();
    Test.assert(w.running && w.engine.phase()[0].equals("RECOVERY"));
    Test.assert(f.laps == 1 && f.stops == 0 && f.saves == 0);
    Test.assert(w.engine.effortResults[0][1] >= 95000);
    delegate.onBack();
    Test.assert(w.engine.index == 1 && f.laps == 1);
    // Without cool-down the final LAP stops recording and asks to save.
    f = new FakeWorkoutSession();
    w = new ConfirmationController(f);
    w.engine = new WorkoutEngine([[100,1000,0]],0,0,System.getTimer() - 3500);
    f.fields = [];
    w.recording.metadata = new WorkoutFitMetadata(f, w.engine.phases);
    delegate = new WorkoutDelegate(w);
    delegate.onBack();
    Test.assert(!w.running && w.engine.done() && w.confirmSave);
    Test.assert(f.stops == 1 && f.saves == 0 && f.laps == 0);
    Test.assert(w.finishedMs >= 3500 && f.fields[0].value.equals("Effort 1"));
    Test.assert(w.recording.metadata.outcome.equals("COMPLETE"));
    return true;
}

(:test)
function confirmBeforeSavingActivity(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    var delegate = new WorkoutDelegate(w);
    delegate.onBack();
    Test.assert(w.running && f.stops == 0 && f.saves == 0);
    delegate.onSelect();
    Test.assert(!w.running && w.confirmSave && w.recording.pending());
    Test.assert(f.stops == 1 && f.saves == 0 && !f.active);
    Test.assert(w.paused && w.endChoice == 2 && w.recording.state.equals("FIT PAUSED"));
    var frozen = w.finishedMs;
    delegate.onBack();
    Test.assert(!w.confirmSave && f.saves == 0);
    delegate.onBack();
    Test.assert(f.saves == 0 && w.recording.pending());
    delegate.onSelect(); // Reopen confirmation; does not save.
    Test.assert(w.confirmSave && f.saves == 0);
    delegate.onNextPage(); // Select Save after reopening the pause menu.
    delegate.onSelect(); // Explicit confirmation.
    Test.assert(f.saves == 1 && !w.recording.pending() && !w.confirmSave);
    Test.assert(f.stops == 1 && w.finishedMs == frozen);
    Test.assert(f.capturedResult.equals("CANCELLED"));
    return true;
}

(:test)
function completeAndRetryRequireSaveConfirmation(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    w.recording.completed(w.engine.phases.size());
    w.finish("COMPLETE");
    Test.assert(w.confirmSave && f.saves == 0 && !f.active);
    f.saveOk = false;
    w.start();
    Test.assert(w.confirmSave && w.recording.pending() && f.saves == 1);
    Test.assert(w.recording.state.equals("FIT SAVE ERROR"));
    var delegate = new WorkoutDelegate(w);
    delegate.onBack();
    Test.assert(!w.confirmSave && f.saves == 1);
    w.start();
    Test.assert(w.confirmSave && f.saves == 1);
    f.saveOk = true;
    w.start();
    Test.assert(!w.recording.pending() && f.saves == 2 && f.stops == 1);
    Test.assert(f.capturedResult.equals("COMPLETE"));
    return true;
}

(:test)
function shutdownDoesNotSaveWithoutConsent(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    w.shutdown();
    Test.assert(!w.running && !f.active && f.stops == 1 && f.saves == 0);
    Test.assert(w.recording.pending());
    f = new FakeWorkoutSession();
    w = new ConfirmationController(f);
    f.stopOk = false;
    w.finish("CANCELLED");
    Test.assert(w.recording.state.equals("FIT STOP ERROR") && f.saves == 0);
    f.stopOk = true;
    w.start();
    Test.assert(!w.recording.pending() && f.stops == 2 && f.saves == 1);
    Test.assert(f.capturedResult.equals("CANCELLED"));
    return true;
}

(:test)
function discardRequiresExplicitStartConfirmation(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    var delegate = new WorkoutDelegate(w);
    delegate.onPreviousPage();
    delegate.onNextPage();
    Test.assert(w.running && f.stops == 0);
    delegate.onSelect();
    Test.assert(!w.running && w.paused && w.endChoice == 2 && w.confirmSave);
    delegate.onPreviousPage();
    Test.assert(w.endChoice == 1);
    delegate.onSelect();
    Test.assert(w.confirmDiscard && f.discards == 0 && f.saves == 0);
    delegate.onPreviousPage();
    Test.assert(w.endChoice == 1 && w.confirmDiscard);
    delegate.onBack();
    Test.assert(!w.confirmDiscard && w.confirmSave && f.discards == 0);
    delegate.onPreviousPage();
    Test.assert(w.endChoice == 0);
    delegate.onPreviousPage();
    Test.assert(w.endChoice == 2); // Resume is between Save and Discard when wrapping.
    delegate.onPreviousPage();
    Test.assert(w.endChoice == 1);
    delegate.onSelect();
    delegate.onSelect();
    Test.assert(f.discards == 1 && f.saves == 0 && f.stops == 1);
    Test.assert(!w.confirmSave && !w.confirmDiscard && !w.recording.pending());
    Test.assert(w.recording.state.equals("FIT DISCARDED"));
    Test.assert(w.plan.repetitions.size() == 4);
    return true;
}

(:test)
function discardFailurePreservesPendingActivity(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    w.start();
    w.chooseEnd(-1);
    w.start();
    f.discardOk = false;
    w.start();
    Test.assert(w.recording.pending() && w.confirmDiscard && f.discards == 1);
    Test.assert(!w.showingDiscarded && !w.running);
    Test.assert(w.recording.state.equals("FIT DISCARD ERROR") && f.saves == 0);
    f.discardOk = true;
    f.throwDiscard = true;
    w.start();
    Test.assert(w.recording.pending() && f.discards == 2);
    f.throwDiscard = false;
    var delegate = new WorkoutDelegate(w);
    delegate.onBack();
    delegate.onPreviousPage();
    delegate.onSelect(); // Can choose to save after an unsuccessful discard.
    Test.assert(!w.recording.pending() && f.saves == 1 && f.discards == 2);
    Test.assert(f.capturedResult.equals("CANCELLED"));
    return true;
}

(:test)
function discardedNoticeReturnsHome(logger) {
    var f = new FakeWorkoutSession();
    var w = new ConfirmationController(f);
    var originalPlan = w.plan;
    var delegate = new WorkoutDelegate(w);
    w.start();
    w.chooseEnd(-1);
    w.start();
    w.start();
    Test.assert(w.showingDiscarded && !w.recording.pending());
    Test.assert(w.timer.delay == 3000 && !w.timer.repeating);
    delegate.onSelect();
    delegate.onPreviousPage();
    delegate.onNextPage();
    delegate.onMenu();
    delegate.onBack();
    Test.assert(w.showingDiscarded && !w.running && f.discards == 1);
    w.timer.callback.invoke();
    Test.assert(!w.showingDiscarded && w.engine == null && w.finishedMs == 0);
    Test.assert(w.status.equals("READY") && w.endChoice == 0);
    Test.assert(w.plan == originalPlan && !w.confirmSave && !w.confirmDiscard);
    return true;
}

(:test)
function discardStopFailureAndRestartGuard(logger) {
    var f = new FakeWorkoutSession();
    var r = new FakeWorkoutRecording(f);
    Test.assert(r.start(null));
    f.stopOk = false;
    Test.assert(!r.discard() && r.pending() && f.discards == 0 && f.saves == 0);
    f.stopOk = true;
    Test.assert(r.discard() && !r.pending() && f.discards == 1);
    Test.assert(r.discard() && f.discards == 1);
    // Use the real restart guard after a discard.
    var guarded = new WorkoutRecording();
    guarded.saveClock = r.saveClock;
    Test.assert(!guarded.canStart(guarded.saveClock.origin));
    Test.assert(guarded.canStart(guarded.saveClock.origin + 1000));
    return true;
}
