import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string documentId
    property var fields: []
    property int revision: 0
    Connections {
        target: Store
        function onChanged() {
            root.revision++;
        }
    }
    spacing: 22
    Repeater {
        model: root.fields
        Field {
            required property var modelData
            title: modelData.title
            hint: modelData.hint || ""
            kind: modelData.kind || "text"
            minimum: modelData.min || 0
            maximum: modelData.max || 100
            choices: modelData.choices || []
            value: {
                root.revision;
                return Store.value(root.documentId, modelData.key, modelData.fallback === undefined ? "" : modelData.fallback);
            }
            onEdited: next => {
                Store.setValue(root.documentId, modelData.key, next);
                if (root.documentId === "wallpaper") {
                    if (modelData.key === "transitionPreset" && next) {
                        const recipe = Store.transitions()[next];
                        if (recipe) {
                            Store.setValue("wallpaper", "transition", recipe.type);
                            Store.setValue("wallpaper", "transitionDuration", recipe.duration);
                        }
                    } else if (modelData.key === "transition")
                        Store.setValue("wallpaper", "transitionPreset", "");
                }
            }
        }
    }
}
