import Toybox.Attention;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class WorkoutController {
    var plan;
    var profiles;
    var repetitions;
    var engine;
    var timer;
    var running = false;
    var status = "READY";
    var lastUi = 0;
    var recording;
    var finishedMs = 0;
    var confirmSave = false;
    var endChoice = 0; // 0 = save, 1 = discard
    var confirmDiscard = false;

    function initialize() {
        profiles = new WorkoutProfiles();
        plan = profiles.load("active-session");
        if (plan == null) {
            plan = new WorkoutPlan();
            if (!profiles.message.equals("Empty slot")) { status = "SAVED PLAN ERROR"; }
        }
        repetitions = plan.repetitions;
        timer = new Timer.Timer();
        recording = new WorkoutRecording();
        recording.prepare();
    }
    function applyPlan(draft) {
        if (running || recording.pending()) { return false; }
        // Validate the entire timeline before replacing the session.
        try { draft.timeline(); } catch (e) { return false; }
        if (!profiles.save("active-session", draft)) { return false; }
        plan = draft.copy();
        repetitions = plan.repetitions;
        engine = null;
        status = "READY";
        recording.prepare();
        return true;
    }
    function edit() {
        if (running || recording.pending()) { return; }
        var editor = new WorkoutEditor(self);
        WatchUi.pushView(editor, new WorkoutEditorDelegate(editor), WatchUi.SLIDE_IMMEDIATE);
    }
    function start() {
        if (running) { finish("CANCELLED"); return; }
        if (recording.pending()) {
            if (!confirmSave) {
                confirmSave = true;
                endChoice = 0;
                confirmDiscard = false;
            }
            else if (endChoice == 1 && !confirmDiscard) { confirmDiscard = true; }
            else {
                if (endChoice == 1) { recording.discard(); }
                else { recording.finish(null); }
                if (!recording.pending()) {
                    confirmSave = false;
                    confirmDiscard = false;
                }
            }
            WatchUi.requestUpdate();
            return;
        }
        if (!recording.canStart(System.getTimer())) {
            status = "PLEASE WAIT";
            WatchUi.requestUpdate();
            return;
        }
        if (!(Attention has :playTone)) { status = "NO SOUND"; WatchUi.requestUpdate(); return; }
        try {
            recording.prepare();
            engine = new WorkoutEngine(repetitions, plan.warmupMs, plan.cooldownMs, System.getTimer());
            if (!recording.start(engine.phases)) { finish("START ERROR"); return; }
            // Plan construction and FIT field setup happen before the timing origin.
            engine.clock.origin = System.getTimer();
            lastUi = 0;
            finishedMs = 0;
            confirmSave = false;
            confirmDiscard = false;
            endChoice = 0;
            running = true;
            status = "IN PROGRESS";
            timer.start(method(:onTick), 50, true);
        } catch (e) { finish("START ERROR"); }
        WatchUi.requestUpdate();
    }
    function chooseEnd(direction) {
        if (running || !recording.pending() || !confirmSave || confirmDiscard) { return; }
        endChoice = (endChoice + direction + 2) % 2;
        WatchUi.requestUpdate();
    }
    function onTick() {
        if (!running) { return; }
        var tick = System.getTimer();
        var event = engine.update(tick);
        handleEvent(event, tick);
    }
    function lap() {
        if (!running || engine == null) { return; }
        var tick = System.getTimer();
        if (!engine.lap(tick)) { return; }
        // Close the native FIT lap immediately, before requesting feedback.
        if (!engine.done()) { recording.phaseChanged(engine.index); }
        handleEvent([true, false], tick);
    }
    function handleEvent(event, tick) {
        try {
            if (engine.done()) {
                Attention.playTone(Attention.TONE_SUCCESS);
                recording.completed(engine.index);
                finish("COMPLETE");
                return;
            }
            // Only the current phase can produce a reference tone.
            if (event[1]) { Attention.playTone(Attention.TONE_LOUD_BEEP); }
            else if (event[0]) { Attention.playTone(Attention.TONE_INTERVAL_ALERT); }
        } catch (e) { finish("SOUND ERROR"); return; }
        // Sound is requested first; disk-related lap work cannot delay that request.
        if (event[0]) { recording.phaseChanged(engine.index); }
        var now = engine.elapsed(tick);
        if (event[0] || now - lastUi >= 250) { lastUi = now; WatchUi.requestUpdate(); }
    }
    function finish(reason) {
        if (running && engine != null) {
            finishedMs = engine.elapsed(System.getTimer());
            if (engine.done() && finishedMs > engine.totalMs) { finishedMs = engine.totalMs; }
        }
        running = false;
        timer.stop();
        status = reason;
        recording.stop(reason);
        confirmSave = recording.pending();
        endChoice = 0;
        confirmDiscard = false;
        recording.release();
        WatchUi.requestUpdate();
    }
    function shutdown() {
        var reason = running ? "APP STOP" : null;
        running = false;
        timer.stop();
        recording.stop(reason);
        recording.release();
    }
}
