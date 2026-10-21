import Toybox.FitContributor;

// Developer fields identify phases without overwriting Garmin's native FIT data.
class WorkoutFitMetadata {
    var phases;
    var fields = [];
    var currentIndex = 0;
    var endIndex;
    var mixed = false;
    var outcome = "INTERRUPTED";

    function initialize(session, plan) {
        phases = plan;
        fields.add(session.createField("Phase name", 0, FitContributor.DATA_TYPE_STRING, {:mesgType=>FitContributor.MESG_TYPE_LAP, :count=>24}));
        fields.add(session.createField("Phase type", 1, FitContributor.DATA_TYPE_UINT8, {:mesgType=>FitContributor.MESG_TYPE_LAP}));
        fields.add(session.createField("Repetition", 2, FitContributor.DATA_TYPE_UINT16, {:mesgType=>FitContributor.MESG_TYPE_LAP}));
        fields.add(session.createField("Target duration", 3, FitContributor.DATA_TYPE_FLOAT, {:mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"s"}));
        fields.add(session.createField("100m interval", 4, FitContributor.DATA_TYPE_FLOAT, {:mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"s"}));
        fields.add(session.createField("Workout result", 5, FitContributor.DATA_TYPE_STRING, {:mesgType=>FitContributor.MESG_TYPE_SESSION, :count=>32}));
        fields.add(session.createField("Lap errors", 6, FitContributor.DATA_TYPE_UINT16, {:mesgType=>FitContributor.MESG_TYPE_SESSION}));
        fields.add(session.createField("Missed boundaries", 7, FitContributor.DATA_TYPE_UINT16, {:mesgType=>FitContributor.MESG_TYPE_SESSION}));
        writeLap(1);
        writeSummary(null, 0, 0);
    }
    function writeLap(nextIndex) {
        var name = "Mixed phases";
        var code = 0;
        var repetition = 0;
        var duration = 0.0;
        var interval = 0.0;
        if (!mixed && nextIndex == currentIndex + 1 && currentIndex < phases.size()) {
            var p = phases[currentIndex];
            duration = (p[2] - p[1]) / 1000.0;
            if (p[0].equals("WARM-UP")) { name = "Warm-up"; code = 1; }
            else if (p[0].equals("EFFORT")) {
                code = 2;
                repetition = p[3] + 1;
                name = "Effort " + repetition;
                interval = p[4] / 1000.0;
            } else if (p[0].equals("RECOVERY")) { name = "Recovery"; code = 3; }
            else if (p[0].equals("COOL-DOWN")) { name = "Cool-down"; code = 4; }
        }
        fields[0].setData(name);
        fields[1].setData(code);
        fields[2].setData(repetition);
        fields[3].setData(duration);
        fields[4].setData(interval);
    }
    function lapResult(nextIndex, success) {
        currentIndex = nextIndex;
        // A failed native lap merges phases into the next successful lap.
        mixed = !success;
    }
    function writeSummary(reason, lapErrors, missed) {
        if (reason != null) { outcome = reason; }
        fields[5].setData(outcome);
        fields[6].setData(lapErrors);
        fields[7].setData(missed);
    }
    function finish(reason, lapErrors, missed) {
        writeLap(endIndex == null ? currentIndex + 1 : endIndex);
        writeSummary(reason, lapErrors, missed);
    }
}
