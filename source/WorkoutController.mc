import Toybox.Attention;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class WorkoutController {
    var repetitions = [[400, 23000, 60000], [400, 22700, 60000], [400, 22400, 60000], [400, 22100, 0]];
    var engine;
    var timer;
    var running = false;
    var status = "READY";
    var lastUi = 0;
    var recording;

    function initialize() {
        timer = new Timer.Timer();
        recording = new WorkoutRecording();
        recording.prepare();
    }
    function start() {
        if (running) { return; }
        if (recording.pending()) {
            recording.finish();
            WatchUi.requestUpdate();
            return;
        }
        if (!(Attention has :playTone)) { status = "NO SOUND"; WatchUi.requestUpdate(); return; }
        try {
            recording.prepare();
            if (!recording.start()) { finish("START ERROR"); return; }
            engine = new WorkoutEngine(repetitions, 60000, 60000, System.getTimer());
            lastUi = 0;
            running = true;
            status = "IN PROGRESS";
            timer.start(method(:onTick), 50, true);
        } catch (e) { finish("START ERROR"); }
        WatchUi.requestUpdate();
    }
    function onTick() {
        if (!running) { return; }
        var tick = System.getTimer();
        var event = engine.update(tick);
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
        running = false;
        timer.stop();
        status = reason;
        recording.finish();
        recording.release();
        WatchUi.requestUpdate();
    }
    function shutdown() {
        running = false;
        timer.stop();
        recording.finish();
        recording.release();
    }
}
