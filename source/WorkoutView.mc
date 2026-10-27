import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;

class WorkoutView extends WatchUi.View {
    var workout;
    var text;
    var liveFonts = {};
    function initialize(w) { View.initialize(); workout = w; text = new WorkoutText(); }
    function line(dc, y, font, value) {
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
    }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (workout.showingDiscarded) {
            var message = "Activity Discarded";
            var font = fitFont(dc, message, [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY], dc.getWidth() * 0.90, dc.getHeight() * 0.15);
            dc.drawText(dc.getWidth() / 2, (dc.getHeight() - dc.getFontHeight(font)) / 2, font, message, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        var fit = workout.recording;
        if (workout.running) { drawRunning(dc); return; }
        if (workout.confirmSave && fit.pending()) {
            line(dc, workout.confirmDiscard ? 0.36 : 0.12, Graphics.FONT_SMALL, workout.confirmDiscard ? "Discard activity?" : (workout.paused ? "PAUSED" : "ACTIVITY STOPPED"));
            line(dc, workout.confirmDiscard ? 0.49 : 0.25, Graphics.FONT_LARGE, text.duration(workout.finishedMs));
            if (!workout.confirmDiscard) {
                if (!fit.state.equals("FIT PAUSED")) { line(dc, 0.38, Graphics.FONT_TINY, fit.state); }
                if (workout.paused) {
                    dc.setColor(workout.endChoice == 2 ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                    line(dc, 0.49, Graphics.FONT_SMALL, (workout.endChoice == 2 ? "> " : "") + "Resume");
                }
                dc.setColor(workout.endChoice == 0 ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                line(dc, workout.paused ? 0.61 : 0.53, Graphics.FONT_SMALL, (workout.endChoice == 0 ? "> " : "") + "Save");
                dc.setColor(workout.endChoice == 1 ? Graphics.COLOR_BLUE : Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                line(dc, workout.paused ? 0.73 : 0.65, Graphics.FONT_SMALL, (workout.endChoice == 1 ? "> " : "") + "Discard");
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            }
            return;
        }
        line(dc, 0.10, Graphics.FONT_SMALL, workout.engine == null ? (fit.gpsReady() ? "GPS OK" : "GPS ...") : workout.status);
        if (workout.engine != null) {
            line(dc, 0.25, Graphics.FONT_LARGE, text.duration(workout.finishedMs));
            line(dc, 0.41, Graphics.FONT_SMALL, fit.state);
            line(dc, 0.53, Graphics.FONT_TINY, "Missed beeps: " + workout.engine.skipped);
            line(dc, 0.62, Graphics.FONT_TINY, "Lap errors: " + fit.lapErrors + " | Skips: " + fit.missedBoundaries);
        } else {
            var plan = workout.plan;
            line(dc, 0.25, Graphics.FONT_LARGE, plan.mixed(1) ? plan.repetitions.size() + " varied reps" : plan.repetitions.size() + " x " + plan.repetitions[0][0] + " m");
            line(dc, 0.41, Graphics.FONT_SMALL, plan.mixed(2) ? "Varied pace / 100 m" : text.pace(plan.repetitions[0][1]) + " | " + text.interval(plan.repetitions[0][1]) + " s");
            line(dc, 0.53, Graphics.FONT_TINY, "Cool down " + text.duration(plan.cooldownMs));
            line(dc, 0.62, Graphics.FONT_TINY, plan.mixed(3) ? "Varied recovery" : "Recovery " + text.duration(plan.repetitions[0][2]));
        }
        if (workout.engine == null) {
            if (!workout.status.equals("READY")) { line(dc, 0.70, Graphics.FONT_XTINY, workout.status); }
            drawHeartRate(dc, 0.77);
        } else {
            line(dc, 0.70, Graphics.FONT_XTINY, (fit.gpsReady() ? "GPS OK" : "GPS ...") + " | HR " + (fit.heartRate == null ? "--" : fit.heartRate.toString()));
        }
        if (fit.pending()) {
            line(dc, 0.77, Graphics.FONT_XTINY, "START: options");
            line(dc, 0.83, Graphics.FONT_XTINY, "Activity not saved");
        }
    }
    function drawRunning(dc) {
        var e = workout.engine;
        var p = e.phase();
        var now = e.elapsed(System.getTimer());
        var left = p[2] - now;
        if (left < 0) { left = 0; }
        var effort = p[0].equals("EFFORT");
        if (effort) { drawEffort(dc, p, now); return; }
        if (p[0].equals("RECOVERY")) { drawRest(dc, p, now); return; }
        var color = effort ? Graphics.COLOR_ORANGE : Graphics.COLOR_BLUE;
        dc.setColor(color, Graphics.COLOR_BLACK);
        line(dc, 0.09, Graphics.FONT_SMALL, p[0]);
        var repIndex = p[3];
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
        line(dc, 0.87, Graphics.FONT_XTINY, "START: pause");
        var width = dc.getWidth() * 0.60;
        var progress = (now - p[1]).toFloat() / (p[2] - p[1]);
        if (progress < 0) { progress = 0; }
        if (progress > 1) { progress = 1; }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(dc.getWidth() * 0.20, dc.getHeight() * 0.77, width, 4);
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.fillRectangle(dc.getWidth() * 0.20, dc.getHeight() * 0.77, width * progress, 4);
    }
    function fitFont(dc, value, fonts, maxWidth, maxHeight) {
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(value, fonts[i]) <= maxWidth && dc.getFontHeight(fonts[i]) <= maxHeight) { return fonts[i]; }
        }
        return fonts[fonts.size() - 1];
    }
    function liveFont(dc, value, width, height) {
        var size = height.toNumber();
        if (!liveFonts.hasKey(size)) {
            liveFonts[size] = Graphics.getVectorFont({:font=>Graphics.FONT_SMALL, :scale=>size.toFloat() / dc.getFontHeight(Graphics.FONT_SMALL)});
        }
        var font = liveFonts[size];
        if (font == null) { font = Graphics.FONT_SMALL; }
        if (dc.getTextWidthInPixels(value, font) > width) {
            var smaller = (size * width / dc.getTextWidthInPixels(value, font)).toNumber();
            if (!liveFonts.hasKey(smaller)) {
                liveFonts[smaller] = Graphics.getVectorFont({:font=>Graphics.FONT_SMALL, :scale=>smaller.toFloat() / dc.getFontHeight(Graphics.FONT_SMALL)});
            }
            font = liveFonts[smaller];
            if (font == null) { font = fitFont(dc, value, [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY], width, height); }
        }
        return font;
    }
    function numberAt(dc, x, y, value, width, height) {
        var font = liveFont(dc, value, width, height);
        dc.drawText(x, y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
    }
    function drawHeartRate(dc, y) {
        var hr = workout.recording.heartRate;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var value = hr == null || hr <= 0 ? "--" : hr.toString();
        var font = liveFont(dc, value, w * 0.35, h * 0.16);
        var numberWidth = dc.getTextWidthInPixels(value, font);
        var heartSize = w * 0.075;
        var gap = w * 0.025;
        var left = (w - numberWidth - heartSize - gap) / 2;
        var top = h * y + (dc.getFontHeight(font) - heartSize) / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        // Draw the heart directly so it does not depend on font glyph coverage.
        dc.fillCircle(left + heartSize * 0.25, top + heartSize * 0.28, heartSize * 0.25);
        dc.fillCircle(left + heartSize * 0.75, top + heartSize * 0.28, heartSize * 0.25);
        dc.fillPolygon([[left, top + heartSize * 0.35], [left + heartSize, top + heartSize * 0.35], [left + heartSize * 0.5, top + heartSize]]);
        dc.drawText(left + heartSize + gap, h * y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
    }
    function drawEffort(dc, p, now) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var fit = workout.recording;
        var data = fit.liveData(fit.activityInfo());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        line(dc, 0.07, Graphics.FONT_SMALL, "REP " + (p[3] + 1) + " / " + workout.repetitions.size());
        numberAt(dc, w / 2, h * 0.17, text.elapsedTime(now - p[1]), w * 0.78, h * 0.19);
        dc.setColor(0xCC2266, Graphics.COLOR_BLACK);
        dc.drawLine(w * 0.10, h * 0.39, w * 0.90, h * 0.39);
        dc.drawLine(w / 2, h * 0.39, w / 2, h * 0.73);
        dc.drawLine(w * 0.13, h * 0.73, w * 0.87, h * 0.73);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(w * 0.28, h * 0.42, Graphics.FONT_XTINY, "DISTANCE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w * 0.72, h * 0.42, Graphics.FONT_XTINY, "PACE", Graphics.TEXT_JUSTIFY_CENTER);
        numberAt(dc, w * 0.28, h * 0.50, data[0] == null ? "--" : data[0].toNumber().toString(), w * 0.38, h * 0.21);
        numberAt(dc, w * 0.72, h * 0.50, text.realPace(data[1]), w * 0.38, h * 0.21);
        drawHeartRate(dc, 0.77);
    }
    function remainingFraction(p, now) {
        var fraction = (p[2] - now).toFloat() / (p[2] - p[1]);
        if (fraction < 0) { return 0.0; }
        if (fraction > 1) { return 1.0; }
        return fraction;
    }
    function nextStep() {
        var e = workout.engine;
        return e.index + 1 < e.phases.size() ? e.phases[e.index + 1] : null;
    }
    function drawRest(dc, p, now) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var left = p[2] - now;
        if (left < 0) { left = 0; }
        var radius = (w < h ? w : h) * 0.465;
        dc.setPenWidth(7);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawCircle(w / 2, h / 2, radius);
        var fraction = remainingFraction(p, now);
        var degrees = (360 * fraction).toNumber();
        if (degrees > 0) {
            dc.setColor(0xFFDD33, Graphics.COLOR_BLACK);
            if (degrees == 360) { dc.drawCircle(w / 2, h / 2, radius); }
            else { dc.drawArc(w / 2, h / 2, radius, Graphics.ARC_CLOCKWISE, 90, 90 - degrees); }
        }
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(w * 0.20, h * 0.19, Graphics.FONT_SMALL, "REST", Graphics.TEXT_JUSTIFY_LEFT);
        var countdown = text.duration(left);
        var font = fitFont(dc, countdown, [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY], w * 0.34, h * 0.12);
        dc.drawText(w * 0.79, h * 0.19, font, countdown, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawLine(w * 0.17, h * 0.31, w * 0.83, h * 0.31);
        var next = nextStep();
        line(dc, 0.38, Graphics.FONT_XTINY, "NEXT");
        if (next != null && next[0].equals("EFFORT")) {
            var r = workout.repetitions[next[3]];
            line(dc, 0.46, Graphics.FONT_SMALL, "Run " + r[0] + " m");
            line(dc, 0.58, Graphics.FONT_SMALL, text.pace(r[1]));
        } else {
            line(dc, 0.46, Graphics.FONT_SMALL, next == null ? "Finish" : next[0]);
            if (next != null) { line(dc, 0.58, Graphics.FONT_SMALL, text.duration(next[2] - next[1])); }
        }
        drawHeartRate(dc, 0.77);
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
        if (workout.showingDiscarded) { return true; }
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
