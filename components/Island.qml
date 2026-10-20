import QtQuick
import "../services"

// Floating glass pill that holds one bar section in the islands style.
Rectangle {
    property bool highlighted: false

    radius: Math.min(width, height) / 2
    color: Theme.glass
    border.width: 1
    border.color: highlighted ? Theme.alpha(Theme.accent, 0.65) : Theme.hairline
    Behavior on border.color { ColorAnimation { duration: Theme.anim } }
}
