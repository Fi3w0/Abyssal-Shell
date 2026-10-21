import QtQuick
import QtMultimedia

// The wallpaper picker's live preview of the selected video, muted and
// looping. Its own file, loaded by a Loader: without Qt Multimedia the
// Loader fails and the picker keeps showing the thumbnail.
Item {
    id: root

    property string path: ""

    MediaPlayer {
        id: player
        source: root.path ? "file://" + root.path : ""
        loops: MediaPlayer.Infinite
        videoOutput: out
        onSourceChanged: if (source != "") play()
    }
    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        // Fade in once frames arrive, over the thumbnail.
        opacity: player.playbackState === MediaPlayer.PlayingState && player.position > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 260 } }
    }
}
