import Toybox.Test;

(:test)
function individualRepetitionTimeline(logger) {
    var p = new WorkoutPlan();
    p.setValue(0, 2);
    p.setValue(4, 0);
    p.setValue(5, 0);
    Test.assert(p.setRepetitionValue(0, 1, 200));
    Test.assert(p.setRepetitionValue(0, 2, 225));
    Test.assert(p.setRepetitionValue(0, 3, 10));
    Test.assert(p.setRepetitionValue(1, 1, 400));
    Test.assert(p.setRepetitionValue(1, 2, 221));
    Test.assert(!p.setRepetitionValue(2, 2, 230));
    Test.assert(!p.setRepetitionValue(0, 2, 9));
    Test.assert(!p.setRepetitionValue(0, 1, 350));
    Test.assert(!p.setRepetitionValue(0, 3, 11));
    var e = p.timeline();
    Test.assert(e.totalMs == 143400);
    Test.assert(e.update(22500)[1]);
    e.update(45000);
    Test.assert(e.phase()[0].equals("RECOVERY"));
    e.update(55000);
    Test.assert(e.phase()[3] == 1 && e.phase()[4] == 22100);
    Test.assert(e.update(77100)[1]);
    e.update(143400);
    Test.assert(e.done());
    return true;
}

(:test)
function profilesValidationAndIsolation(logger) {
    var store = new WorkoutProfiles();
    var p = new WorkoutPlan();
    var data = store.encode(p);
    var loaded = store.decode(data);
    Test.assert(loaded != null && loaded.mixed(2));
    loaded.repetitions[0][1] = 22000;
    Test.assert(p.repetitions[0][1] == 23000 && data[3][0][1] == 23000);
    Test.assert(store.decode(null) == null);
    Test.assert(store.decode([2, 60000, 60000, p.repetitions]) == null);
    Test.assert(store.decode([1, "bad", 60000, p.repetitions]) == null);
    Test.assert(store.decode([1, 0, 0, []]) == null);
    Test.assert(store.decode([1, 0, 0, [[400, 23001, 0]]]) == null);
    Test.assert(store.decode([1, 0, 0, [[400, 23000, -5]]]) == null);
    Test.assert(store.decode([1, 0, 0, [[400, 23000]]]) == null);
    Test.assert(store.decode([1, 0, 0, [null]]) == null);
    Test.assert(store.decode([1, 0, 0, [[400.0, 23000, 0]]]) == null);
    for (var f = 0; f < 6; f += 1) { p.setValue(f, p.maximum(f)); }
    Test.assert(store.decode(store.encode(p)).timeline().totalMs == 627600000);
    return true;
}

(:test)
function profilesNativeRoundTrip(logger) {
    // Dedicated key, never modifies any user profile or the active session.
    var key = "phase5-test-only";
    var store = new WorkoutProfiles();
    var p = new WorkoutPlan();
    p.setRepetitionValue(1, 1, 800);
    Test.assert(store.save(key, p));
    var reopened = new WorkoutProfiles();
    var loaded = reopened.load(key);
    Test.assert(loaded != null && loaded.repetitions[1][0] == 800 && loaded.repetitions[1][1] == 22700);
    Test.assert(reopened.erase(key));
    Test.assert(reopened.load(key) == null && reopened.message.equals("Empty slot"));
    return true;
}

(:test)
class ProfileMemoryStore extends WorkoutProfiles {
    var values;
    var failWrites = false;
    var failReads = false;
    var failDeletes = false;
    function initialize() { WorkoutProfiles.initialize(); values = {}; }
    function read(key) {
        if (failReads) { throw new Toybox.Lang.InvalidValueException("read"); }
        return values.hasKey(key) ? values[key] : null;
    }
    function write(key, value) {
        if (failWrites) { throw new Toybox.Lang.InvalidValueException("write"); }
        values[key] = value;
    }
    function remove(key) {
        if (failDeletes) { throw new Toybox.Lang.InvalidValueException("delete"); }
        values.remove(key);
    }
}

(:test)
class ProfileTestWorkout {
    var plan;
    var profiles;
    function initialize() { plan = new WorkoutPlan(); profiles = new ProfileMemoryStore(); }
}

