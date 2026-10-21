import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;

class WorkoutView extends WatchUi.View {
    var workout;
    function initialize(w) { View.initialize(); workout = w; }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var h = dc.getHeight();
        var title = workout.status;
        var main = "4 x 400 m";
        var detail = "23.0 / 22.7 / 22.4 / 22.1 s";
        var next = "Warm-up/cool-down: 1 min";
        var extra = "Recovery: 1 min";
        var fit = workout.recording;
        var footer = "START: start | BACK: exit";
        if (workout.running) {
            var e = workout.engine;
            var p = e.phase();
            var now = e.elapsed(System.getTimer());
            title = p[0];
            var left = p[2] - now;
            if (left < 0) { left = 0; }
            main = (left / 1000.0).format("%.1f") + " s";
            detail = "";
            next = "";
            extra = "";
            footer = (fit.gpsReady() ? "GPS OK" : "GPS searching") + " | HR " + (fit.heartRate == null ? "--" : fit.heartRate.toString());
            if (p[3] >= 0) {
                var r = workout.repetitions[p[3]];
                detail = (p[0].equals("EFFORT") ? "Rep " : "Next ") + (p[3] + 1) + "/" + workout.repetitions.size();
                var pace = (r[1] / 100).toNumber();
                extra = (pace / 60).toNumber() + ":" + (pace % 60).format("%02d") + "/km | " + (r[1] / 1000.0).format("%.1f") + " s";
                if (p[0].equals("EFFORT")) {
                    var markLeft = p[1] + e.nextMark * p[4] - now;
                    if (markLeft < 0) { markLeft = 0; }
                    next = "100 m: " + (markLeft / 1000.0).format("%.1f") + " s";
                }
            }
        } else if (workout.engine != null) {
            detail = "Missed beeps: " + workout.engine.skipped;
            next = fit.state;
            extra = "Lap errors: " + fit.lapErrors + " | Skips: " + fit.missedBoundaries;
        } else {
            next = fit.gpsReady() ? "GPS OK | FIT on start" : "Waiting for GPS (optional)";
            extra = fit.sensorWarning ? "Check GPS / HR sensor" : "Recovery: 1 min | HR " + (fit.heartRate == null ? "--" : fit.heartRate.toString());
        }
        if (fit.pending() && !workout.running) {
            next = fit.state;
            footer = "START: retry save";
        }
        dc.drawText(x, (h * 0.13).toNumber(), Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, (h * 0.29).toNumber(), Graphics.FONT_LARGE, main, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, (h * 0.46).toNumber(), Graphics.FONT_SMALL, detail, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, (h * 0.57).toNumber(), Graphics.FONT_SMALL, next, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, (h * 0.68).toNumber(), Graphics.FONT_TINY, extra, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, (h * 0.79).toNumber(), Graphics.FONT_TINY, footer, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
class WorkoutDelegate extends WatchUi.BehaviorDelegate {
    var workout;
    function initialize(w) { BehaviorDelegate.initialize(); workout = w; }
    function onSelect() { workout.start(); return true; }
    function onBack() {
        if (workout.running) { workout.finish("CANCELLED"); }
        else if (workout.recording.pending()) { workout.start(); }
        else { workout.shutdown(); System.exit(); }
        return true;
    }
}
