#!/usr/bin/env python3

"""

AERO-Q GCS - Standalone Live Ground Control Station

Runs the complete cyberpunk military HUD directly on desktop with:

1. Real-time MAVLink UDP (Port 14550) receiver for real drones / SITL.

2. Built-in tactical physics simulator when no live vehicle is connected.

"""



import sys

import math

import time

import threading

from pathlib import Path



from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer, QUrl, Qt

from PySide6.QtGui import QGuiApplication, QColor

from PySide6.QtQuick import QQuickView

from PySide6.QtPositioning import QGeoCoordinate

from PySide6 import QtLocation



try:

    from pymavlink import mavutil

    HAS_PYMAVLINK = True

except ImportError:

    HAS_PYMAVLINK = False





# -----------------------------------------------------------------------------

# MOCK QGC FACT & TELEMETRY OBJECTS

# -----------------------------------------------------------------------------

class MockFact(QObject):

    valueChanged = Signal()



    def __init__(self, val=0.0, units="", enum_str=""):

        super().__init__()

        self._val = float(val) if isinstance(val, (int, float)) else 0.0

        self._units = str(units)

        self._enum_str = str(enum_str)



    def get_val(self):

        return self._val



    def set_val(self, v):

        try:

            fv = float(v)

            if self._val != fv:

                self._val = fv

                self.valueChanged.emit()

        except (ValueError, TypeError):

            pass



    value = Property(float, get_val, set_val, notify=valueChanged)

    rawValue = Property(float, get_val, set_val, notify=valueChanged)



    def get_val_str(self):

        return f"{self._val:.1f}"



    valueString = Property(str, get_val_str, notify=valueChanged)



    def get_units(self):

        return self._units



    units = Property(str, get_units, constant=True)



    def get_enum_str(self):

        return self._enum_str or f"{int(self._val)}"



    enumStringValue = Property(str, get_enum_str, notify=valueChanged)





class MockBattery(QObject):

    def __init__(self, voltage=16.4, percent=88.0):

        super().__init__()

        self.voltage = MockFact(voltage, "V")

        self.percentRemaining = MockFact(percent, "%")





class MockBatteriesModel(QObject):

    countChanged = Signal()



    def __init__(self):

        super().__init__()

        self._bats = [MockBattery(16.4, 88.0)]



    @Property(int, notify=countChanged)

    def count(self):

        return len(self._bats)



    @Slot(int, result=QObject)

    def get(self, idx):

        if 0 <= idx < len(self._bats):

            return self._bats[idx]

        return None





class MockGPS(QObject):

    def __init__(self):

        super().__init__()

        self.count = MockFact(14, "")

        self.lock = MockFact(3, "", "3D FIX")

        self.hdop = MockFact(0.8, "")





