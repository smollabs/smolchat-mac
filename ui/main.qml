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
    // The title bar is transparent and our own UI shows the app name, so keep
    // the native title text empty (it would collide with the traffic lights).
    title: ""
    color: Theme.frame
    // Native macOS look: content extends under a transparent title bar, the
    // traffic lights float over the sidebar.
    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    // We lay out around the title bar ourselves (Theme.titleBarHeight), so
    // opt out of the automatic safe-area padding.
    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0

    menuBar: MenuBar {
        Menu {
            title: qsTr("&File")
            Action {
                text: qsTr("New Chat")
                shortcut: StandardKey.New
                onTriggered: backend.newChat()
            }
            MenuSeparator {}
            Action {
                text: qsTr("Close Window")
                shortcut: StandardKey.Close
                onTriggered: window.close()
            }
        }

        Menu {
            title: qsTr("&Edit")
            Action {
                text: qsTr("Undo")
                shortcut: StandardKey.Undo
                onTriggered: {
                    var item = window.activeFocusItem
                    if (item && typeof item.undo === "function") item.undo()
                }
            }
            Action {
                text: qsTr("Redo")
                shortcut: StandardKey.Redo
                onTriggered: {
                    var item = window.activeFocusItem
                    if (item && typeof item.redo === "function") item.redo()
                }
            }
            MenuSeparator {}
            Action {
                text: qsTr("Cut")
                shortcut: StandardKey.Cut
                onTriggered: {
                    var item = window.activeFocusItem
                    if (item && typeof item.cut === "function") item.cut()
                }
            }
            Action {
                text: qsTr("Copy")
                shortcut: StandardKey.Copy
                onTriggered: {
                    var item = window.activeFocusItem
                    if (item && typeof item.copy === "function") item.copy()
                }
            }
            Action {
                text: qsTr("Paste")
                shortcut: StandardKey.Paste
                onTriggered: {
                    var item = window.activeFocusItem
                    if (item && typeof item.paste === "function") item.paste()
                }
            }
            Action {
                text: qsTr("Select All")
                shortcut: StandardKey.SelectAll
                onTriggered: {
                    var item = window.activeFocusItem
                    if (item && typeof item.selectAll === "function") item.selectAll()
                }
            }
        }

        Menu {
            title: qsTr("&View")
            Action {
                text: window.sidebarPinned ? qsTr("Hide Sidebar") : qsTr("Show Sidebar")
                shortcut: "Ctrl+\\"
                onTriggered: window.sidebarPinned = !window.sidebarPinned
            }
            Action {
                text: qsTr("Search Chats…")
                shortcut: "Ctrl+K"
                onTriggered: { window.sidebarPinned = true; sidebar.focusSearch() }
            }
            MenuSeparator {}
            Action {
                text: qsTr("Model Library…")
                shortcut: "Ctrl+Shift+M"
                onTriggered: window.openLibrary("all")
            }
            Action {
                text: qsTr("Settings…")
                shortcut: StandardKey.Preferences
                onTriggered: settingsDialog.open()
            }
            MenuSeparator {}
            Action {
                text: Theme.dark ? qsTr("Switch to Light Mode") : qsTr("Switch to Dark Mode")
                shortcut: "Ctrl+Shift+L"
                onTriggered: window.setAppearance("theme", Theme.dark ? "light" : "dark")
            }
        }

        Menu {
            title: qsTr("&Window")
            Action {
                text: qsTr("Minimize")
                shortcut: "Ctrl+M"
                onTriggered: window.showMinimized()
            }
            Action {
                text: qsTr("Zoom")
                onTriggered: window.toggleZoom()
            }
        }

        Menu {
            title: qsTr("&Help")
            Action {
                text: qsTr("SmolChat Documentation")
                onTriggered: Qt.openUrlExternally("https://github.com/smollabs/smolchat-mac#readme")
            }
            Action {
                text: qsTr("Report an Issue…")
                onTriggered: Qt.openUrlExternally("https://github.com/smollabs/smolchat-mac/issues")
            }
        }
    }

    property bool sidebarPinned: true

    Binding {
        target: Theme
        property: "dark"
        value: backend.theme === "system"
               ? Application.styleHints.colorScheme !== Qt.ColorScheme.Light
               : backend.theme !== "light"
    }
    Binding { target: Theme; property: "accentName"; value: backend.accent }

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontMd

    function openLibraryPanel() { openLibrary("all") }
    function openSettingsPanel() { settingsDialog.open() }

    function openLibrary(filter) {
        library.filter = filter || "all"
        library.open()
    }

    // Change a setting that affects appearance with a smooth crossfade:
    // snapshot the window, apply the change underneath, fade the snapshot out.
    function setAppearance(key, value) {
        const shot = fader.running ? "" : backend.snapshotWindow(window)
        if (shot) {
            fader.source = shot
            fader.opacity = 1
        }
        backend.setSetting(key, value)
        if (shot) fader.fadeOut()
    }

    // Window dragging / zoom for the transparent title bar region.
    function startDrag() { window.startSystemMove() }
    function toggleZoom() {
        window.visibility === Window.Maximized ? window.showNormal() : window.showMaximized()
    }

    Item {
        id: shell
        anchors.fill: parent
        opacity: 0
        scale: 0.985

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
                onToggleTheme: window.setAppearance("theme", Theme.dark ? "light" : "dark")
            }

            // The stage floats as a rounded, glossy panel inside the dark frame.
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ChatView {
                    id: chat
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    anchors.rightMargin: 8
                    anchors.leftMargin: window.sidebarPinned ? 0 : 8
                    Behavior on anchors.leftMargin { NumberAnimation { duration: Theme.normal } }
                    sidebarVisible: window.sidebarPinned
                    onToggleSidebar: window.sidebarPinned = !window.sidebarPinned
                    onOpenLibrary: (filter) => window.openLibrary(filter)
                    onOpenSettings: settingsDialog.open()
                }
            }
        }

        ParallelAnimation {
            id: reveal
            NumberAnimation { target: shell; property: "opacity"; to: 1; duration: Theme.slow; easing.type: Easing.OutCubic }
            NumberAnimation { target: shell; property: "scale"; to: 1; duration: 520; easing.type: Easing.OutCubic }
        }
    }

    ModelLibrary { id: library }
    SettingsDialog {
        id: settingsDialog
        onOpenLibrary: window.openLibrary("all")
        onAppearanceChange: (key, value) => window.setAppearance(key, value)
    }

    // ------------------------------------------------------------- toast
    Rectangle {
        id: toast
        property string kind: "info"
        property bool shown: false
        parent: Overlay.overlay
        z: 900
        x: (window.width - width) / 2
        y: shown ? 18 : -height - 10
        width: Math.min(toastRow.implicitWidth + 32, window.width - 80)
        height: Math.max(42, toastText.implicitHeight + 22)
        radius: 14
        color: Theme.popup
        border.color: kind === "error" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.5) : Theme.border
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        RowLayout {
            id: toastRow
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            spacing: 10
            Rectangle {
                width: 22; height: 22; radius: 11
                color: toast.kind === "error" ? Theme.dangerBg : Theme.brandSoft
                C.Icon {
                    anchors.centerIn: parent
                    name: toast.kind === "error" ? "alert" : "check"
                    color: toast.kind === "error" ? Theme.danger : Theme.brand
                    size: 14
                }
            }
            Text {
                id: toastText
                Layout.fillWidth: true
                Layout.maximumWidth: window.width - 160
                color: Theme.text
                font.pixelSize: Theme.fontMd - 1
                wrapMode: Text.Wrap
            }
        }
        Timer { id: toastTimer; interval: 4200; onTriggered: toast.shown = false }
        MouseArea { anchors.fill: parent; onClicked: toast.shown = false }
    }

    // ------------------------------------------------- start-up problems
    // Shown once start-up finishes. The error stays; the notice can be dismissed.
    Rectangle {
        id: startupBanner
        parent: Overlay.overlay
        z: 800
        readonly property bool hasError: backend.startupError !== ""
        readonly property bool hasNotice: backend.startupNotice !== ""
        visible: backend.ready && (hasError || hasNotice)
        x: Math.max(40, (window.width - width) / 2)
        y: 14
        width: Math.min(620, window.width - 80)
        height: bannerRow.implicitHeight + 24
        radius: 14
        color: hasError ? Theme.dangerBg : Theme.popup
        border.color: hasError ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.5)
                               : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.5)

        Accessible.role: Accessible.AlertMessage
        Accessible.name: (backend.startupError + " " + backend.startupNotice).trim()

        RowLayout {
            id: bannerRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10
            C.Icon {
                name: "alert"
                size: 16
                color: startupBanner.hasError ? Theme.danger : Theme.warning
                Layout.alignment: Qt.AlignTop
            }
            ColumnLayout {
                id: bannerCol
                Layout.fillWidth: true
                spacing: 6
                Text {
                    visible: startupBanner.hasError
                    Layout.fillWidth: true
                    text: backend.startupError
                    color: Theme.text
                    font.pixelSize: Theme.fontMd - 1
                    wrapMode: Text.Wrap
                }
                Text {
                    visible: startupBanner.hasNotice
                    Layout.fillWidth: true
                    text: backend.startupNotice
                    color: Theme.text
                    font.pixelSize: Theme.fontMd - 1
                    wrapMode: Text.Wrap
                }
            }
            C.IconButton {
                visible: !startupBanner.hasError && startupBanner.hasNotice
                iconName: "close"
                Layout.alignment: Qt.AlignTop
                onClicked: backend.dismissStartupNotice()
                Accessible.name: "Dismiss"
            }
        }
    }

    Connections {
        target: backend
        function onToast(message, kind) {
            toastText.text = message
            toast.kind = kind
            toast.shown = true
            toastTimer.restart()
        }
    }

    // Theme crossfade snapshot, above everything including popups.
    Image {
        id: fader
        parent: Overlay.overlay
        z: 1000
        width: window.width
        height: window.height
        opacity: 0
        visible: opacity > 0
        cache: false
        readonly property bool running: fadeAnim.running
        function fadeOut() { fadeAnim.restart() }
        NumberAnimation {
            id: fadeAnim
            target: fader
            property: "opacity"
            from: 1
            to: 0
            duration: 420
            easing.type: Easing.InOutQuad
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
    Shortcut { sequence: "Ctrl+Shift+L"; onActivated: window.setAppearance("theme", Theme.dark ? "light" : "dark") }
    Shortcut { sequence: "Ctrl+."; enabled: backend.isGenerating; onActivated: backend.stopGeneration() }

    // Splash overlay – sits above everything until initialisation finishes.
    Loader {
        id: splashLoader
        anchors.fill: parent
        z: 100
        sourceComponent: Splash {
            status: backend.initStatus
            finished: backend.ready
            onFading: reveal.start()
            onDismissed: splashLoader.active = false
        }
    }

    Component.onCompleted: backend.newChat()
}
