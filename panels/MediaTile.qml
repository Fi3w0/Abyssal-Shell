import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../components"
import "../services"

// Now playing, from any MPRIS player (Spotify, Firefox, mpv…): cover,
// title, artist, previous / play-pause / next, and a seek bar in the full
// size. The playing player wins; with several, the arrows switch between
// them. Compact (2×2) drops the seek bar.
Item {
    id: root

    property bool compact: false
    property bool active: true

    readonly property var players: Mpris.players.values
    // Player picked with the arrows; otherwise the one playing.
    property var chosen: null
    readonly property var player: chosen && players.includes(chosen) ? chosen
        : players.find(p => p.isPlaying) ?? players[0] ?? null

    // MPRIS does not push position updates; ask for them while visible.
    Timer {
        running: root.active && !root.compact && root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // The player's own cover, else a YouTube thumbnail from the video's
    // URL (Firefox sends the URL over MPRIS but no artwork).
    readonly property string videoId: {
        if (!player || player.trackArtUrl) return ""
        const url = String((player.metadata || {})["xesam:url"] || "")
        const m = url.match(/(?:youtube\.com\/(?:watch\?(?:.*&)?v=|shorts\/|embed\/)|youtu\.be\/)([\w-]{11})/)
        return m ? m[1] : ""
    }
    readonly property string artUrl: !player ? "" : player.trackArtUrl
        || (videoId ? "https://i.ytimg.com/vi/" + videoId + "/mqdefault.jpg" : "")

    function fmt(s) {
        s = Math.max(0, Math.floor(s))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
    function cycle() {
        if (players.length < 2) return
        chosen = players[(players.indexOf(player) + 1) % players.length]
    }

    Text {
        visible: root.player === null
        anchors.centerIn: parent
        text: "Nothing playing"
        color: Theme.overlay
        font { family: Theme.font; pixelSize: 11 }
    }

    ColumnLayout {
        visible: root.player !== null
        anchors { fill: parent; margins: 12 }
        spacing: root.compact ? 8 : 10

        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            ClippingRectangle {
                // Video thumbnails are 16:9; covers are square.
                implicitHeight: root.compact ? 38 : 50
                implicitWidth: root.videoId ? Math.round(implicitHeight * 16 / 9) : implicitHeight
                radius: 10
                color: Theme.surface1
                border.width: 1
                border.color: Theme.hairline
                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    sourceSize.width: 160
                    sourceSize.height: 160
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Icon {
                    anchors.centerIn: parent
                    visible: !root.artUrl
                    name: "volume-high"
                    size: 16
                    color: Theme.overlay
                }
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    visible: !root.compact
                    text: root.player ? root.player.identity.toUpperCase() : ""
                    color: Theme.overlay
                    font { family: Theme.font; pixelSize: 9; letterSpacing: 1.5 }
                }
                Text {
                    text: root.player ? (root.player.trackTitle || "Unknown title") : ""
                    color: Theme.text
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
                    Layout.fillWidth: true
                }
                Text {
                    text: root.player ? (root.player.trackArtist || "") : ""
                    color: Theme.subtext
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: 11 }
                    Layout.fillWidth: true
                }
            }
            BarButton {
                visible: root.players.length > 1 && !root.compact
                implicitWidth: 24
                implicitHeight: 24
                icon: "arrows"
                iconSize: 12
                onClicked: root.cycle()
            }
        }

        RowLayout {
            spacing: 6
            Layout.fillWidth: true

            BarButton {
                implicitWidth: 26; implicitHeight: 26
                icon: "chevron-left"
                iconSize: 13
                enabled: root.player !== null && root.player.canGoPrevious
                opacity: enabled ? 1 : 0.35
                onClicked: root.player.previous()
            }
            BarButton {
                implicitWidth: 30; implicitHeight: 30
                icon: root.player && root.player.isPlaying ? "pause" : "play"
                iconSize: 15
                iconColor: Theme.text
                onClicked: root.player.togglePlaying()
            }
            BarButton {
                implicitWidth: 26; implicitHeight: 26
                icon: "chevron-right"
                iconSize: 13
                enabled: root.player !== null && root.player.canGoNext
                opacity: enabled ? 1 : 0.35
                onClicked: root.player.next()
            }

            Text {
                visible: !root.compact && root.player !== null && root.player.lengthSupported
                text: root.player ? root.fmt(root.player.position) : ""
                color: Theme.overlay
                font { family: Theme.font; pixelSize: 10 }
                Layout.leftMargin: 4
            }
            Item {
                visible: !root.compact
                Layout.fillWidth: true
                implicitHeight: 14
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 2
                    radius: 1
                    color: Theme.alpha(Theme.text, 0.10)
                    Rectangle {
                        height: parent.height
                        radius: 1
                        color: Theme.text
                        width: root.player && root.player.length > 0
                               ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.player !== null && root.player.canSeek && root.player.length > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: mouse => root.player.position = root.player.length * (mouse.x / width)
                }
            }
            Text {
                visible: !root.compact && root.player !== null && root.player.lengthSupported
                text: root.player ? root.fmt(root.player.length) : ""
                color: Theme.overlay
                font { family: Theme.font; pixelSize: 10 }
            }
            Item { visible: root.compact; Layout.fillWidth: true }
        }
    }
}
