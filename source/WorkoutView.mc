import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;

class WorkoutView extends WatchUi.View {
    var workout;
    var text;
    function initialize(w) { View.initialize(); workout = w; text = new WorkoutText(); }
    function line(dc, y, font, value) {
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
    }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var fit = workout.recording;
        if (workout.running) { drawRunning(dc); return; }
        line(dc, 0.10, Graphics.FONT_SMALL, workout.status);
        if (workout.engine != null) {
            line(dc, 0.25, Graphics.FONT_LARGE, text.duration(workout.finishedMs));
            line(dc, 0.41, Graphics.FONT_SMALL, fit.state);
            line(dc, 0.53, Graphics.FONT_TINY, "Missed beeps: " + workout.engine.skipped);
            line(dc, 0.62, Graphics.FONT_TINY, "Lap errors: " + fit.lapErrors + " | Skips: " + fit.missedBoundaries);
        } else {
            var plan = workout.plan;
            line(dc, 0.25, Graphics.FONT_LARGE, plan.mixed(1) ? plan.repetitions.size() + " varied reps" : plan.repetitions.size() + " x " + plan.repetitions[0][0] + " m");
            line(dc, 0.41, Graphics.FONT_SMALL, plan.mixed(2) ? "Varied pace / 100 m" : text.pace(plan.repetitions[0][1]) + " | " + text.interval(plan.repetitions[0][1]) + " s");
            line(dc, 0.53, Graphics.FONT_TINY, "Warm " + text.duration(plan.warmupMs) + " | Cool " + text.duration(plan.cooldownMs));
            line(dc, 0.62, Graphics.FONT_TINY, plan.mixed(3) ? "Varied recovery" : "Recovery " + text.duration(plan.repetitions[0][2]));
        }
        line(dc, 0.71, Graphics.FONT_TINY, (fit.gpsReady() ? "GPS OK" : "GPS ...") + " | HR " + (fit.heartRate == null ? "--" : fit.heartRate.toString()));
        line(dc, 0.79, Graphics.FONT_TINY, fit.pending() ? "START: save" : "START: run");
        line(dc, 0.86, Graphics.FONT_TINY, fit.pending() ? "Retry save" : "UP: edit");
    }
    function drawRunning(dc) {
        var e = workout.engine;
        var p = e.phase();
        var now = e.elapsed(System.getTimer());
        var left = p[2] - now;
        if (left < 0) { left = 0; }
        var effort = p[0].equals("EFFORT");
        var color = effort ? Graphics.COLOR_ORANGE : Graphics.COLOR_BLUE;
        dc.setColor(color, Graphics.COLOR_BLACK);
        line(dc, 0.09, Graphics.FONT_SMALL, p[0]);
        var repIndex = p[3];
        if (repIndex < 0 && p[0].equals("WARM-UP")) { repIndex = 0; }
        var repLabel = repIndex >= 0 ? (effort ? "REP " : "NEXT ") + (repIndex + 1) + " / " + workout.repetitions.size() : "FINISHING";
        line(dc, 0.20, Graphics.FONT_SMALL, repLabel);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        line(dc, 0.30, Graphics.FONT_NUMBER_HOT, text.duration(left));
        line(dc, 0.47, Graphics.FONT_TINY, "REMAINING");
        if (repIndex >= 0) {
            var r = workout.repetitions[repIndex];
            if (effort) {
                var markLeft = p[1] + e.nextMark * p[4] - now;
                if (markLeft < 0) { markLeft = 0; }
                var finalMark = e.nextMark >= r[0] / 100;
                line(dc, 0.56, Graphics.FONT_SMALL, (finalMark ? "End: " : "100 m: ") + text.interval(markLeft) + " s");
            } else { line(dc, 0.56, Graphics.FONT_SMALL, "Next: " + r[0] + " m"); }
            line(dc, 0.68, Graphics.FONT_SMALL, text.pace(r[1]) + " | " + text.interval(r[1]) + " s");
        } else { line(dc, 0.60, Graphics.FONT_SMALL, "Session ends automatically"); }
        var fit = workout.recording;
        line(dc, 0.79, Graphics.FONT_TINY, (fit.gpsReady() ? "GPS OK" : "GPS ...") + " | HR " + (fit.heartRate == null ? "--" : fit.heartRate.toString()));
        line(dc, 0.86, Graphics.FONT_TINY, "BACK: end & save");
        var width = dc.getWidth() * 0.60;
        var progress = (now - p[1]).toFloat() / (p[2] - p[1]);
        if (progress < 0) { progress = 0; }
        if (progress > 1) { progress = 1; }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(dc.getWidth() * 0.20, dc.getHeight() * 0.74, width, 4);
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.fillRectangle(dc.getWidth() * 0.20, dc.getHeight() * 0.74, width * progress, 4);
    }
}
class WorkoutDelegate extends WatchUi.BehaviorDelegate {
    var workout;
    function initialize(w) { BehaviorDelegate.initialize(); workout = w; }
    function onSelect() { workout.start(); return true; }
    function onMenu() { workout.edit(); return true; }
    function onPreviousPage() { workout.edit(); return true; }
    function onBack() {
        if (workout.running) { workout.finish("CANCELLED"); }
        else if (workout.recording.pending()) { workout.start(); }
        else { workout.shutdown(); System.exit(); }
        return true;
    }
}