class MockVehicle(QObject):

    rollChanged = Signal()

    pitchChanged = Signal()

    headingChanged = Signal()

    airSpeedChanged = Signal()

    groundSpeedChanged = Signal()

    altitudeRelativeChanged = Signal()

    climbRateChanged = Signal()

    armedChanged = Signal()

    flightModeChanged = Signal()

    flightModesChanged = Signal()

    communicationLostChanged = Signal()

    mavlinkStatusChanged = Signal()

    sensorsHealthBitsChanged = Signal()

    allSensorsHealthyChanged = Signal()

    coordinateChanged = Signal()

    homePositionChanged = Signal()

    textMessageReceived = Signal(int, int, int, str, str)



    def __init__(self):

        super().__init__()

        self._id = 1

        self._armed = True

        self._flightMode = "LOITER"

        self._flightModes = ["LOITER", "ALT HOLD", "STABILIZE", "AUTO MISSION", "RTL", "LAND"]

        self._firmwareType = "ArduPilot (ArduCopter)"

        self._vehicleType = "Multi-Rotor Quad X"

        self._commLost = False

        self._sensorsHealthBits = 0x303F

        self._allSensorsHealthy = True

        self._last_real_mavlink = 0.0



        self.roll = MockFact(0.0, "deg")

        self.pitch = MockFact(0.0, "deg")

        self.heading = MockFact(42.0, "deg")

        self.airSpeed = MockFact(14.2, "m/s")

        self.groundSpeed = MockFact(14.5, "m/s")

        self.altitudeRelative = MockFact(24.8, "m")

        self.climbRate = MockFact(0.4, "m/s")

        self.throttlePct = MockFact(48.0, "%")

        self.rcRSSI = MockFact(98.0, "%")

        self.hobbs = MockFact(0.0, "", "00:14:32")



        self.batteries = MockBatteriesModel()

        self.gps = MockGPS()



        self._mavlinkSentCount = 1420

        self._mavlinkReceivedCount = 1890

        self._mavlinkLossCount = 2

        self._mavlinkLossPercent = 0.1



        self._coordinate = QGeoCoordinate(13.0827, 80.2707, 24.8)

        self._homePosition = QGeoCoordinate(13.0827, 80.2707, 0.0)



    @Property(int, constant=True)

    def id(self): return self._id



    def get_armed(self): return self._armed

    def set_armed(self, a):

        if self._armed != a:

            self._armed = a

            self.armedChanged.emit()

            txt = "MOTORS ARMED - Propellers active" if a else "Vehicle disarmed"

            self.textMessageReceived.emit(self._id, 1, 4 if a else 6, txt, "")

    armed = Property(bool, get_armed, set_armed, notify=armedChanged)



    def get_flightMode(self): return self._flightMode

    def set_flightMode(self, m):

        if self._flightMode != m:

            self._flightMode = m

            self.flightModeChanged.emit()

            self.textMessageReceived.emit(self._id, 1, 6, f"Flight mode switched to {m}", "")

    flightMode = Property(str, get_flightMode, set_flightMode, notify=flightModeChanged)



    @Property(list, constant=True)

    def flightModes(self): return self._flightModes



    @Property(str, constant=True)

    def firmwareTypeString(self): return self._firmwareType



    @Property(str, constant=True)

    def vehicleTypeString(self): return self._vehicleType



    @Property(bool, notify=communicationLostChanged)

    def communicationLost(self): return self._commLost



    @Property(int, notify=sensorsHealthBitsChanged)

    def sensorsHealthBits(self): return self._sensorsHealthBits



    @Property(int, constant=True)

    def sensorsPresentBits(self): return 0x303F



    @Property(bool, notify=allSensorsHealthyChanged)

    def allSensorsHealthy(self): return self._allSensorsHealthy



    @Property(float, notify=mavlinkStatusChanged)

    def mavlinkLossPercent(self): return self._mavlinkLossPercent



    @Property(int, notify=mavlinkStatusChanged)

    def mavlinkSentCount(self): return self._mavlinkSentCount



    @Property(int, notify=mavlinkStatusChanged)

    def mavlinkReceivedCount(self): return self._mavlinkReceivedCount



    @Property(int, notify=mavlinkStatusChanged)

    def mavlinkLossCount(self): return self._mavlinkLossCount



    def get_coordinate(self): return self._coordinate

    def set_coordinate(self, c):

        if self._coordinate != c:

            self._coordinate = c

            self.coordinateChanged.emit()

    coordinate = Property(QGeoCoordinate, get_coordinate, set_coordinate, notify=coordinateChanged)



    @Property(QGeoCoordinate, notify=homePositionChanged)

    def homePosition(self): return self._homePosition



    @Slot(float)

    def guidedModeTakeoff(self, alt):

        self.set_flightMode("GUIDED")

        self.set_armed(True)

        self.altitudeRelative.set_val(alt)

        self.textMessageReceived.emit(self._id, 1, 6, f"Guided Takeoff executed -> Target: {alt:.1f}m", "")



    @Slot()

    def guidedModeLand(self):

        self.set_flightMode("LAND")

        self.textMessageReceived.emit(self._id, 1, 6, "Guided Land commanded at current position", "")



    @Slot(bool)

    def guidedModeRTL(self, smart):

        self.set_flightMode("RTL")

        self.textMessageReceived.emit(self._id, 1, 6, "RTL commanded -> Returning to Home Launch point", "")





class MockMultiVehicleManager(QObject):

    activeVehicleChanged = Signal(QObject)



    def __init__(self, veh):

        super().__init__()

        self._veh = veh



    @Property(QObject, notify=activeVehicleChanged)

    def activeVehicle(self):

        return self._veh





class MockVideoManager(QObject):

    decodingChanged = Signal()



    def __init__(self):

        super().__init__()

        self._decoding = False

        self._isUvc = False



    @Property(bool, notify=decodingChanged)

    def decoding(self): return self._decoding



    @Property(bool, constant=True)

    def isUvc(self): return self._isUvc



    @Property(bool, constant=True)

    def hasVideo(self): return False





class MockQGroundControl(QObject):

    def __init__(self, veh):

        super().__init__()

        self.multiVehicleManager = MockMultiVehicleManager(veh)

        self.videoManager = MockVideoManager()





# -----------------------------------------------------------------------------

# REAL MAVLINK UDP LISTENER THREAD

# -----------------------------------------------------------------------------

