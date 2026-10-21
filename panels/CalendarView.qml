import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

// Large time and date over a month grid (weeks start on Monday). The
// arrows page through months, "Today" comes back; today has a violet ring.
// Paging slides the grid out and the new month in from that side; the days
// rise into place when the panel opens.
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 2

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // First day of the month shown.
    property date month: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    onActiveChanged: if (active) {
        month = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
        enter.restart()
    }

    function shift(n) {
        goTo(new Date(month.getFullYear(), month.getMonth() + n, 1))
    }
    function goTo(target) {
        if (target.getTime() === month.getTime()) return
        pending = target
        dir = target > month ? 1 : -1
        page.restart()
    }

    property date pending: month
    property int dir: 1

    // Out toward the side we leave, swap the month, in from the other side.
    SequentialAnimation {
        id: page
        ParallelAnimation {
            NumberAnimation { target: slide; property: "x"; to: -root.dir * 22; duration: 110; easing.type: Easing.InCubic }
            NumberAnimation { targets: [days, title]; property: "opacity"; to: 0; duration: 110 }
        }
        ScriptAction { script: { root.month = root.pending; slide.x = root.dir * 22 } }
        ParallelAnimation {
            NumberAnimation { target: slide; property: "x"; to: 0; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { targets: [days, title]; property: "opacity"; to: 1; duration: 200 }
        }
    }
    // Opening: the grid rises and fades in.
    ParallelAnimation {
        id: enter
        NumberAnimation { target: slide; property: "y"; from: 8; to: 0; duration: 320; easing.type: Easing.OutCubic }
        NumberAnimation { target: days; property: "opacity"; from: 0; to: 1; duration: 260 }
    }

    // 42 cells: the days around this month fill the first and last weeks.
    readonly property var cells: {
        const y = month.getFullYear(), m = month.getMonth()
        const lead = (new Date(y, m, 1).getDay() + 6) % 7
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, 1 - lead + i)
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === m,
                weekend: i % 7 >= 5,
                today: d.toDateString() === clock.date.toDateString()
            })
        }
        return out
    }
    readonly property bool onToday: month.getFullYear() === clock.date.getFullYear() && month.getMonth() === clock.date.getMonth()

    Text {
        text: Qt.formatDateTime(clock.date, "hh:mm")
        color: Theme.text
        font { family: Theme.font; pixelSize: 34; weight: Font.Light; letterSpacing: -1 }
        Layout.leftMargin: 2
    }
    Text {
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 11 }
        Layout.leftMargin: 2
        Layout.bottomMargin: 12
    }

    RowLayout {
        spacing: 4
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        Text {
            id: title
            text: Qt.formatDateTime(root.month, "MMMM yyyy")
            color: Theme.text
            font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
            Layout.fillWidth: true
            Layout.leftMargin: 2
        }
        BarButton { implicitWidth: 26; implicitHeight: 26; icon: "chevron-left"; iconSize: 13; onClicked: root.shift(-1) }
        TextButton { visible: !root.onToday; text: "Today"; onClicked: root.goTo(new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)) }
        BarButton { implicitWidth: 26; implicitHeight: 26; icon: "chevron-right"; iconSize: 13; onClicked: root.shift(1) }
    }

    GridLayout {
        columns: 7
        columnSpacing: 0
        Layout.fillWidth: true

        Repeater {
            model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
            Text {
                required property string modelData
                text: modelData
                color: Theme.overlay
                horizontalAlignment: Text.AlignHCenter
                font { family: Theme.font; pixelSize: 9; letterSpacing: 1 }
                Layout.fillWidth: true
                Layout.bottomMargin: 4
            }
        }
    }

    GridLayout {
        id: days
        columns: 7
        rowSpacing: 2
        columnSpacing: 0
        Layout.fillWidth: true
        transform: Translate { id: slide }

        Repeater {
            model: root.cells
            Item {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 32
                Rectangle {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    radius: 15
                    color: modelData.today ? Theme.alpha(Theme.accent, 0.16) : dayArea.containsMouse ? Theme.alpha(Theme.text, 0.05) : "transparent"
                    border.width: modelData.today ? 1 : 0
                    border.color: Theme.alpha(Theme.accent, 0.75)
                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: modelData.today ? Theme.text
                             : !modelData.inMonth ? Theme.alpha(Theme.overlay, 0.6)
                             : modelData.weekend ? Theme.text : Theme.subtext
                        font { family: Theme.font; pixelSize: 11; weight: modelData.today ? Font.DemiBold : Font.Normal }
                    }
                    MouseArea { id: dayArea; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }
}
