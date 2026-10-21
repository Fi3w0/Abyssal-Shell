pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Window
import "kit"

Window {
    id: preview
    width: Number(argument("width", "1480"))
    height: Number(argument("height", "1000"))
    minimumWidth: 1000
    minimumHeight: 720
    visible: true
    title: "Abyssal · Trench / Violet"
    color: "#100c16"

    function argument(name, fallback) {
        const prefix = "--" + name + "=";
        const value = Qt.application.arguments.find(a => a.startsWith(prefix));
        return value ? value.slice(prefix.length) : fallback;
    }
    Component.onCompleted: Theme.monoLabels = argument("labels", "sans") === "mono"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 66
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 5
                Text {
                    text: "Abyssal / Trench · Violet"
                    color: "#f1eaf7"
                    font.family: "Noto Sans"
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: "One system: panels, launcher, controls, menus and notifications. Sample data only."
                    color: "#c3b2d2"
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
            Controls.Button {
                id: typography
                text: Theme.monoLabels ? "Labels: Mono" : "Labels: Sans + mono"
                implicitWidth: 176
                implicitHeight: 36
                hoverEnabled: true
                background: Rectangle {
                    color: typography.hovered ? "#3a2950" : "#291c3b"
                    radius: 6
                    border.width: 1
                    border.color: typography.activeFocus ? "#c5a5ef" : "#574067"
                }
                contentItem: Text {
                    text: typography.text
                    color: "#f1eaf7"
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: Theme.monoLabels = !Theme.monoLabels
            }
        }
        Item {
            id: viewport
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            Item {
                width: 1440
                height: 850
                anchors.centerIn: parent
                scale: Math.min(viewport.width / width, viewport.height / height)
                Rectangle {
                    anchors.fill: parent
                    color: Theme.current.bg
                }
                Image {
                    anchors.fill: parent
                    source: preview.argument("wallpaper", "")
                    fillMode: Image.PreserveAspectCrop
                    opacity: Theme.current.wallpaper
                    asynchronous: true
                }
                Violet {
                    anchors.fill: parent
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            Text {
                text: Theme.current.note
                color: "#c3b2d2"
                font.family: "Noto Sans"
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Controls.Button {
                id: reset
                text: "Reset samples"
                implicitHeight: 28
                background: Rectangle {
                    color: reset.hovered ? "#3a2950" : "#291c3b"
                    radius: 4
                    border.width: reset.activeFocus ? 1 : 0
                    border.color: "#c5a5ef"
                }
                contentItem: Text {
                    text: reset.text
                    color: "#f1eaf7"
                    font.family: "Noto Sans"
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }
                onClicked: Sample.reset()
            }
            Text {
                text: Sample.feedback
                color: "#c3b2d2"
                font.family: "Noto Sans"
                font.pixelSize: 11
                Layout.maximumWidth: preview.width * 0.38
                elide: Text.ElideRight
            }
        }
    }
    Timer {
        interval: 1000
        running: preview.argument("capture", "") !== ""
        onTriggered: preview.contentItem.grabToImage(function (result) {
            const ok = result.saveToFile(preview.argument("capture", ""));
            console.log(ok ? "Preview captured" : "Capture failed");
            Qt.exit(ok ? 0 : 1);
        })
    }
}
