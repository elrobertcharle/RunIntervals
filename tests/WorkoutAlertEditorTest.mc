import Toybox.Test;

(:test)
function alertEditorEditsPartsAndBacktracks(logger) {
    var w = new EditorTestWorkout();
    var e = new WorkoutEditor(w);
    var delegate = new WorkoutEditorDelegate(e);
    e.field = 2;
    delegate.onSelect();
    Test.assert(e.editing && e.intervalPart == 0 && e.candidate == 23000);
    delegate.onPreviousPage();
    Test.assert(e.candidate == 24000);
    delegate.onSelect();
    Test.assert(e.editing && e.intervalPart == 1 && e.draft.repetitions[0][1] == 23000);
    delegate.onPreviousPage();
    Test.assert(e.candidate == 24050);
    delegate.onBack();
    Test.assert(e.editing && e.intervalPart == 0 && e.candidate == 24050);
    delegate.onNextPage();
    Test.assert(e.candidate == 23050);
    delegate.onSelect();
    delegate.onSelect();
    Test.assert(!e.editing && e.draft.repetitions[0][1] == 23050);
    Test.assert(e.draft.repetitions[3][1] == 23050 && w.plan.repetitions[0][1] == 23000);
    delegate.onSelect();
    Test.assert(e.intervalPart == 0);
    delegate.onSelect();
    delegate.onPreviousPage();
    delegate.onBack();
    delegate.onBack();
    Test.assert(!e.editing && e.draft.repetitions[0][1] == 23050);
    return true;
}

(:test)
function alertEditorWrapsHundredthsAndHonorsBounds(logger) {
    var e = new WorkoutEditor(new EditorTestWorkout());
    e.field = 2;
    e.select();
    e.select();
    e.move(-1);
    Test.assert(e.candidate == 23950); // Hundredths wrap without changing seconds.
    e.move(1);
    Test.assert(e.candidate == 23000);
    e.back();
    e.candidate = 1000;
    e.move(-1);
    Test.assert(e.candidate == 1000);
    e.candidate = 119950;
    e.move(1);
    Test.assert(e.candidate == 120000);
    e.select();
    e.move(1);
    Test.assert(e.candidate == 120000);
    e.move(-1);
    Test.assert(e.candidate == 120000);
    return true;
}

(:test)
function individualAlertsKeepHundredthsThroughProfilesAndTiming(logger) {
    var w = new ProfileTestWorkout();
    var e = new WorkoutEditor(w);
    e.field = 6;
    e.select();
    e.repIndex = 1;
    e.field = 2;
    e.select();
    e.select();
    e.move(1);
    e.select();
    Test.assert(e.draft.repetitions[1][1] == 22750 && e.draft.repetitions[0][1] == 23000);
    Test.assert(w.profiles.save("hundredths", e.draft));
    var p = w.profiles.load("hundredths");
    Test.assert(p != null && p.repetitions[1][1] == 22750);
    Test.assert(p.setValue(2, 23050));
    Test.assert(!p.setValue(2, 23010) && !p.setRepetitionValue(0, 2, 23025));
    var engine = p.timeline();
    Test.assert(!engine.update(23049)[1] && engine.update(23050)[1]);
    Test.assert(!engine.update(46099)[1] && engine.update(46100)[1]);
    Test.assert(w.profiles.decode([1,0,0,[[100,23025,0]]]) == null);
    var text = new WorkoutText();
    Test.assert(text.interval(23050).equals("23.05"));
    Test.assert(text.interval(23950).equals("23.95"));
    Test.assert(text.interval(24000).equals("24.00"));
    Test.assert(text.interval(120000).equals("120.00"));
    return true;
}
