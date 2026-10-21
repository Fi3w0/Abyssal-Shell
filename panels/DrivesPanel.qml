import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"

// Removable drives (services/Drives.qml): each with its partitions, how
// full they are, Open (mounts first if needed) and Eject (unmounts all,
// then powers the drive off so it can be pulled out safely).
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 6

    onActiveChanged: if (active) Drives.refresh()

    PageHeader {
        icon: "usb"
        title: "Drives"
        showBack: root.showBack
        onBack: root.back()
    }

    Text {
        visible: Drives.count === 0
        Layout.fillWidth: true
        Layout.topMargin: 14
        Layout.bottomMargin: 14
        horizontalAlignment: Text.AlignHCenter
        text: "No removable drives connected"
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 12 }
    }

    Text {
        visible: Drives.error !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 6
        wrapMode: Text.Wrap
        text: Drives.error
        color: Theme.danger
        font { family: Theme.font; pixelSize: 11 }
    }

    Repeater {
        model: Drives.drives
        delegate: Rectangle {
            id: drive
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: col.implicitHeight + 20
            radius: Theme.controlRadius
            color: Theme.alpha(Theme.text, 0.04)
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        implicitWidth: 34; implicitHeight: 34; radius: 10
                        color: Theme.accentSoft
                        Icon { anchors.centerIn: parent; name: "usb"; size: 17; color: Theme.accent }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: drive.modelData.name
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13; bold: true }
                        }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: [Drives.size(drive.modelData.size), drive.modelData.model].filter(s => s && s !== drive.modelData.name).join(" · ")
                            color: Theme.overlay
                            font { family: Theme.font; pixelSize: 10 }
                        }
                    }
                    TextButton {
                        text: Drives.working === drive.modelData.path ? "Ejecting…" : "Eject"
                        icon: "eject"
                        onClicked: Drives.eject(drive.modelData)
                    }
                }

                Repeater {
                    model: drive.modelData.partitions
                    delegate: RowLayout {
                        id: part
                        required property var modelData
                        readonly property bool mounted: modelData.mounts.length > 0
                        readonly property real fill: mounted && modelData.used + modelData.avail > 0
                            ? modelData.used / (modelData.used + modelData.avail) : 0
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: (part.modelData.label || part.modelData.path.replace(/^.*\//, "")) + "  "
                                        + "<font color='" + Theme.overlay + "'>" + part.modelData.fstype + "</font>"
                                    textFormat: Text.StyledText
                                    color: Theme.subtext
                                    font { family: Theme.font; pixelSize: 11 }
                                }
                                Text {
                                    text: part.mounted ? Drives.size(part.modelData.avail) + " free" : Drives.size(part.modelData.size)
                                    color: Theme.overlay
                                    font { family: Theme.monoFont; pixelSize: 10 }
                                }
                            }
                            // How full, once mounted.
                            Rectangle {
                                visible: part.mounted
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Theme.alpha(Theme.text, 0.1)
                                Rectangle {
                                    width: parent.width * part.fill
                                    height: parent.height
                                    radius: 2
                                    color: part.fill > 0.9 ? Theme.warn : Theme.accent
                                }
                            }
                        }
                        BarButton {
                            icon: "folder"
                            iconSize: 15
                            implicitWidth: 28; implicitHeight: 28
                            iconColor: Theme.accent
                            onClicked: Drives.open(part.modelData)
                        }
                        BarButton {
                            visible: part.mounted
                            icon: "x"
                            iconSize: 13
                            implicitWidth: 28; implicitHeight: 28
                            onClicked: Drives.unmount(part.modelData)
                        }
                    }
                }
            }
        }
    }
}
