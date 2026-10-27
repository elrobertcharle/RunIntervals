import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.System;
import Toybox.WatchUi;

// FIT lifecycle kept separate from the absolute workout timeline.
class WorkoutRecording {
    var session;
    var state = "NOT RECORDING";
    var phaseIndex = 0;
    var lapErrors = 0;
    var missedBoundaries = 0;
    var gpsQuality = Position.QUALITY_NOT_AVAILABLE;
    var heartRate;
    var sensorsActive = false;
    var sensorWarning = false;
    var metadata;
    var saveClock;
    var phaseStartDistance = 0;

    function initialize() {}
    function pending() { return session != null; }
    // Give native recording a moment to finalize before another start request.
    function canStart(tick) { return saveClock == null || saveClock.elapsed(tick) >= 1000; }

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
    function activityInfo() { return Activity.getActivityInfo(); }
    function liveData(info) {
        var distance = null;
        if (info != null && info.elapsedDistance != null) {
            if (phaseStartDistance == null) { phaseStartDistance = info.elapsedDistance; }
            distance = info.elapsedDistance - phaseStartDistance;
            if (distance < 0) { distance = 0; }
        }
        return [distance, info == null ? null : info.currentSpeed];
    }
    function start(phases) {
        if (pending() || !canStart(System.getTimer())) { return false; }
        phaseIndex = 0;
        phaseStartDistance = 0;
        lapErrors = 0;
        missedBoundaries = 0;
        metadata = null;
        state = "FIT START ERROR";
        try {
            session = createSession();
            if (session != null && session.start()) {
                if (phases != null) { metadata = new WorkoutFitMetadata(session, phases); }
                state = "RECORDING";
                return true;
            }
        } catch (e) {}
        // Keep even an unstarted session for an explicit save/discard decision.
        return false;
    }
    function phaseChanged(index) {
        if (!pending() || index <= phaseIndex) { return; }
        // addLap has no timestamp argument. Do not fabricate historical laps.
        missedBoundaries += index - phaseIndex - 1;
        phaseIndex = index;
        var info = activityInfo();
        phaseStartDistance = info == null ? null : info.elapsedDistance;
        var success = false;
        try {
            if (metadata != null) { metadata.writeLap(index); }
            success = session.addLap();
        } catch (e) {}
        if (!success) { lapErrors += 1; }
        if (metadata != null) { metadata.lapResult(index, success); }
    }
    function completed(index) {
        // stop/save closes the final lap. Count earlier boundaries missed by a late callback.
        if (index > phaseIndex) { missedBoundaries += index - phaseIndex - 1; }
        phaseIndex = index;
        if (metadata != null) { metadata.endIndex = index; }
    }
    function pause() {
        if (!pending()) { return false; }
        try {
            if (session.isRecording() && !session.stop()) { state = "FIT STOP ERROR"; return false; }
            state = "FIT PAUSED";
            return true;
        } catch (e) { state = "FIT STOP ERROR"; return false; }
    }
    function resume() {
        if (!pending()) { return false; }
        try {
            if (!session.isRecording() && !session.start()) { state = "FIT RESUME ERROR"; return false; }
            state = "RECORDING";
            return true;
        } catch (e) { state = "FIT RESUME ERROR"; return false; }
    }
    function stop(reason) {
        if (!pending()) { return true; }
        try {
            if (metadata != null) { metadata.finish(reason, lapErrors, missedBoundaries); }
            if (session.isRecording()) {
                if (!session.stop()) { state = "FIT STOP ERROR"; return false; }
            }
            state = "FIT NOT SAVED";
            return true;
        } catch (e) { state = "FIT STOP ERROR"; return false; }
    }
    function finish(reason) {
        if (!pending()) { return true; }
        if (!stop(reason)) { return false; }
        try {
            if (!session.save()) { state = "FIT SAVE ERROR"; return false; }
            session = null;
            metadata = null;
            saveClock = new DeadlineEngine(1, 1, System.getTimer());
            state = "FIT SAVED";
            return true;
        } catch (e) { state = "FIT ERROR"; return false; }
    }
    function discard() {
        if (!pending()) { return true; }
        if (!stop(null)) { return false; }
        try {
            if (!session.discard()) { state = "FIT DISCARD ERROR"; return false; }
            session = null;
            metadata = null;
            saveClock = new DeadlineEngine(1, 1, System.getTimer());
            state = "FIT DISCARDED";
            return true;
        } catch (e) { state = "FIT DISCARD ERROR"; return false; }
    }
}
