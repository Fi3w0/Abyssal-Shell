pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Machine-wide stats, polled once for every bar on every monitor.
Singleton {
    id: root

    property int    cpuPct: 0
    property var    cpuHistory: []
    property int    ramUsedMb: 0
    property int    ramTotalMb: 1
    property real   cpuTemp: 0
    property string netType: ""        // "wifi" | "ethernet" | ""
    property string netName: ""
    property int    wifiSignal: 0
    property bool   recording: false
    property bool   hasBacklight: false

    // Laptop-only widgets hide themselves when this is false.
    readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
    readonly property int  batteryPct: Math.round(UPower.displayDevice.percentage * 100)
    readonly property bool charging:   UPower.displayDevice.state === UPowerDeviceState.Charging
                                    || UPower.displayDevice.state === UPowerDeviceState.FullyCharged

    property var _prevCpu: []

    Process {
        id: cpuProc
        command: ["awk", "/^cpu /{print $2,$3,$4,$5,$6,$7,$8}", "/proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                const f = data.trim().split(" ").map(Number)
                if (root._prevCpu.length === 7) {
                    const total = f.reduce((a, b) => a + b, 0)
                    const pTotal = root._prevCpu.reduce((a, b) => a + b, 0)
                    const dt = total - pTotal
                    root.cpuPct = dt > 0 ? Math.round((1 - (f[3] - root._prevCpu[3]) / dt) * 100) : 0
                    const hist = root.cpuHistory.slice()
                    hist.push(root.cpuPct)
                    if (hist.length > 40) hist.shift()
                    root.cpuHistory = hist
                }
                root._prevCpu = f
            }
        }
    }

    Process {
        id: ramProc
        command: ["awk", "/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{print int((t-a)/1024), int(t/1024)}", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(" ")
                root.ramUsedMb = parseInt(p[0]) || 0
                root.ramTotalMb = parseInt(p[1]) || 1
            }
        }
    }

    // CPU temperature straight from sysfs: hwmon by chip name first (hwmonN
    // is not stable across boots), then CPU-looking thermal zones.
    Process {
        id: tempProc
        command: ["sh", "-c", 'for n in k10temp coretemp cpu_thermal soc_thermal thinkpad acpitz; do for h in /sys/class/hwmon/*; do read -r hn < "$h/name" 2>/dev/null || continue; [ "$hn" = "$n" ] || continue; read -r t < "$h/temp1_input" 2>/dev/null || continue; [ -n "$t" ] && [ "$t" -gt 0 ] && { echo $((t/1000)); exit 0; }; done; done; for z in /sys/class/thermal/thermal_zone*; do read -r ty < "$z/type" 2>/dev/null || continue; case "$ty" in x86_pkg_temp|*cpu*|*CPU*|*pkg*|*soc*) read -r t < "$z/temp" 2>/dev/null || continue; [ -n "$t" ] && [ "$t" -gt 0 ] && { echo $((t/1000)); exit 0; }; ;; esac; done']
        stdout: SplitParser {
            onRead: data => { const v = parseFloat(data); if (v > 0) root.cpuTemp = v }
        }
    }

    Process {
        id: wifiSigProc
        command: ["awk", "NR==3{gsub(/\\./,\"\",$3); v=int($3*100/70); print (v>100?100:v)}", "/proc/net/wireless"]
        stdout: SplitParser { onRead: data => root.wifiSignal = parseInt(data) || 0 }
    }

    // First connected wifi/ethernet device and its connection name.
    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let type = "", name = ""
                for (const line of text.split("\n")) {
                    const p = line.split(":")
                    if (p.length < 3 || p[1] !== "connected") continue
                    if (p[0] === "wifi" || p[0] === "ethernet") { type = p[0]; name = p.slice(2).join(":"); break }
                }
                root.netType = type
                root.netName = name
            }
        }
    }

    // Wi-Fi radio switch (nmcli), for the quick settings toggle.
    property bool wifiEnabled: true
    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiEnabled = text.trim() === "enabled" }
    }
    Process {
        id: radioSet
        onExited: { radioProc.running = true; netProc.running = true }
    }
    function setWifi(on) {
        wifiEnabled = on
        radioSet.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]
        radioSet.running = true
    }

    property real uptimeSec: 0
    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector { onStreamFinished: root.uptimeSec = parseFloat(text) || 0 }
    }
    function refreshUptime() {
        uptimeProc.running = true
    }

    Process {
        id: recProc
        command: ["sh", "-c", "pgrep -x 'obs|wf-recorder|gpu-screen-recorder|kooha|simplescreenrecorder' >/dev/null && echo 1 || echo 0"]
        stdout: SplitParser { onRead: data => root.recording = data.trim() === "1" }
    }

    Process {
        id: backlightProc
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector { onStreamFinished: root.hasBacklight = text.trim() !== "" }
    }

    function refreshFast() {
        cpuProc.running = true
        ramProc.running = true
        tempProc.running = true
        if (netType === "wifi") wifiSigProc.running = true
    }

    function refresh() {
        refreshFast()
        netProc.running = true
        recProc.running = true
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refreshFast() }
    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { netProc.running = true; recProc.running = true; radioProc.running = true }
    }

    // QML timers pause during suspend; a big wall-clock jump means we just
    // woke up, so refresh everything at once.
    Timer {
        property double last: Date.now()
        interval: 30000; running: true; repeat: true
        onTriggered: {
            const now = Date.now()
            if (now - last > interval * 3) root.refresh()
            last = now
        }
    }

    Component.onCompleted: backlightProc.running = true
}
