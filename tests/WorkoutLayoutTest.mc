import Toybox.Test;

(:test)
class LayoutActivityInfo {
    var elapsedDistance;
    var currentSpeed;
    function initialize(distance, speed) { elapsedDistance = distance; currentSpeed = speed; }
}

(:test)
class LayoutRecording extends WorkoutRecording {
    var info;
    function initialize() { WorkoutRecording.initialize(); }
    function activityInfo() { return info; }
}

(:test)
function liveMetricsUseActualDistanceAndSpeed(logger) {
    var fit = new LayoutRecording();
    fit.session = new FakeWorkoutSession();
    fit.info = new LayoutActivityInfo(125.0, 4.0);
    fit.phaseChanged(1);
    fit.info = new LayoutActivityInfo(325.0, 5.0);
    var data = fit.liveData(fit.info);
    Test.assert(data[0] == 200.0 && data[1] == 5.0);
    fit.phaseChanged(2);
    fit.info = new LayoutActivityInfo(345.0, 0.0);
    data = fit.liveData(fit.info);
    Test.assert(data[0] == 20.0 && data[1] == 0.0);
    fit.info = new LayoutActivityInfo(null, null);
    fit.phaseChanged(3);
    Test.assert(fit.liveData(fit.info)[0] == null);
    fit.info = new LayoutActivityInfo(400.0, 4.0);
    Test.assert(fit.liveData(fit.info)[0] == 0.0);
    Test.assert(fit.liveData(new LayoutActivityInfo(390.0, 4.0))[0] == 0);
    var text = new WorkoutText();
    Test.assert(text.distance(1250).equals("1.25"));
    Test.assert(text.distance(null).equals("--"));
    Test.assert(text.realPace(4.0).equals("4:10"));
    Test.assert(text.realPace(5.0).equals("3:20"));
    Test.assert(text.realPace(null).equals("--:--"));
    Test.assert(text.realPace(0).equals("--:--"));
    Test.assert(text.realPace(-1).equals("--:--"));
    Test.assert(text.realPace(0.01).equals("--:--"));
    return true;
}

(:test)
function restUsesActualNextPhaseAndRemainingTime(logger) {
    var w = new LayoutWorkout();
    var v = new WorkoutView(w);
    w.engine = new WorkoutEngine([[400, 23000, 30000], [800, 22500, 60000]], 0, 10000, 0);
    Test.assert(w.engine.lap(90000));
    var rest = w.engine.phase();
    Test.assert(v.nextStep()[0].equals("EFFORT") && v.nextStep()[3] == 1);
    Test.assert(v.remainingFraction(rest, 90000) == 1.0);
    Test.assert(v.remainingFraction(rest, 105000) == 0.5);
    Test.assert(v.remainingFraction(rest, 120000) == 0.0);
    Test.assert(v.remainingFraction(rest, 130000) == 0.0);
    Test.assert(v.remainingFraction(rest, 80000) == 1.0);
    w.engine.index = w.engine.phases.size() - 1;
    Test.assert(v.nextStep() == null);
    return true;
}

(:test)
class LayoutWorkout {
    var engine;
    function initialize() {}
}
