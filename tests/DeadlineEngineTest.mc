import Toybox.Test;

(:test)
function absoluteDeadlines(logger) {
    var e = new DeadlineEngine(22500, 20, 1000);
    Test.assert(e.due(23499) == null);
    Test.assert(e.due(23537)[1] == 1);
    Test.assert(e.target(2) == 45000);
    Test.assert(e.due(45999) == null);
    Test.assert(e.due(46007)[1] == 2);
    Test.assert(e.target(20) == 450000);
    return true;
}

(:test)
function missedCallbacks(logger) {
    var e = new DeadlineEngine(22000, 20, 0);
    var d = e.due(66010);
    Test.assert(d[0] == 1 && d[1] == 3);
    Test.assert(e.nextIndex == 4);
    Test.assert(e.due(66010) == null);
    d = e.due(500000);
    Test.assert(d[1] == 20 && e.done());
    Test.assert(e.due(600000) == null);
    return true;
}

(:test)
function signedTimerRollover(logger) {
    var e = new DeadlineEngine(23000, 20, 2147483640);
    Test.assert(e.elapsed(-2147483640) == 16);
    Test.assert(e.due(-2147460656)[1] == 1);
    e = new DeadlineEngine(22100, 20, -10);
    Test.assert(e.elapsed(10) == 20);
    Test.assert(e.target(20) == 442000);
    return true;
}
