import QtQuick
import QtQuick.Layouts

Pane {
    id: notice
    property bool stripe: true
    visible: Sample.notification
    height: 100
    Rectangle {
        visible: notice.stripe
        width: 3
        height: parent.height - 24
        x: 0
        y: 12
        color: Theme.current.accent
    }
    RowLayout {
        anchors {
            fill: parent
            margins: 18
        }
        spacing: 14
        Glyph {
            name: "bell"
            tint: Theme.current.accent
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7
            Label {
                text: "Screenshot saved"
                font.pixelSize: 16
                Layout.fillWidth: true
            }
            Label {
                text: "Sample notification · Pictures/Screenshots"
                color: Theme.current.muted
                font.pixelSize: 11
                Layout.fillWidth: true
            }
        }
        Action {
            text: "×"
            implicitWidth: 28
            Accessible.name: "Dismiss sample notification"
            onClicked: Sample.notification = false
        }
    }
}
