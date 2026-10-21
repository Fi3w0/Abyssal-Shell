import QtQuick
import QtQuick.Layouts
import "../services"

// The clock's panel: notifications on the left, the calendar on the right.
RowLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 18

    NotificationList {
        active: root.active
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
    Rectangle {
        implicitWidth: 1
        Layout.fillHeight: true
        color: Theme.hairline
    }
    CalendarView {
        active: root.active
        Layout.preferredWidth: 280
        Layout.alignment: Qt.AlignTop
    }
}
