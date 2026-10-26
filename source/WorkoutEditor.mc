import Toybox.Graphics;
import Toybox.WatchUi;

// Profiles load into this draft. Only Apply changes the active session.
class WorkoutEditor extends WatchUi.View {
    var workout;
    var draft;
    var field = 0;
    var editing = false;
    var candidate = 0;
    var individual = false;
    var repIndex = 0;
    var slot = 1;
    var confirming = false;
    var message = "";
    var labels = ["Repetitions", "Distance / rep", "100 m interval", "Recovery", "Cool-down", "Apply session", "Restore demo", "Edit each rep", "Profile slot", "Save profile", "Load profile", "Delete profile", "View steps"];
    var repLabels = ["Repetition", "Distance", "100 m interval", "Recovery after", "Session editor"];
    var text;
    function initialize(w) {
        View.initialize();
        workout = w;
        draft = w.plan.copy();
        text = new WorkoutText();
    }
    function currentValue() {
        if (individual) { return field == 0 ? repIndex + 1 : draft.repetitionValue(repIndex, field); }
        return field == 8 ? slot : draft.value(field);
    }
    function displayValue(v) {
        if (field == 0 || (!individual && field == 8)) { return v.toString(); }
        if (field == 1) { return v + " m"; }
        if (field == 2) { return text.interval(v * 100) + " s"; }
        return text.duration(v * 1000);
    }
    function move(direction) {
        message = "";
        confirming = false;
        if (editing) {
            var selector = (individual && field == 0) || (!individual && field == 8);
            var low = selector ? 1 : draft.minimum(field);
            var high = selector ? (individual ? draft.repetitions.size() : 3) : draft.maximum(field);
            candidate += direction * (selector ? 1 : draft.step(field));
            if (candidate < low) { candidate = low; }
            if (candidate > high) { candidate = high; }
        } else { field = (field + direction + (individual ? repLabels.size() : labels.size())) % (individual ? repLabels.size() : labels.size()); }
        WatchUi.requestUpdate();
    }
    function select() {
        message = "";
        if (editing) {
            if (individual && field == 0) { repIndex = candidate - 1; }
            else if (!individual && field == 8) { slot = candidate; }
            else if (individual) { draft.setRepetitionValue(repIndex, field, candidate); }
            else { draft.setValue(field, candidate); }
            editing = false;
        } else if (individual && field == 4) { individual = false; field = 7; }
        else if (!individual && field == 5) {
            if (workout.applyPlan(draft)) { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
            else { message = "Apply failed: retry"; }
        } else if (!individual && field == 6) { draft = new WorkoutPlan(); field = 0; }
        else if (!individual && field == 7) { individual = true; repIndex = 0; field = 0; }
        else if (!individual && field == 12) {
            var steps = new WorkoutSteps(draft);
            WatchUi.pushView(steps, new WorkoutStepsDelegate(steps), WatchUi.SLIDE_IMMEDIATE);
        }
        else if (!individual && field >= 9) {
            var profiles = workout.profiles;
            var key = profiles.slotKey(slot);
            if (field == 10) {
                var loaded = profiles.load(key);
                if (loaded != null) { draft = loaded; message = "Loaded into draft"; }
                else { message = profiles.message; }
            } else if (!confirming) { confirming = true; message = "START again: confirm"; }
            else {
                if (field == 9) { profiles.save(key, draft); }
                else { profiles.erase(key); }
                confirming = false;
                message = profiles.message;
            }
        } else { candidate = currentValue(); editing = true; }
        WatchUi.requestUpdate();
    }
    function back() {
        if (confirming) { confirming = false; message = "Cancelled"; }
        else if (editing) { editing = false; }
        else if (individual) { individual = false; field = 7; }
        else { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
        WatchUi.requestUpdate();
    }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var h = dc.getHeight();
        dc.drawText(x, h * 0.12, Graphics.FONT_SMALL, editing ? "CHANGE VALUE" : (individual ? "REP " + (repIndex + 1) + " / " + draft.repetitions.size() : "EDIT SESSION"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(x, h * 0.27, Graphics.FONT_SMALL, individual ? repLabels[field] : labels[field], Graphics.TEXT_JUSTIFY_CENTER);
        var numeric = individual ? field < 4 : (field < 5 || field == 8);
        var value = numeric ? displayValue(editing ? candidate : currentValue()) : (individual ? "Back" : (field == 5 ? "Apply" : (field == 6 ? "Demo" : (field == 7 || field == 12 ? "Open" : "Slot " + slot))));
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(x, h * 0.40, Graphics.FONT_LARGE, value, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var hint = "";
        if (field == 2) { hint = text.pace((editing ? candidate : currentValue()) * 100); }
        else if (!individual && field == 5) { hint = "Total " + text.duration(draft.timeline().totalMs); }
        else if (!individual && field == 6) { hint = "4 x 400 m, varied pace"; }
        else if (!individual && field == 12) { hint = "Preview draft steps"; }
        else if (!individual && field >= 8) { hint = "Profile " + slot + " / 3"; }
        else if (individual && field == 3 && repIndex == draft.repetitions.size() - 1) { hint = "Last recovery unused"; }
        else if (field >= 3 && field <= 4 && numeric) { hint = "0:00 = skip phase"; }
        dc.drawText(x, h * 0.54, Graphics.FONT_SMALL, hint, Graphics.TEXT_JUSTIFY_CENTER);
        var note = individual ? "Changes stay in draft" : (field >= 1 && field <= 3 ? "Applies to every rep" : "Apply saves session");
        if (!individual && !editing && draft.mixed(field)) { note = "Mixed: edit sets all reps"; }
        if (!individual && field == 9) { note = "Replaces selected slot"; }
        if (!individual && field == 10) { note = "Load, review, then Apply"; }
        if (!individual && field == 11) { note = "Deletes selected slot"; }
        dc.drawText(x, h * 0.66, Graphics.FONT_TINY, message.equals("") ? note : message, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, h * 0.76, Graphics.FONT_TINY, editing ? "UP + / DOWN -" : "UP/DOWN: field", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, h * 0.83, Graphics.FONT_TINY, editing ? "START: set" : "START: select", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WorkoutEditorDelegate extends WatchUi.BehaviorDelegate {
    var editor;
    function initialize(e) { BehaviorDelegate.initialize(); editor = e; }
    function onNextPage() { editor.move(editor.editing ? -1 : 1); return true; }
    function onPreviousPage() { editor.move(editor.editing ? 1 : -1); return true; }
    function onSelect() { editor.select(); return true; }
    function onBack() { editor.back(); return true; }
}
