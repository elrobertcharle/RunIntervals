import Toybox.Test;

(:test)
function workoutTimeline(logger) {
    var e = new WorkoutEngine([[400, 23000, 60000], [400, 22100, 0]], 10000, 5000, 1000);
    Test.assert(e.totalMs == 255400);
    Test.assert(!e.update(10999)[1]);
    Test.assert(e.update(11037)[0]);
    Test.assert(e.phase()[1] == 10000);
    Test.assert(!e.update(33999)[1]);
    Test.assert(e.update(34037)[1]);
    Test.assert(!e.update(34037)[1]);
    Test.assert(!e.update(56999)[1]);
    Test.assert(e.update(57007)[1]);
    var event = e.update(103000);
    Test.assert(!event[0] && event[1]); // final target beep does not finish effort
    Test.assert(e.phase()[0].equals("EFFORT"));
    Test.assert(e.lap(106000)); // 95 s actual versus 92 s target
    Test.assert(e.effortResults[0][1] == 95000);
    Test.assert(e.phase()[0].equals("RECOVERY"));
    Test.assert(!e.lap(106010)); // repeated LAP cannot skip recovery
    Test.assert(!e.update(150000)[1]);
    Test.assert(e.update(166049)[0]);
    Test.assert(e.phase()[1] == 165000);
    Test.assert(!e.update(188099)[1]);
    Test.assert(e.update(188107)[1]);
    Test.assert(e.lap(250000)); // second effort faster than target
    Test.assert(e.effortResults[1][1] == 84000);
    Test.assert(e.phase()[0].equals("COOL-DOWN"));
    Test.assert(e.phase()[1] == 249000 && e.totalMs == 254000);
    Test.assert(!e.update(254999)[1]);
    Test.assert(e.update(255000)[0] && e.done());
    Test.assert(!e.lap(255000));
    Test.assert(!e.update(300000)[0]);
    return true;
}

(:test)
function workoutMissedCallbacks(logger) {
    var e = new WorkoutEngine([[400, 22000, 1000], [400, 22500, 0]], 0, 0, 0);
    Test.assert(e.update(66010)[1]);
    Test.assert(e.skipped == 2 && e.nextMark == 4);
    Test.assert(!e.update(100000)[0]);
    Test.assert(e.phase()[0].equals("EFFORT") && e.nextMark == 5);
    Test.assert(!e.update(120000)[1]); // no marks beyond planned distance
    Test.assert(e.lap(120000));
    Test.assert(e.update(121000)[0]);
    Test.assert(e.phase()[1] == 121000 && e.phase()[3] == 1);
    Test.assert(!e.update(143499)[1]);
    Test.assert(e.update(143500)[1]);
    Test.assert(e.lap(200000) && e.done());
    e = new WorkoutEngine([[400, 22000, 1000], [400, 22500, 0]], 0, 0, 0);
    Test.assert(e.update(200000)[1] && !e.done());
    Test.assert(e.skipped == 3 && e.index == 0); // cannot skip an uncompleted effort
    return true;
}

(:test)
function workoutRolloverAndRestart(logger) {
    var e = new WorkoutEngine([[100, 22100, 60000]], 0, 0, 2147483640);
    Test.assert(!e.update(-2147483640)[1]);
    Test.assert(e.totalMs == 22100);
    Test.assert(e.update(-2147461556)[1] && !e.done());
    Test.assert(e.lap(-2147461556) && e.done());
    Test.assert(e.effortResults[0][1] == 22100);
    e = new WorkoutEngine([[400, 22100, 0]], 0, 0, -10);
    Test.assert(e.elapsed(10) == 20);
    Test.assert(e.index == 0 && e.nextMark == 1 && e.skipped == 0);
    Test.assert(e.update(22090)[1]);
    return true;
}

(:test)
function manualEffortNoRecoveryAndLateWarmup(logger) {
    var e = new WorkoutEngine([[100,1000,0],[100,2000,0]],1000,0,0);
    Test.assert(!e.lap(500)); // warm-up remains automatic
    Test.assert(e.update(10000)[0] && e.index == 1);
    Test.assert(e.phase()[1] == 1000 && !e.done());
    Test.assert(e.lap(11000) && e.index == 2);
    Test.assert(e.phase()[1] == 11000);
    Test.assert(!e.update(20000)[0] && !e.done());
    Test.assert(e.lap(21000) && e.done());
    Test.assert(e.totalMs == 21000 && e.effortResults.size() == 2);
    Test.assert(e.effortResults[0][1] == 10000 && e.effortResults[1][1] == 10000);
    var text = new WorkoutText();
    Test.assert(text.elapsedTime(95999).equals("1:35.9"));
    Test.assert(text.elapsedTime(1).equals("0:00.0"));
    return true;
}

(:test)
function workoutRejectsInvalidPlans(logger) {
    var rejected = 0;
    try { new WorkoutEngine([], 0, 0, 0); } catch (e) { rejected += 1; }
    try { new WorkoutEngine([[350, 22000, 0]], 0, 0, 0); } catch (e) { rejected += 1; }
    try { new WorkoutEngine([[400, 22101, 0]], 0, 0, 0); } catch (e) { rejected += 1; }
    try { new WorkoutEngine([[400, 22000, -1]], 0, 0, 0); } catch (e) { rejected += 1; }
    try { new WorkoutEngine([[400, 22000, 0]], -1, 0, 0); } catch (e) { rejected += 1; }
    Test.assert(rejected == 5);
    return true;
}