(:test)
function profileEditorDraftAndFailures(logger) {
    var w = new ProfileTestWorkout();
    var editor = new WorkoutEditor(w);
    editor.field = 8;
    editor.select();
    Test.assert(editor.individual);
    editor.select(); // Choose repetition 2.
    editor.move(1);
    editor.select();
    editor.field = 2;
    editor.select();
    editor.move(-1);
    editor.back();
    Test.assert(editor.draft.repetitions[1][1] == 22700);
    editor.select();
    editor.move(-1);
    editor.select();
    Test.assert(editor.draft.repetitions[1][1] == 22600);
    Test.assert(w.plan.repetitions[1][1] == 22700 && editor.draft.repetitions[0][1] == 23000);
    editor.back();
    editor.field = 10;
    editor.select();
    Test.assert(w.profiles.load("profile-1") == null);
    editor.back();
    Test.assert(!editor.confirming);
    editor.select();
    editor.select();
    Test.assert(w.profiles.load("profile-1").repetitions[1][1] == 22600);
    editor.draft.setValue(0, 1);
    editor.field = 11;
    editor.select();
    Test.assert(editor.draft.repetitions.size() == 4 && w.plan.repetitions[1][1] == 22700);
    editor.slot = 2;
    editor.select();
    Test.assert(editor.draft.repetitions.size() == 4 && editor.message.equals("Empty slot"));
    w.profiles.failWrites = true;
    Test.assert(!w.profiles.save("profile-1", w.plan));
    Test.assert(w.profiles.load("profile-1").repetitions[1][1] == 22600);
    w.profiles.failDeletes = true;
    Test.assert(!w.profiles.erase("profile-1"));
    w.profiles.failReads = true;
    Test.assert(w.profiles.load("profile-1") == null && w.profiles.message.equals("Read failed"));
    return true;
}

(:test)
class ProfileApplyRecording {
    var isPending = false;
    var prepared = 0;
    function initialize() {}
    function pending() { return isPending; }
    function prepare() { prepared += 1; }
}

(:test)
class ProfileApplyController extends WorkoutController {
    function initialize() {
        plan = new WorkoutPlan();
        repetitions = plan.repetitions;
        profiles = new ProfileMemoryStore();
        recording = new ProfileApplyRecording();
    }
}

(:test)
function activePlanSaveFailureAndGuards(logger) {
    var w = new ProfileApplyController();
    var draft = w.plan.copy();
    draft.setRepetitionValue(1, 2, 200);
    w.profiles.failWrites = true;
    Test.assert(!w.applyPlan(draft));
    Test.assert(w.plan.repetitions[1][1] == 22700 && w.recording.prepared == 0);
    w.profiles.failWrites = false;
    w.running = true;
    Test.assert(!w.applyPlan(draft));
    w.running = false;
    w.recording.isPending = true;
    Test.assert(!w.applyPlan(draft));
    Test.assert(w.profiles.load("active-session") == null);
    w.recording.isPending = false;
    Test.assert(w.applyPlan(draft));
    Test.assert(w.plan.repetitions[1][1] == 20000 && w.recording.prepared == 1);
    draft.setRepetitionValue(1, 2, 210);
    Test.assert(w.plan.repetitions[1][1] == 20000);
    Test.assert(w.profiles.load("active-session").repetitions[1][1] == 20000);
    return true;
}

(:test)
function profileSlotsAndDeleteConfirmation(logger) {
    var w = new ProfileTestWorkout();
    var editor = new WorkoutEditor(w);
    editor.field = 10;
    editor.select(); editor.select();
    editor.slot = 2;
    editor.draft.setValue(0, 2);
    editor.select(); editor.select();
    Test.assert(w.profiles.load("profile-1").repetitions.size() == 4);
    Test.assert(w.profiles.load("profile-2").repetitions.size() == 2);
    editor.field = 12;
    editor.select();
    editor.back();
    Test.assert(w.profiles.load("profile-2") != null);
    editor.select(); editor.select();
    Test.assert(w.profiles.load("profile-2") == null);
    Test.assert(w.profiles.load("profile-1") != null && editor.draft.repetitions.size() == 2);
    w.profiles.values["profile-2"] = [99];
    editor.field = 11;
    editor.select();
    Test.assert(editor.message.equals("Invalid saved session") && editor.draft.repetitions.size() == 2);
    return true;
}
