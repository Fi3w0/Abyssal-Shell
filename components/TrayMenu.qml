import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services"

// A tray item's DBus menu in Abyssal style. Submenus drill down in place
// with a Back row. grabFocus closes it when you click anywhere else.
PopupWindow {
    id: pop

    required property var handle

    property var stack: []
    property var current: handle
    function enter(h) { stack = stack.concat([h]); current = h }
    function back() { stack = stack.slice(0, -1); current = stack.length ? stack[stack.length - 1] : pop.handle }
    onVisibleChanged: if (!visible) { stack = []; current = pop.handle }

    grabFocus: true
    implicitWidth: 248
    implicitHeight: bg.implicitHeight
    color: "transparent"

    QsMenuOpener { id: opener; menu: pop.current }

    Rectangle {
        id: bg
        anchors.fill: parent
        implicitHeight: col.implicitHeight + 12
        radius: 14
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.10)

        Column {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 6 }
            spacing: 1

            MenuRow {
                visible: pop.stack.length > 0
                leading: "chevron-left"
                leadingColor: Theme.accent
                label: "Back"
                labelColor: Theme.subtext
                onActivated: pop.back()
            }

            Repeater {
                model: opener.children

                delegate: Item {
                    id: row
                    required property var modelData
                    width: col.width
                    height: modelData.isSeparator ? 9 : 32

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 14
                        height: 1
                        color: Theme.alpha(Theme.text, 0.10)
                    }

                    MenuRow {
                        visible: !row.modelData.isSeparator
                        enabled: row.modelData.enabled
                        leading: row.modelData.buttonType !== 0 ? (row.modelData.checkState !== 0 ? "check" : "square") : ""
                        leadingColor: Theme.success
                        iconSource: row.modelData.buttonType === 0 ? row.modelData.icon : ""
                        label: (row.modelData.text || "").replace(/_(.)/g, "$1")
                        trailing: row.modelData.hasChildren ? "chevron-right" : ""
                        onActivated: {
                            if (row.modelData.hasChildren) {
                                pop.enter(row.modelData)
                            } else {
                                row.modelData.triggered()
                                pop.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    component MenuRow: Rectangle {
        id: mr
        property string leading: ""
        property color  leadingColor: Theme.subtext
        property string iconSource: ""
        property string label: ""
        property color  labelColor: Theme.text
        property string trailing: ""
        signal activated()

        width: col.width
        height: 32
        radius: 8
        color: ma.containsMouse && enabled ? Theme.alpha(Theme.accent, 0.18) : "transparent"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 9

            Item {
                width: 16
                height: parent.height
                Icon {
                    anchors.centerIn: parent
                    visible: mr.leading !== ""
                    name: mr.leading
                    size: 14
                    color: mr.leadingColor
                }
                HiDpiIcon {
                    anchors.centerIn: parent
                    visible: mr.leading === "" && mr.iconSource !== ""
                    implicitSize: 16
                    source: mr.iconSource
                }
            }

            Text {
                width: parent.width - 16 - 9 - (mr.trailing !== "" ? 23 : 0)
                anchors.verticalCenter: parent.verticalCenter
                text: mr.label
                color: mr.enabled ? mr.labelColor : Theme.overlay
                font { family: Theme.font; pixelSize: 12 }
                elide: Text.ElideRight
            }

            Icon {
                visible: mr.trailing !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: mr.trailing
                size: 13
                color: Theme.subtext
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            enabled: mr.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: mr.activated()
        }
    }
}
