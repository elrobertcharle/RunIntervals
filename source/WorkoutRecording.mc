import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.WatchUi;

// FIT lifecycle kept separate from the absolute workout timeline.
class WorkoutRecording {
    var session;
    var state = "SIN GRABAR";
    var phaseIndex = 0;
    var lapErrors = 0;
    var missedBoundaries = 0;
    var gpsQuality = Position.QUALITY_NOT_AVAILABLE;
    var heartRate;
    var sensorsActive = false;
    var sensorWarning = false;

    function initialize() {}
    function pending() { return session != null; }

    function prepare() {
        if (sensorsActive) { return; }
        sensorsActive = true;
        sensorWarning = false;
        try { Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition)); }
        catch (e) { sensorWarning = true; }
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            Sensor.enableSensorEvents(method(:onSensor));
        } catch (e) { sensorWarning = true; }
    }
    function onPosition(info as Position.Info) as Void {
        gpsQuality = info.accuracy;
        if (!pending()) { WatchUi.requestUpdate(); }
    }
    function onSensor(info as Sensor.Info) as Void {
        heartRate = info.heartRate;
        if (!pending()) { WatchUi.requestUpdate(); }
    }
    function release() {
        if (!sensorsActive) { return; }
        try { Position.enableLocationEvents(Position.LOCATION_DISABLE, null); } catch (e) {}
        try { Sensor.enableSensorEvents(null); Sensor.setEnabledSensors([]); } catch (e) {}
        sensorsActive = false;
        gpsQuality = Position.QUALITY_NOT_AVAILABLE;
        heartRate = null;
    }
    function gpsReady() {
        return gpsQuality == Position.QUALITY_GOOD || gpsQuality == Position.QUALITY_USABLE;
    }
    function createSession() {
        return ActivityRecording.createSession({:name=>"RunIntervals", :sport=>Activity.SPORT_RUNNING, :subSport=>Activity.SUB_SPORT_GENERIC});
    }
    function start() {
        if (pending()) { return false; }
        phaseIndex = 0;
        lapErrors = 0;
        missedBoundaries = 0;
        state = "ERROR INICIO FIT";
        try {
            session = createSession();
            if (session != null && session.start()) { state = "GRABANDO"; return true; }
        } catch (e) {}
        // Keep even an unstarted session available for save/retry; never discard data.
        return false;
    }
    function phaseChanged(index) {
        if (!pending() || index <= phaseIndex) { return; }
        // addLap has no timestamp argument. Do not fabricate historical laps.
        missedBoundaries += index - phaseIndex - 1;
        phaseIndex = index;
        try { if (!session.addLap()) { lapErrors += 1; } }
        catch (e) { lapErrors += 1; }
    }
    function completed(index) {
        // stop/save closes the final lap. Count earlier boundaries missed by a late callback.
        if (index > phaseIndex) { missedBoundaries += index - phaseIndex - 1; }
        phaseIndex = index;
    }
    function finish() {
        if (!pending()) { return true; }
        try {
            if (session.isRecording() && !session.stop()) { state = "ERROR STOP FIT"; return false; }
            if (!session.save()) { state = "ERROR SAVE FIT"; return false; }
            session = null;
            state = "FIT GUARDADO";
            return true;
        } catch (e) { state = "ERROR FIT"; return false; }
    }
}
