import Toybox.Graphics;
import Toybox.WatchUi;

// A snapshot of the actual timeline, including only scheduled phases.
class WorkoutSteps extends WatchUi.View {
    var plan;
    var phases;
    var selected = 0;
    var text;

    function initialize(p) {
        View.initialize();
        plan = p.copy();
        phases = plan.timeline().phases;
        text = new WorkoutText();
    }
    function move(direction) {
        selected += direction;
        if (selected < 0) { selected = 0; }
        if (selected >= phases.size()) { selected = phases.size() - 1; }
        WatchUi.requestUpdate();
    }
    function title(index) {
        var p = phases[index];
        if (p[0].equals("EFFORT")) {
            return "Run " + (plan.repetitions[p[3]][0] / 1000.0).format("%.2f") + " km";
        }
        var label = p[0].equals("RECOVERY") ? "Rest " : "Cool down ";
        return label + text.duration(p[2] - p[1]);
    }
    function paceLabel(index) { return "Pace " + text.pace(phases[index][4]); }
    function alertLabel(index) { return "Alert " + text.interval(phases[index][4]) + " s / 100 m"; }
    function drawCard(dc, index, y, cardHeight) {
        var w = dc.getWidth();
        var active = index == selected;
        var effort = phases[index][0].equals("EFFORT");
        var accent = effort ? Graphics.COLOR_BLUE : Graphics.COLOR_YELLOW;
        var background = active ? 0x102438 : 0x101010;
        dc.setColor(background, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(w * 0.12, y, w * 0.76, cardHeight, 12);
        dc.setColor(accent, Graphics.COLOR_BLACK);
        dc.fillRectangle(w * 0.12, y + 8, 4, cardHeight - 16);
        var x = w * 0.17;
        var font = Graphics.FONT_SMALL;
        if (dc.getTextWidthInPixels(title(index), font) > w * 0.66) { font = Graphics.FONT_TINY; }
        dc.setColor(Graphics.COLOR_WHITE, background);
        dc.drawText(x, y + 8, font, title(index), Graphics.TEXT_JUSTIFY_LEFT);
        if (effort) {
            dc.setColor(Graphics.COLOR_LT_GRAY, background);
            dc.drawText(x, y + cardHeight * 0.36, Graphics.FONT_TINY, paceLabel(index), Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(0x55CCFF, background);
            var alertFont = Graphics.FONT_TINY;
            if (dc.getTextWidthInPixels(alertLabel(index), alertFont) > w * 0.66) { alertFont = Graphics.FONT_XTINY; }
            dc.drawText(x, y + cardHeight * 0.67, alertFont, alertLabel(index), Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(w / 2, h * 0.07, Graphics.FONT_SMALL, "STEPS", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawLine(w * 0.28, h * 0.17, w * 0.72, h * 0.17);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(w / 2, h * 0.18, Graphics.FONT_XTINY, (selected + 1) + " / " + phases.size(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setClip(0, h * 0.26, w, h * 0.57);
        var y = h * 0.27;
        for (var i = selected; i < phases.size() && i <= selected + 1; i += 1) {
            var cardHeight = h * (phases[i][0].equals("EFFORT") ? 0.33 : 0.18);
            drawCard(dc, i, y, cardHeight);
            y += cardHeight + h * 0.02;
        }
        dc.clearClip();
        // Position indicator beside the cards, away from the circular edge.
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.fillRectangle(w * 0.90, h * 0.34, 3, h * 0.32);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        var thumb = h * 0.32 / phases.size();
        if (thumb < 6) { thumb = 6; }
        var offset = phases.size() > 1 ? selected.toFloat() / (phases.size() - 1) * (h * 0.32 - thumb) : 0;
        dc.fillRectangle(w * 0.90, h * 0.34 + offset, 3, thumb);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(w / 2, h * 0.85, Graphics.FONT_XTINY, "UP/DOWN", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h * 0.91, Graphics.FONT_XTINY, "BACK", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class WorkoutStepsDelegate extends WatchUi.BehaviorDelegate {
    var view;
    function initialize(v) { BehaviorDelegate.initialize(); view = v; }
    function onNextPage() { view.move(1); return true; }
    function onPreviousPage() { view.move(-1); return true; }
    function onSwipe(event) {
        var direction = event.getDirection();
        if (direction == WatchUi.SWIPE_UP) { view.move(1); return true; }
        if (direction == WatchUi.SWIPE_DOWN) { view.move(-1); return true; }
        return false;
    }
    function onSelect() { return true; }
    function onBack() { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); return true; }
}
