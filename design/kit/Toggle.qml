import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Controls.Button {
    id: toggle
    property string detail: ""
    property string glyph: ""
    property string treatment: "text"
    implicitHeight: 55
    checkable: true
    focusPolicy: Qt.StrongFocus
    padding: 8
    hoverEnabled: true
    background: Rectangle {
        color: toggle.hovered ? Theme.current.raised : "transparent"
        radius: Theme.current.radius / 2
        border.width: toggle.activeFocus ? 1 : 0
        border.color: Theme.current.accent
    }
    contentItem: RowLayout {
        spacing: 12
        Glyph {
            visible: toggle.glyph !== ""
            name: toggle.glyph
            tint: toggle.checked ? Theme.current.accent : Theme.current.muted
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Label {
                text: toggle.text
                font.pixelSize: 14
                Layout.fillWidth: true
            }
            Label {
                visible: toggle.detail !== ""
                text: toggle.detail
                color: Theme.current.muted
                font.pixelSize: 11
                Layout.fillWidth: true
            }
        }
        Label {
            visible: toggle.treatment === "text"
            text: toggle.checked ? "ON" : "OFF"
            font.pixelSize: 11
            color: toggle.checked ? Theme.current.accent : Theme.current.muted
        }
        Rectangle {
            visible: toggle.treatment === "square"
            implicitWidth: 19
            implicitHeight: 19
            color: toggle.checked ? Theme.current.accent : "transparent"
            border.width: 1
            border.color: Theme.current.accent
            Label {
                anchors.centerIn: parent
                text: toggle.checked ? "+" : ""
                color: Theme.current.ink
                font.pixelSize: 17
            }
        }
        Rectangle {
            visible: toggle.treatment === "switch"
            implicitWidth: 30
            implicitHeight: 16
            radius: 8
            color: toggle.checked ? Theme.current.accent : Theme.current.line
            Rectangle {
                x: toggle.checked ? 17 : 3
                y: 3
                width: 10
                height: 10
                radius: 5
                color: Theme.current.ink
            }
        }
    }
}
