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
    Test.assert(event[0] && !event[1]);
    Test.assert(e.phase()[0].equals("RECOVERY"));
    Test.assert(!e.update(150000)[1]);
    Test.assert(e.update(163049)[0]);
    Test.assert(e.phase()[1] == 162000);
    Test.assert(!e.update(185099)[1]);
    Test.assert(e.update(185107)[1]);
    Test.assert(e.update(251400)[0]);
    Test.assert(e.phase()[0].equals("COOL-DOWN"));
    Test.assert(!e.update(256399)[1]);
    Test.assert(e.update(256400)[0] && e.done());
    Test.assert(!e.update(300000)[0]);
    return true;
}

(:test)
function workoutMissedCallbacks(logger) {
    var e = new WorkoutEngine([[400, 22000, 1000], [400, 22500, 0]], 0, 0, 0);
    Test.assert(e.update(66010)[1]);
    Test.assert(e.skipped == 2 && e.nextMark == 4);
    Test.assert(e.update(100000)[0]);
    Test.assert(e.phase()[1] == 89000 && e.phase()[3] == 1);
    Test.assert(!e.update(111499)[1]);
    Test.assert(e.update(111500)[1]);
    Test.assert(!e.update(179000)[1] && e.done());
    e = new WorkoutEngine([[400, 22000, 1000], [400, 22500, 0]], 0, 0, 0);
    Test.assert(!e.update(200000)[1] && e.done());
    Test.assert(e.skipped == 6);
    return true;
}

(:test)
function workoutRolloverAndRestart(logger) {
    var e = new WorkoutEngine([[100, 22100, 60000]], 0, 0, 2147483640);
    Test.assert(!e.update(-2147483640)[1]);
    Test.assert(e.totalMs == 22100);
    Test.assert(e.update(-2147461556)[0] && e.done());
    e = new WorkoutEngine([[400, 22100, 0]], 0, 0, -10);
    Test.assert(e.elapsed(10) == 20);
    Test.assert(e.index == 0 && e.nextMark == 1 && e.skipped == 0);
    Test.assert(e.update(22090)[1]);
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
