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

class RunIntervalsApp extends Application.AppBase {
    var workout;
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        workout = new WorkoutController();
        return [new WorkoutView(workout), new WorkoutDelegate(workout)];
    }
    function onStop(state) {
        if (workout != null && workout.running) { workout.finish("APP_STOP"); }
    }
}
