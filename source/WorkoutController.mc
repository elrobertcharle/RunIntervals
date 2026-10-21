import Toybox.Attention;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class WorkoutController {
    var repetitions = [[400, 23000, 60000], [400, 22700, 60000], [400, 22400, 60000], [400, 22100, 0]];
    var engine;
    var timer;
    var running = false;
    var status = "LISTO";
    var lastUi = 0;

    function initialize() { timer = new Timer.Timer(); }
    function start() {
        if (running) { return; }
        if (!(Attention has :playTone)) { status = "SIN SONIDO"; WatchUi.requestUpdate(); return; }
        try {
            engine = new WorkoutEngine(repetitions, 60000, 60000, System.getTimer());
            lastUi = 0;
            running = true;
            status = "EN CURSO";
            timer.start(method(:onTick), 50, true);
        } catch (e) { finish("ERROR INICIO"); }
        WatchUi.requestUpdate();
    }
    function onTick() {
        if (!running) { return; }
        var tick = System.getTimer();
        var event = engine.update(tick);
        try {
            if (engine.done()) {
                finish("COMPLETO");
                Attention.playTone(Attention.TONE_SUCCESS);
                return;
            }
            // Only the current phase can produce a reference tone.
            if (event[1]) { Attention.playTone(Attention.TONE_LOUD_BEEP); }
            else if (event[0]) { Attention.playTone(Attention.TONE_INTERVAL_ALERT); }
        } catch (e) { finish("ERROR SONIDO"); return; }
        var now = engine.elapsed(tick);
        if (event[0] || now - lastUi >= 250) { lastUi = now; WatchUi.requestUpdate(); }
    }
    function finish(reason) {
        running = false;
        timer.stop();
        status = reason;
        WatchUi.requestUpdate();
    }
}
