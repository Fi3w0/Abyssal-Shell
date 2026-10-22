import QtQuick

// Notification images can be sender portraits or content attachments. Messaging
// categories identify portraits; small square images are also icon-sized.
Image {
    id: root
    property string category: ""
    readonly property bool compact: status === Image.Ready &&
        (/^(im\.|presence\.|email\.arrived$|x-.*\.im\.)/.test(category) ||
         (implicitWidth > 0 && implicitWidth <= 128 && implicitHeight > 0 &&
          implicitHeight <= 128 && Math.abs(implicitWidth - implicitHeight) <= 2))
    function previewHeight(availableWidth, maximumHeight) {
        if (status !== Image.Ready || compact || implicitWidth <= 0) return 0;
        return Math.max(0, Math.min(maximumHeight, implicitHeight,
                                   availableWidth * implicitHeight / implicitWidth));
    }
    // Keep the native dimensions: requesting a larger provider size can upscale
    // a tiny image before we have a chance to classify it or limit its display.
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
}
