import Toybox.Test;

(:test)
function stepsFollowScheduledTimeline(logger) {
    var p = new WorkoutPlan();
    p.repetitions = [[1000, 22500, 30000], [400, 23100, 60000]];
    p.cooldownMs = 60000;
    var steps = new WorkoutSteps(p);
    Test.assert(steps.phases.size() == 4);
    Test.assert(steps.title(0).equals("Run 1000 m"));
    Test.assert(steps.paceLabel(0).equals("Pace 3:45/km"));
    Test.assert(steps.alertLabel(0).equals("Alert 22.50 s / 100 m"));
    Test.assert(steps.title(1).equals("Rest 0:30"));
    Test.assert(steps.title(2).equals("Run 400 m"));
    Test.assert(steps.alertLabel(2).equals("Alert 23.10 s / 100 m"));
    Test.assert(steps.title(3).equals("Cool down 1:00"));
    p.repetitions[0][0] = 800;
    Test.assert(steps.title(0).equals("Run 1000 m"));
    Test.assert(p.repetitions[1][2] == 60000);
    return true;
}

(:test)
function stepsSkipAbsentPhasesAndClampScroll(logger) {
    var p = new WorkoutPlan();
    p.cooldownMs = 0;
    p.repetitions = [[100, 1000, 0], [100, 120000, 30000]];
    var steps = new WorkoutSteps(p);
    Test.assert(steps.phases.size() == 2);
    var delegate = new WorkoutStepsDelegate(steps);
    delegate.onPreviousPage();
    Test.assert(steps.selected == 0);
    delegate.onNextPage();
    Test.assert(steps.selected == 1);
    delegate.onNextPage();
    Test.assert(steps.selected == 1);
    Test.assert(steps.alertLabel(1).equals("Alert 120.00 s / 100 m"));
    Test.assert(steps.paceLabel(1).equals("Pace 20:00/km"));
    delegate.onPreviousPage();
    Test.assert(steps.selected == 0);
    return true;
}
