import Toybox.Application;
import Toybox.WatchUi;

class RunIntervalsApp extends Application.AppBase {
    var workout;
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        workout = new WorkoutController();
        return [new WorkoutView(workout), new WorkoutDelegate(workout)];
    }
    function onStop(state) {
        if (workout != null) { workout.shutdown(); }
    }
}
