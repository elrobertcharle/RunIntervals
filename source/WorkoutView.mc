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
        if (workout.confirmSave && fit.pending()) {
            line(dc, 0.12, Graphics.FONT_SMALL, workout.confirmDiscard ? "Discard activity?" : "ACTIVITY STOPPED");
            line(dc, 0.25, Graphics.FONT_LARGE, text.duration(workout.finishedMs));
            line(dc, 0.41, Graphics.FONT_TINY, fit.state);
            if (workout.confirmDiscard) {
                line(dc, 0.54, Graphics.FONT_SMALL, "Cannot be undone");
                line(dc, 0.68, Graphics.FONT_SMALL, "START: discard");
                line(dc, 0.80, Graphics.FONT_TINY, "BACK: cancel");
            } else {
                dc.setColor(workout.endChoice == 0 ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                line(dc, 0.53, Graphics.FONT_SMALL, (workout.endChoice == 0 ? "> " : "") + "Save");
                dc.setColor(workout.endChoice == 1 ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                line(dc, 0.65, Graphics.FONT_SMALL, (workout.endChoice == 1 ? "> " : "") + "Discard");
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                line(dc, 0.78, Graphics.FONT_TINY, "UP/DOWN: choose");
                line(dc, 0.85, Graphics.FONT_TINY, "START: select");
            }
            return;
        }
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
        line(dc, 0.70, Graphics.FONT_XTINY, (fit.gpsReady() ? "GPS OK" : "GPS ...") + " | HR " + (fit.heartRate == null ? "--" : fit.heartRate.toString()));
        line(dc, 0.77, Graphics.FONT_XTINY, fit.pending() ? "START: options" : "START: run");
        line(dc, 0.83, Graphics.FONT_XTINY, fit.pending() ? "Activity not saved" : "UP: edit");
        if (!fit.pending()) { line(dc, 0.89, Graphics.FONT_XTINY, "DOWN: steps"); }
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
        var timeLabel = effort ? text.elapsedTime(now - p[1]) : text.duration(left);
        var timeFont = Graphics.FONT_NUMBER_HOT;
        if (dc.getFontHeight(timeFont) > dc.getHeight() * 0.18 || dc.getTextWidthInPixels(timeLabel, timeFont) > dc.getWidth() * 0.86) { timeFont = Graphics.FONT_NUMBER_MEDIUM; }
        if (dc.getFontHeight(timeFont) > dc.getHeight() * 0.18 || dc.getTextWidthInPixels(timeLabel, timeFont) > dc.getWidth() * 0.86) { timeFont = Graphics.FONT_NUMBER_MILD; }
        line(dc, 0.28, timeFont, timeLabel);
        var lastResult = e.effortResults.size() > 0 ? e.effortResults[e.effortResults.size() - 1] : null;
        line(dc, 0.49, Graphics.FONT_TINY, effort ? "ELAPSED | LAP: end rep" : (lastResult == null ? "REMAINING" : "LAST " + (lastResult[0] + 1) + ": " + text.elapsedTime(lastResult[1])));
        if (repIndex >= 0) {
            var r = workout.repetitions[repIndex];
            if (effort) {
                var markLeft = p[1] + e.nextMark * p[4] - now;
                if (markLeft < 0) { markLeft = 0; }
                var finalMark = e.nextMark >= r[0] / 100;
                var targetPassed = e.nextMark > r[0] / 100;
                line(dc, 0.56, Graphics.FONT_SMALL, targetPassed ? "Target reached | LAP" : (finalMark ? "Target: " : "100 m: ") + text.interval(markLeft) + " s");
            } else { line(dc, 0.56, Graphics.FONT_SMALL, "Next: " + r[0] + " m"); }
            line(dc, 0.68, Graphics.FONT_TINY, text.pace(r[1]) + " | " + text.interval(r[1]) + " s");
        } else { line(dc, 0.60, Graphics.FONT_SMALL, "Auto finish"); }
        var fit = workout.recording;
        line(dc, 0.79, Graphics.FONT_XTINY, (fit.gpsReady() ? "GPS OK" : "GPS ...") + " | HR " + (fit.heartRate == null ? "--" : fit.heartRate.toString()));
        line(dc, 0.87, Graphics.FONT_XTINY, "START: stop");
        var width = dc.getWidth() * 0.60;
        var progress = (now - p[1]).toFloat() / (p[2] - p[1]);
        if (progress < 0) { progress = 0; }
        if (progress > 1) { progress = 1; }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(dc.getWidth() * 0.20, dc.getHeight() * 0.77, width, 4);
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.fillRectangle(dc.getWidth() * 0.20, dc.getHeight() * 0.77, width * progress, 4);
    }
}
class WorkoutDelegate extends WatchUi.BehaviorDelegate {
    var workout;
    function initialize(w) { BehaviorDelegate.initialize(); workout = w; }
    function onSelect() { workout.start(); return true; }
    function onMenu() { workout.edit(); return true; }
    function onPreviousPage() {
        if (workout.recording.pending()) { workout.chooseEnd(-1); }
        else { workout.edit(); }
        return true;
    }
    function onNextPage() {
        if (workout.recording.pending()) { workout.chooseEnd(1); }
        else { workout.showSteps(); }
        return true;
    }
    function onBack() {
        if (workout.running) { workout.lap(); return true; }
        else if (workout.recording.pending()) {
            if (workout.confirmDiscard) { workout.confirmDiscard = false; }
            else { workout.confirmSave = false; }
            WatchUi.requestUpdate();
        }
        else { workout.shutdown(); System.exit(); }
        return true;
    }
}
