import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class PrecisionProbe {
    var presets = [22000, 22500, 23000];
    var preset = 1;
    var pollMs = 50;
    var recordFit = false;
    var running = false;
    var status = "LISTO";
    var engine;
    var timer;
    var session;
    var rows = [];
    var lastUi = 0;
    var lastCallback = 0;
    var maxGap = 0;
    var runId = 0;

    function initialize() { timer = new Timer.Timer(); }
    function cycle() {
        if (!running) { preset = (preset + 1) % presets.size(); WatchUi.requestUpdate(); }
    }
    function toggleFit() {
        if (!running) { recordFit = !recordFit; WatchUi.requestUpdate(); }
    }
    function start() {
        if (running) { return; }
        if (session != null) { status = "REINICIAR APP: FIT"; WatchUi.requestUpdate(); return; }
        if (!(Attention has :playTone)) { status = "SIN SONIDO"; WatchUi.requestUpdate(); return; }
        rows = [];
        maxGap = 0;
        lastCallback = 0;
        lastUi = 0;
        runId += 1;
        try {
            if (recordFit) {
                session = ActivityRecording.createSession({:name=>"RunIntervals Lab", :sport=>Activity.SPORT_RUNNING, :subSport=>Activity.SUB_SPORT_GENERIC});
                if (!session.start()) { status = "ERROR FIT"; session = null; WatchUi.requestUpdate(); return; }
            }
            engine = new DeadlineEngine(presets[preset], 20, System.getTimer());
            running = true;
            status = "ESFUERZO";
            timer.start(method(:onTick), pollMs, true);
        } catch (e) {
            if (running) { finish("ERROR INICIO"); }
            else {
                status = "ERROR INICIO FIT";
                if (session != null) {
                    try { session.stop(); session.discard(); } catch (cleanupError) { }
                    session = null;
                }
            }
        }
        WatchUi.requestUpdate();
    }

    function onTick() {
        if (!running) { return; }
        var tick = System.getTimer();
        var now = engine.elapsed(tick);
        var gap = now - lastCallback;
        lastCallback = now;
        if (gap > maxGap) { maxGap = gap; }
        var due = engine.due(tick);
        if (due != null) {
            for (var i = due[0]; i < due[1]; i += 1) {
                rows.add([i, engine.target(i), -1, -1, gap, "SKIPPED"]);
            }
            if (now - engine.target(due[1]) >= engine.intervalMs) {
                rows.add([due[1], engine.target(due[1]), -1, -1, gap, "SKIPPED"]);
                if (engine.done()) { finish("COMPLETO"); }
                return;
            }
            // Request timestamp is sampled immediately before the API call.
            var requested = engine.elapsed(System.getTimer());
            var result = "REQUESTED";
            try { Attention.playTone(Attention.TONE_LOUD_BEEP); }
            catch (e) { result = "ERROR"; }
            var returned = engine.elapsed(System.getTimer());
            rows.add([due[1], engine.target(due[1]), requested, returned, gap, result]);
            if (result == "ERROR") { finish("ERROR SONIDO"); return; }
            if (engine.done()) { finish("COMPLETO"); return; }
        }
        // Drawing is deliberately less frequent than deadline checks.
        if (now - lastUi >= 250) { lastUi = now; WatchUi.requestUpdate(); }
    }

    function finish(reason) {
        if (!running) { return; }
        running = false;
        timer.stop();
        status = reason;
        if (session != null) {
            try {
                if (!session.stop()) { status = "ERROR STOP FIT"; }
                else if (!session.save()) { status = "ERROR SAVE FIT"; }
                else { session = null; }
            } catch (e) { status = "ERROR FIT"; }
        }
        // Buffer only 20 rows; disk/console I/O occurs AFTER timing is over.
        System.println("RI_BEGIN," + runId + "," + presets[preset] + "," + pollMs + "," + engine.origin + "," + recordFit);
        System.println("RI_HEADER,index,target_ms,request_ms,return_ms,callback_gap_ms,result");
        for (var j = 0; j < rows.size(); j += 1) {
            var r = rows[j];
            System.println("RI_EVENT," + r[0] + "," + r[1] + "," + r[2] + "," + r[3] + "," + r[4] + "," + r[5]);
        }
        System.println("RI_END," + status + "," + maxGap);
        WatchUi.requestUpdate();
    }
}