class MavlinkReceiverThread(threading.Thread):

    def __init__(self, vehicle):

        super().__init__(daemon=True)

        self.vehicle = vehicle

        self.running = True

        self.active_mav = None



    def process_message(self, msg, port_label):

        msg_type = msg.get_type()

        now = time.time()



        if msg_type == 'HEARTBEAT':

            is_armed = bool(msg.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED)

            mode_str = mavutil.mode_string_v10(msg)

            self.vehicle.set_armed(is_armed)

            self.vehicle.set_flightMode(mode_str)

            if self.vehicle._last_real_mavlink == 0.0 or now - self.vehicle._last_real_mavlink > 5.0:

                self.vehicle.textMessageReceived.emit(1, 1, 6, f"LIVE DRONE LINK ESTABLISHED via {port_label}", "")

            self.vehicle._last_real_mavlink = now

            self.vehicle._mavlinkReceivedCount += 1

        elif msg_type == 'ATTITUDE':

            self.vehicle.roll.set_val(math.degrees(msg.roll))

            self.vehicle.pitch.set_val(math.degrees(msg.pitch))

            self.vehicle.heading.set_val((math.degrees(msg.yaw) + 360) % 360)

            self.vehicle._last_real_mavlink = now

            self.vehicle._mavlinkReceivedCount += 1

        elif msg_type == 'VFR_HUD':

            self.vehicle.airSpeed.set_val(msg.airspeed)

            self.vehicle.groundSpeed.set_val(msg.groundspeed)

            self.vehicle.altitudeRelative.set_val(msg.alt)

            self.vehicle.climbRate.set_val(msg.climb)

            self.vehicle.throttlePct.set_val(msg.throttle)

            self.vehicle._last_real_mavlink = now

            self.vehicle._mavlinkReceivedCount += 1

        elif msg_type == 'SYS_STATUS':

            v_volts = msg.voltage_battery / 1000.0 if msg.voltage_battery != -1 else 0.0

            pct = msg.battery_remaining if msg.battery_remaining != -1 else 0

            if self.vehicle.batteries.count > 0:

                b = self.vehicle.batteries.get(0)

                b.voltage.set_val(v_volts)

                b.percentRemaining.set_val(pct)

            self.vehicle._sensorsHealthBits = msg.onboard_control_sensors_health

            self.vehicle.sensorsHealthBitsChanged.emit()

            self.vehicle._last_real_mavlink = now

            self.vehicle._mavlinkReceivedCount += 1

        elif msg_type == 'GPS_RAW_INT':

            self.vehicle.gps.count.set_val(msg.satellites_visible)

            fix_names = {0: "NO GPS", 1: "NO FIX", 2: "2D FIX", 3: "3D FIX", 4: "DGPS", 5: "RTK FLT", 6: "RTK FIX"}

            self.vehicle.gps.lock._enum_str = fix_names.get(msg.fix_type, "3D FIX")

            self.vehicle.gps.lock.valueChanged.emit()

            if msg.lat != 0 and msg.lon != 0:

                self.vehicle.set_coordinate(QGeoCoordinate(msg.lat / 1e7, msg.lon / 1e7, msg.alt / 1000.0))

            self.vehicle._last_real_mavlink = now

            self.vehicle._mavlinkReceivedCount += 1

        elif msg_type == 'GLOBAL_POSITION_INT':

            lat = msg.lat / 1e7

            lon = msg.lon / 1e7

            alt = msg.relative_alt / 1000.0

            self.vehicle.set_coordinate(QGeoCoordinate(lat, lon, alt))

            self.vehicle.altitudeRelative.set_val(alt)

            self.vehicle.heading.set_val((msg.hdg / 100.0) % 360.0)

            self.vehicle._last_real_mavlink = now

            self.vehicle._mavlinkReceivedCount += 1

        elif msg_type == 'HOME_POSITION':

            h_lat = msg.latitude / 1e7

            h_lon = msg.longitude / 1e7

            h_alt = msg.altitude / 1000.0

            self.vehicle._homePosition = QGeoCoordinate(h_lat, h_lon, h_alt)

            self.vehicle.homePositionChanged.emit()

        elif msg_type == 'STATUSTEXT':

            text = msg.text if isinstance(msg.text, str) else msg.text.decode('utf-8', errors='ignore')

            self.vehicle.textMessageReceived.emit(msg.get_srcSystem(), msg.get_srcComponent(), msg.severity, text, "")



    def _listen_udp(self):

        try:

            mav_udp = mavutil.mavlink_connection("udpin:0.0.0.0:14550")

            print("[MAVLINK] Listening on UDP 14550 (Wi-Fi / SITL / Companion PC)...")

            while self.running:

                msg = mav_udp.recv_match(blocking=True, timeout=1.0)

                if msg:

                    self.active_mav = mav_udp

                    self.process_message(msg, "UDP:14550")

        except Exception as e:

            print(f"[MAVLINK] UDP listener error: {e}")



    def _scan_serial(self):

        import serial.tools.list_ports

        known_connected = set()

        while self.running:

            try:

                ports = [p.device for p in serial.tools.list_ports.comports()]

                for port in ports:

                    if port not in known_connected:

                        # Try standard telemetry radio baud (57600) then direct USB (115200)

                        for baud in [57600, 115200]:

                            try:

                                mav_ser = mavutil.mavlink_connection(port, baud=baud, timeout=0.5)

                                msg = mav_ser.recv_match(blocking=True, timeout=1.5)

                                if msg:

                                    print(f"[MAVLINK] Real drone detected on {port} @ {baud} baud!")

                                    known_connected.add(port)

                                    self.active_mav = mav_ser

                                    while self.running:

                                        m = mav_ser.recv_match(blocking=True, timeout=1.0)

                                        if m:

                                            self.process_message(m, f"{port}@{baud}")

                                        elif time.time() - self.vehicle._last_real_mavlink > 3.0:

                                            break

                            except Exception:

                                pass

            except Exception:

                pass

            time.sleep(3.0)



    def run(self):

        if not HAS_PYMAVLINK:

            return

        t_udp = threading.Thread(target=self._listen_udp, daemon=True)

        t_udp.start()

        t_ser = threading.Thread(target=self._scan_serial, daemon=True)

        t_ser.start()

        t_udp.join()





