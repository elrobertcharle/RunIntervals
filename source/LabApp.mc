import Toybox.Application;
import Toybox.WatchUi;

class LabApp extends Application.AppBase {
    var probe;
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        probe = new PrecisionProbe();
        return [new ProbeView(probe), new ProbeDelegate(probe)];
    }
    function onStop(state) {
        if (probe != null) { probe.finish("APP_STOP"); }
    }
}
