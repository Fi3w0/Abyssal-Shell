import QtQuick
import QtTest
import "../../components"

Item {
    width: 400; height: 240
    NotificationPicture { id: picture; width: 36; height: 36 }
    TestCase {
        name: "NotificationImages"
        when: windowShown
        function image(width, height) {
            picture.source = "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="'+width+'" height="'+height+'"><rect width="100%" height="100%" fill="teal"/></svg>');
            tryCompare(picture, "status", Image.Ready);
        }
        function init() { picture.category = ""; picture.source = ""; }
        function test_smallSquareIsCompactWithoutAppNameRules() {
            image(64,64);
            verify(picture.compact);
            compare(picture.previewHeight(240,150),0);
        }
        function test_chatPortraitIsCompactAtHighResolution() {
            picture.category = "im.received";
            image(512,512);
            verify(picture.compact);
            compare(picture.previewHeight(240,150),0);
        }
        function test_contentImageStaysAPreview() {
            image(800,600);
            verify(!picture.compact);
            compare(picture.previewHeight(240,150),150);
        }
        function test_smallNonSquareAttachmentIsNeverUpscaled() {
            image(80,40);
            verify(!picture.compact);
            compare(picture.previewHeight(240,150),40);
            compare(picture.previewHeight(40,150),20);
        }
        function test_largeSquareAttachmentStaysAPreview() {
            image(512,512);
            verify(!picture.compact);
            compare(picture.previewHeight(240,150),150);
        }
        function test_noImageReservesNoSpace() {
            compare(picture.status,Image.Null);
            verify(!picture.compact);
            compare(picture.previewHeight(240,150),0);
        }
    }
}