# -----------------------------------------------------------------------------

# MAIN RUNNER

# -----------------------------------------------------------------------------

def main():

    app = QGuiApplication(sys.argv)

    app.setApplicationName("Aero-q-gcs")

    app.setOrganizationName("AeroQ")



    root_dir = Path(__file__).resolve().parent

    src_dir = root_dir / "src"

    mock_qml_dir = root_dir / "tools" / "mock_qml"



    veh = MockVehicle()

    qgc = MockQGroundControl(veh)



    # Start live MAVLink receiver in background

    mav_thread = MavlinkReceiverThread(veh)

    mav_thread.start()



    view = QQuickView()

    view.setTitle("Aero-q-gcs | Tactical Avionics & Defense Suite v2.4")

    view.setColor(QColor("#03060d"))

    view.resize(1340, 800)
    view.setResizeMode(QQuickView.ResizeMode.SizeRootObjectToView)



    engine = view.engine()

    engine.addImportPath(str(src_dir))

    engine.addImportPath(str(src_dir / "AeroQ"))

    engine.addImportPath(str(mock_qml_dir))



    context = view.rootContext()

    context.setContextProperty("QGroundControl", qgc)



    # Telemetry Simulator: Yields when real MAVLink packets arrive

    start_time = time.time()

    msg_counter = 0



    def on_tick():

        nonlocal msg_counter

        # If live MAVLink packets are arriving, do not overwrite with simulated physics

        if time.time() - veh._last_real_mavlink < 2.5:

            return



        t = time.time() - start_time

        new_pitch = 4.5 + 8.0 * math.sin(t * 0.7) + 2.0 * math.sin(t * 1.8)

        new_roll = 6.0 * math.sin(t * 0.5) + 8.0 * math.cos(t * 0.9)

        new_hdg = (45.0 + t * 4.0) % 360.0

        new_alt = 24.0 + 4.0 * math.sin(t * 0.3)

        new_climb = 0.8 * math.cos(t * 0.3)

        new_spd = 14.0 + 2.5 * math.sin(t * 0.4)



        veh.pitch.set_val(new_pitch)

        veh.roll.set_val(new_roll)

        veh.heading.set_val(new_hdg)

        veh.altitudeRelative.set_val(new_alt)

        veh.climbRate.set_val(new_climb)

        veh.groundSpeed.set_val(new_spd)

        veh.airSpeed.set_val(new_spd + 0.6)

        veh.throttlePct.set_val(48.0 + 6.0 * math.sin(t * 1.2))



        # Dynamic patrol coordinates around base station (Chennai 13.0827°N, 80.2707°E)

        sim_lat = 13.0827 + 0.0025 * math.sin(t * 0.08)

        sim_lon = 80.2707 + 0.0025 * math.cos(t * 0.08)

        veh.set_coordinate(QGeoCoordinate(sim_lat, sim_lon, new_alt))



        msg_counter += 1

        if msg_counter % 280 == 0:

            veh.textMessageReceived.emit(1, 1, 6, "EKF3 IMU0 primary lane healthy (0.18 pos var)", "")

        elif msg_counter % 520 == 0:

            veh.textMessageReceived.emit(1, 1, 6, "Nano² Mesh Link: 4/4 nodes sync verified (14ms)", "")



    timer = QTimer()

    timer.setInterval(25)  # 40 fps

    timer.timeout.connect(on_tick)

    timer.start()



    preview_qml = mock_qml_dir / "PreviewMain.qml"

    view.setSource(QUrl.fromLocalFile(str(preview_qml)))

    view.show()



    if "--test" in sys.argv:

        print("SIMULATION TEST INITIALIZED - Auto-quitting in 1.5 seconds...")

        QTimer.singleShot(1500, app.quit)



    sys.exit(app.exec())





if __name__ == "__main__":

    main()

