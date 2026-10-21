import QtQuick
import QtQuick.Controls as Controls

Controls.TextField {
    id: search
    implicitHeight: 50
    placeholderText: "Search applications"
    text: Sample.query
    color: Theme.current.text
    placeholderTextColor: Theme.current.muted
    selectionColor: Theme.current.accent
    selectedTextColor: Theme.current.ink
    font.family: Theme.current.font
    font.pixelSize: 21
    leftPadding: 16
    rightPadding: 16
    background: Rectangle {
        color: "transparent"
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: search.activeFocus ? 2 : 1
            color: search.activeFocus ? Theme.current.accent : Theme.current.line
        }
    }
    Accessible.name: "Search sample applications"
    onTextEdited: {
        Sample.query = text;
        Sample.selected = 0;
    }
    Keys.onDownPressed: Sample.selected = Math.min(Math.max(0, Sample.matches.length - 1), Sample.selected + 1)
    Keys.onUpPressed: Sample.selected = Math.max(0, Sample.selected - 1)
    Keys.onReturnPressed: Sample.pick(Sample.selected)
    Keys.onEnterPressed: Sample.pick(Sample.selected)
    Keys.onEscapePressed: Sample.query = ""
}
