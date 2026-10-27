import Toybox.Application.Storage;
import Toybox.Lang;

// One versioned record per slot; no writes occur during a workout.
class WorkoutProfiles {
    var message = "";
    function initialize() {}
    function read(key) { return Storage.getValue(key); }
    function write(key, value) { Storage.setValue(key, value); }
    function remove(key) { Storage.deleteValue(key); }
    function slotKey(slot) { return "profile-" + slot; }
    function encode(plan) {
        var p = plan.copy();
        // Keep the v1 shape readable by existing installations; warm-up is retired.
        return [1, 0, p.cooldownMs, p.repetitions];
    }
    function validDuration(v) {
        return v instanceof Lang.Number && v >= 0 && v <= 3600000 && v % 5000 == 0;
    }
    function decode(data) {
        if (!(data instanceof Lang.Array) || data.size() != 4 ||
            !(data[0] instanceof Lang.Number) || data[0] != 1 ||
            !validDuration(data[1]) || !validDuration(data[2]) ||
            !(data[3] instanceof Lang.Array) || data[3].size() < 1 || data[3].size() > 40) { return null; }
        var p = new WorkoutPlan();
        p.repetitions = [];
        for (var i = 0; i < data[3].size(); i += 1) {
            var r = data[3][i];
            if (!(r instanceof Lang.Array) || r.size() != 3) { return null; }
            for (var j = 0; j < 3; j += 1) {
                if (!(r[j] instanceof Lang.Number)) { return null; }
            }
            if (r[0] < 100 || r[0] > 10000 || r[0] % 100 != 0 ||
                r[1] < 1000 || r[1] > 120000 || r[1] % 50 != 0 || !validDuration(r[2])) { return null; }
            p.repetitions.add([r[0], r[1], r[2]]);
        }
        // Validate but ignore the legacy warm-up duration when loading old profiles.
        p.cooldownMs = data[2];
        try { p.timeline(); } catch (e) { return null; }
        return p;
    }
    function load(key) {
        message = "";
        try {
            var data = read(key);
            if (data == null) { message = "Empty slot"; return null; }
            var p = decode(data);
            if (p == null) { message = "Invalid saved session"; }
            return p;
        } catch (e) { message = "Read failed"; return null; }
    }
    function save(key, plan) {
        message = "";
        try {
            var data = encode(plan);
            if (decode(data) == null) { message = "Invalid session"; return false; }
            write(key, data);
            message = "Saved";
            return true;
        } catch (e) { message = "Save failed"; return false; }
    }
    function erase(key) {
        try { remove(key); message = "Deleted"; return true; }
        catch (e) { message = "Delete failed"; return false; }
    }
}
