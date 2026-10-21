import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../components"
import "../services"

ColumnLayout {
    property bool active: false
    spacing: 10
    PageHeader { icon: "package"; title: "Update settings"; showBack: true; onBack: Shell.openPage("updates") }
    Flickable {
        id: scroll
        Layout.fillWidth: true
        implicitHeight: Math.min(settings.implicitHeight, 500)
        contentWidth: width
        contentHeight: settings.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        UpdateSettings { id: settings; width: scroll.width }
        Controls.ScrollBar.vertical: Controls.ScrollBar {}
    }
}
