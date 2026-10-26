import Toybox.Test;

(:test)
function editorGoesFromRecoveryToCooldown(logger) {
    var editor = new WorkoutEditor(new EditorTestWorkout());
    editor.field = 3;
    editor.move(1);
    Test.assert(editor.labels[editor.field].equals("Cool-down"));
    editor.select();
    editor.move(1);
    editor.select();
    Test.assert(editor.draft.cooldownMs == 65000);
    Test.assert(editor.draft.timeline().phase()[0].equals("EFFORT"));
    editor.move(1);
    Test.assert(editor.labels[editor.field].equals("Apply session"));
    return true;
}

(:test)
function editedPlanTimeline(logger) {
    var original = new WorkoutPlan();
    var p = original.copy();
    Test.assert(p.mixed(2) && !p.mixed(3));
    Test.assert(p.setValue(0, 2));
    Test.assert(p.setValue(1, 800));
    Test.assert(p.setValue(2, 225));
    Test.assert(p.setValue(3, 30));
    Test.assert(p.setValue(4, 10));
    var e = p.timeline();
    Test.assert(e.totalMs == 400000);
    Test.assert(e.phases.size() == 4);
    Test.assert(e.phase()[0].equals("EFFORT"));
    Test.assert(e.update(22500)[1]);
    Test.assert(e.lap(180000));
    Test.assert(e.phase()[0].equals("RECOVERY"));
    Test.assert(e.update(210000)[0] && e.phase()[3] == 1);
    Test.assert(e.lap(390000) && e.phase()[0].equals("COOL-DOWN"));
    Test.assert(e.update(400000)[0] && e.done());
    Test.assert(original.repetitions.size() == 4 && original.repetitions[0][0] == 400);
    Test.assert(original.repetitions[1][1] == 22700 && original.cooldownMs == 60000);
    Test.assert(!p.mixed(2));
    return true;
}

(:test)
function planBoundsAndCopies(logger) {
    var p = new WorkoutPlan();
    Test.assert(!p.setValue(0, 0) && !p.setValue(0, 41));
    Test.assert(!p.setValue(1, 350) && !p.setValue(2, 0));
    Test.assert(!p.setValue(3, -5) && !p.setValue(4, 3605));
    Test.assert(!p.setValue(4, 11) && !p.setValue(5, 0));
    Test.assert(p.setValue(0, 5));
    Test.assert(p.repetitions[3][2] == 60000);
    p.repetitions[4][0] = 800;
    Test.assert(p.repetitions[0][0] == 400);
    for (var i = 0; i < 5; i += 1) { Test.assert(p.setValue(i, p.maximum(i))); }
    Test.assert(p.timeline().totalMs == 624000000);
    for (var j = 0; j < 5; j += 1) { Test.assert(p.setValue(j, p.minimum(j))); }
    Test.assert(p.timeline().totalMs == 1000 && p.timeline().phases.size() == 1);
    var text = new WorkoutText();
    Test.assert(text.pace(22100).equals("3:41/km"));
    Test.assert(text.interval(22500).equals("22.5"));
    Test.assert(text.duration(60001).equals("1:01"));
    return true;
}

(:test)
function editorDraftIsolation(logger) {
    // Exercise the real editor without starting GPS or a native FIT session.
    var w = new EditorTestWorkout();
    var editor = new WorkoutEditor(w);
    editor.field = 2;
    editor.select();
    editor.move(-1);
    editor.back();
    Test.assert(editor.draft.repetitions[0][1] == 23000);
    editor.select();
    editor.move(-1);
    editor.select();
    Test.assert(editor.draft.repetitions[0][1] == 22900);
    Test.assert(w.plan.repetitions[0][1] == 23000);
    editor.field = 6;
    editor.select();
    Test.assert(editor.draft.mixed(2));
    editor.field = 2;
    editor.select();
    var delegate = new WorkoutEditorDelegate(editor);
    delegate.onPreviousPage(); // UP increases the edited value.
    Test.assert(editor.candidate == 231);
    delegate.onNextPage();
    Test.assert(editor.candidate == 230);
    return true;
}

(:test)
class EditorTestWorkout {
    var plan;
    function initialize() { plan = new WorkoutPlan(); }
}
