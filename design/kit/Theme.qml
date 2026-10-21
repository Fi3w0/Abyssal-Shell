pragma Singleton
import QtQml

QtObject {
    property bool monoLabels: false
    readonly property var current: ({
            name: "Trench / Violet",
            note: "Dark amethyst · softened equipment frames · native application icons",
            font: monoLabels ? "JetBrains Mono" : "Noto Sans",
            display: "Noto Sans",
            bg: "#0e0917",
            panel: "#1b1328",
            panelBottom: "#171020",
            title: "#291c3b",
            inset: "#120d1c",
            raised: "#30213f",
            control: "#342447",
            controlEdge: "#604678",
            hover: "#3a2950",
            line: "#574067",
            text: "#f1eaf7",
            muted: "#c3b2d2",
            accent: "#c5a5ef",
            ink: "#21132f",
            selected: "#46305f",
            danger: "#e9a4bc",
            highlight: "#7e5a9d",
            radius: 10,
            wallpaper: 0.3
        })
}
