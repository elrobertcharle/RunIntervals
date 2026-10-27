import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;

class ProbeView extends WatchUi.View {
    var probe;
    function initialize(p) { View.initialize(); probe = p; }
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var y = dc.getHeight();
        dc.drawText(x, (y * 0.13).toNumber(), Graphics.FONT_SMALL, "RunIntervals LAB", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, (y * 0.25).toNumber(), Graphics.FONT_SMALL, probe.status, Graphics.TEXT_JUSTIFY_CENTER);
        var interval = (probe.presets[probe.preset] / 1000.0).format("%.1f");
        var main = interval + " s";
        var detail = "20 avisos / FIT " + (probe.recordFit ? "SI" : "NO");
        if (probe.running) {
            var left = probe.engine.target(probe.engine.nextIndex) - probe.engine.elapsed(System.getTimer());
            if (left < 0) { left = 0; }
            main = (left / 1000.0).format("%.1f") + " s";
            detail = "Aviso " + probe.engine.nextIndex + "/20 | " + interval + " s";
        }
        dc.drawText(x, (y * 0.39).toNumber(), Graphics.FONT_LARGE, main, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, (y * 0.57).toNumber(), Graphics.FONT_SMALL, detail, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class ProbeDelegate extends WatchUi.BehaviorDelegate {
    var probe;
    function initialize(p) { BehaviorDelegate.initialize(); probe = p; }
    function onSelect() { probe.start(); return true; }
    function onPreviousPage() { probe.cycle(); return true; }
    function onNextPage() { probe.toggleFit(); return true; }
    function onBack() {
        if (probe.running) { probe.finish("CANCELADO"); }
        else { System.exit(); }
        return true;
    }
}

