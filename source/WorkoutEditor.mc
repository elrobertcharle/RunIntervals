import Toybox.Graphics;
import Toybox.WatchUi;

// A draft never mutates the active plan until Apply is selected.
class WorkoutEditor extends WatchUi.View {
    var workout;
    var draft;
    var field = 0;
    var editing = false;
    var candidate = 0;
    var labels = ["Repetitions", "Distance / rep", "100 m interval", "Recovery", "Warm-up", "Cool-down", "Apply session", "Restore demo"];
    var text;
    function initialize(w) {
        View.initialize();
        workout = w;
        draft = w.plan.copy();
        text = new WorkoutText();
    }
    function displayValue(v) {
        if (field == 0) { return v.toString(); }
        if (field == 1) { return v + " m"; }
        if (field == 2) { return text.interval(v * 100) + " s"; }
        return text.duration(v * 1000);
    }
    function move(direction) {
        if (editing) {
            candidate += direction * draft.step(field);
            if (candidate < draft.minimum(field)) { candidate = draft.minimum(field); }
            if (candidate > draft.maximum(field)) { candidate = draft.maximum(field); }
        } else { field = (field + direction + labels.size()) % labels.size(); }
        WatchUi.requestUpdate();
    }
    function select() {
        if (editing) { draft.setValue(field, candidate); editing = false; }
        else if (field == 6) {
            if (workout.applyPlan(draft)) { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
        } else if (field == 7) { draft = new WorkoutPlan(); field = 0; }
        else { candidate = draft.value(field); editing = true; }
        WatchUi.requestUpdate();
    }
    function back() {
        if (editing) { editing = false; WatchUi.requestUpdate(); }
        else { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
    }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var h = dc.getHeight();
        dc.drawText(x, h * 0.12, Graphics.FONT_SMALL, editing ? "CHANGE VALUE" : "EDIT SESSION", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(x, h * 0.27, Graphics.FONT_SMALL, labels[field], Graphics.TEXT_JUSTIFY_CENTER);
        var value = field < 6 ? displayValue(editing ? candidate : draft.value(field)) : (field == 6 ? "Apply" : "Demo");
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(x, h * 0.40, Graphics.FONT_LARGE, value, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var hint = "";
        if (field == 2) { hint = text.pace((editing ? candidate : draft.value(field)) * 100); }
        else if (field == 6) { hint = "Total " + text.duration(draft.timeline().totalMs); }
        else if (field == 7) { hint = "4 x 400 m, varied pace"; }
        else if (field >= 3) { hint = "0:00 = skip phase"; }
        dc.drawText(x, h * 0.54, Graphics.FONT_SMALL, hint, Graphics.TEXT_JUSTIFY_CENTER);
        var note = field >= 1 && field <= 3 ? "Applies to every rep" : "Kept until app exits";
        if (!editing && draft.mixed(field)) { note = "Mixed: edit sets all reps"; }
        dc.drawText(x, h * 0.66, Graphics.FONT_TINY, note, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, h * 0.76, Graphics.FONT_TINY, editing ? "UP + / DOWN -" : "UP/DOWN: field", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, h * 0.83, Graphics.FONT_TINY, editing ? "START: set" : "START: edit", Graphics.TEXT_JUSTIFY_CENTER);
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
