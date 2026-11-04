import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: window
    width: 1180
    height: 780
    minimumWidth: 720
    minimumHeight: 500
    visible: true
    title: backend.currentConversationId ? backend.currentTitle + " — SmolChat" : "SmolChat"
    color: Theme.bg

    property bool sidebarOpen: width > 900 || sidebarPinned
    property bool sidebarPinned: true

    Binding { target: Theme; property: "dark"; value: backend.theme !== "light" }

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd

    function openLibraryPanel() { openLibrary("all") }
    function openSettingsPanel() { settingsDialog.open() }

    function openLibrary(filter) {
        library.filter = filter || "all"
        library.open()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: window.sidebarPinned ? Theme.sidebarWidth : 0
            visible: Layout.preferredWidth > 0
            clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            onOpenLibrary: window.openLibrary("all")
            onOpenSettings: settingsDialog.open()
            onCollapse: window.sidebarPinned = false
        }

        ChatView {
            id: chat
            Layout.fillWidth: true
            Layout.fillHeight: true
            sidebarVisible: window.sidebarPinned
            onToggleSidebar: window.sidebarPinned = !window.sidebarPinned
            onOpenLibrary: (filter) => window.openLibrary(filter)
        }
    }

    ModelLibrary { id: library }
    SettingsDialog { id: settingsDialog; onOpenLibrary: window.openLibrary("all") }

    // Toast notifications
    Rectangle {
        id: toast
        property string kind: "info"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: visible ? 16 : -height
        width: Math.min(toastText.implicitWidth + 56, window.width - 80)
        height: Math.max(40, toastText.implicitHeight + 20)
        radius: 12
        color: Theme.popup
        border.color: kind === "error" ? Theme.danger : Theme.border
        visible: opacity > 0
        opacity: 0
        z: 50
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            C.Icon {
                name: toast.kind === "error" ? "alert" : "check"
                color: toast.kind === "error" ? Theme.danger : Theme.success
                size: 16
            }
            Text {
                id: toastText
                Layout.fillWidth: true
                color: Theme.text
                font.pixelSize: Theme.fontMd - 1
                wrapMode: Text.Wrap
            }
        }
        Timer { id: toastTimer; interval: 4200; onTriggered: toast.opacity = 0 }
        MouseArea { anchors.fill: parent; onClicked: toast.opacity = 0 }
    }

    Connections {
        target: backend
        function onToast(message, kind) {
            toastText.text = message
            toast.kind = kind
            toast.opacity = 1
            toastTimer.restart()
        }
    }

    // Keyboard shortcuts
    Shortcut { sequences: [StandardKey.New]; onActivated: backend.newChat() }
    Shortcut { sequence: "Ctrl+Shift+O"; onActivated: backend.newChat() }
    Shortcut { sequence: "Ctrl+K"; onActivated: { window.sidebarPinned = true; sidebar.focusSearch() } }
    Shortcut { sequence: "Ctrl+Shift+M"; onActivated: window.openLibrary("all") }
    Shortcut { sequences: [StandardKey.Preferences]; onActivated: settingsDialog.open() }
    Shortcut { sequence: "Ctrl+,"; onActivated: settingsDialog.open() }
    Shortcut { sequence: "Ctrl+\\"; onActivated: window.sidebarPinned = !window.sidebarPinned }
    Shortcut { sequence: "Ctrl+."; enabled: backend.isGenerating; onActivated: backend.stopGeneration() }

    // Splash overlay – sits above everything until initialisation finishes.
    Loader {
        id: splashLoader
        anchors.fill: parent
        z: 100
        sourceComponent: Splash {
            status: backend.initStatus
            finished: backend.ready
            onDismissed: splashLoader.active = false
        }
    }

    Component.onCompleted: backend.newChat()
}
