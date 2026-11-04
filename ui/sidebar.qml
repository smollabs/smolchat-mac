import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Rectangle {
    id: root
    color: Theme.sidebar

    signal openLibrary()
    signal openSettings()
    signal collapse()

    function focusSearch() { search.forceActiveFocus() }

    // Right edge hairline
    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.borderSubtle }

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 1
        spacing: 0

        // ---------------------------------------------------------------- top
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.leftMargin: 14
            Layout.rightMargin: 8
            spacing: 8
            Image {
                source: "../resources/icons/logo.svg"
                sourceSize: Qt.size(52, 52)
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
            }
            Text {
                text: "SmolChat"
                color: Theme.text
                font.pixelSize: Theme.fontLg
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            C.IconButton { iconName: "sidebar"; tip: "Hide sidebar  ⌘\\"; onClicked: root.collapse() }
        }

        // New chat
        AbstractButton {
            id: newChatBtn
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 14
            implicitHeight: 36
            hoverEnabled: true
            onClicked: backend.newChat()
            background: Rectangle {
                radius: Theme.radiusMd
                color: newChatBtn.hovered ? Theme.hover : "transparent"
            }
            contentItem: RowLayout {
                spacing: 10
                C.Icon { name: "new-chat"; size: 17; color: Theme.text; Layout.leftMargin: 8 }
                Text { text: "New chat"; color: Theme.text; font.pixelSize: Theme.fontMd; Layout.fillWidth: true }
                Text { text: "⌘N"; color: Theme.textTertiary; font.pixelSize: Theme.fontXs; Layout.rightMargin: 8; visible: newChatBtn.hovered }
            }
        }

        C.Field {
            id: search
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 6
            iconName: "search"
            placeholderText: "Search chats"
            onTextChanged: searchDebounce.restart()
            Keys.onEscapePressed: { text = ""; focus = false }
            Timer { id: searchDebounce; interval: 180; onTriggered: backend.setSearch(search.text) }
        }

        // ------------------------------------------------------------- history
        ListView {
            id: history
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 10
            clip: true
            model: backend.conversationModel
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 8 }
            section.property: "section"
            section.delegate: Text {
                required property string section
                text: section
                width: ListView.view.width
                leftPadding: 18
                topPadding: 14
                bottomPadding: 6
                color: Theme.textTertiary
                font.pixelSize: Theme.fontXs
                font.weight: Font.DemiBold
            }

            delegate: Item {
                id: row
                required property string id
                required property string title
                required property string modelMode
                required property int index
                width: ListView.view.width
                height: 34
                property bool current: backend.currentConversationId === row.id
                property bool renaming: false

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    radius: Theme.radiusMd - 2
                    color: row.current ? Theme.selected : rowMouse.containsMouse || moreBtn.hovered ? Theme.hover : "transparent"
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) contextMenu.popup()
                        else if (!row.renaming) backend.openConversation(row.id)
                    }
                }

                Text {
                    visible: !row.renaming
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.right: moreBtn.visible ? moreBtn.left : parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.title
                    color: Theme.text
                    font.pixelSize: Theme.fontMd - 1
                    elide: Text.ElideRight
                }

                C.Field {
                    id: renameField
                    visible: row.renaming
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    implicitHeight: 30
                    onAccepted: { backend.renameConversation(row.id, text); row.renaming = false }
                    onActiveFocusChanged: if (!activeFocus && row.renaming) { backend.renameConversation(row.id, text); row.renaming = false }
                    Keys.onEscapePressed: row.renaming = false
                }

                C.IconButton {
                    id: moreBtn
                    visible: !row.renaming && (rowMouse.containsMouse || hovered || contextMenu.visible || row.current)
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 26
                    implicitHeight: 26
                    iconName: "more"
                    iconSize: 16
                    tip: "Options"
                    onClicked: contextMenu.popup(moreBtn, 0, moreBtn.height)
                }

                C.MenuStyled {
                    id: contextMenu
                    C.MenuItemStyled {
                        text: "Rename"
                        iconName: "edit"
                        onTriggered: {
                            row.renaming = true
                            renameField.text = row.title
                            renameField.forceActiveFocus()
                            renameField.selectAll()
                        }
                    }
                    C.MenuItemStyled {
                        text: "Delete"
                        iconName: "trash"
                        destructive: true
                        onTriggered: {
                            deleteDialog.conversationId = row.id
                            deleteDialog.message = "“" + row.title + "” and all of its messages will be permanently deleted from this Mac."
                            deleteDialog.open()
                        }
                    }
                }
            }

            // Empty states
            Text {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: history.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: backend.searchQuery ? "No chats match “" + backend.searchQuery + "”." : "Your conversations will appear here."
                color: Theme.textTertiary
                font.pixelSize: Theme.fontSm
            }
        }

        C.Separator { Layout.fillWidth: true }

        // -------------------------------------------------------------- bottom
        // Current model indicator – opens the library.
        AbstractButton {
            id: modelIndicator
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 8
            implicitHeight: 48
            hoverEnabled: true
            onClicked: root.openLibrary()
            ToolTip.visible: hovered && backend.hardwareSummary !== ""
            ToolTip.delay: 700
            ToolTip.text: backend.hardwareSummary
            background: Rectangle { radius: Theme.radiusMd; color: modelIndicator.hovered ? Theme.hover : "transparent" }
            contentItem: RowLayout {
                spacing: 10
                Rectangle {
                    Layout.leftMargin: 8
                    width: 28; height: 28; radius: 8
                    color: Theme.surface
                    C.Icon { anchors.centerIn: parent; name: "chip"; size: 16; color: Theme.textSecondary }
                    Rectangle {
                        width: 9; height: 9; radius: 4.5
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.rightMargin: -2; anchors.bottomMargin: -2
                        border.width: 2; border.color: Theme.sidebar
                        color: backend.runtimeState === "loading" ? Theme.warning
                             : backend.loadedModelId ? Theme.success : Theme.textTertiary
                        SequentialAnimation on opacity {
                            running: backend.runtimeState === "loading"
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 500 }
                            NumberAnimation { to: 1; duration: 500 }
                        }
                    }
                }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: backend.runtimeState === "loading" ? backend.statusText
                            : backend.loadedModelName ? backend.loadedModelName
                            : backend.hasInstalledModels ? "No model loaded" : "No models downloaded"
                        color: Theme.text
                        font.pixelSize: Theme.fontSm + 1
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: backend.loadedModelName ? "Loaded · running on this Mac"
                            : backend.hasInstalledModels ? "Loads on your next message" : "Open the library to get started"
                        color: Theme.textTertiary
                        font.pixelSize: Theme.fontXs
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 2
            Layout.bottomMargin: 10
            spacing: 2
            AbstractButton {
                id: libBtn
                Layout.fillWidth: true
                implicitHeight: 34
                hoverEnabled: true
                onClicked: root.openLibrary()
                background: Rectangle { radius: Theme.radiusMd; color: libBtn.hovered ? Theme.hover : "transparent" }
                contentItem: RowLayout {
                    spacing: 10
                    C.Icon { name: "library"; size: 16; color: Theme.textSecondary; Layout.leftMargin: 8 }
                    Text { text: "Model Library"; color: Theme.text; font.pixelSize: Theme.fontMd - 1; Layout.fillWidth: true }
                    C.Badge {
                        visible: backend.activeDownloads > 0
                        text: backend.activeDownloads + " ↓"
                        tint: Theme.brand
                        Layout.rightMargin: 6
                    }
                }
            }
            C.IconButton { iconName: "settings"; tip: "Settings  ⌘,"; onClicked: root.openSettings() }
        }
    }

    C.ConfirmDialog {
        id: deleteDialog
        property string conversationId
        title: "Delete chat?"
        confirmText: "Delete"
        destructive: true
        onConfirmed: backend.deleteConversation(conversationId)
    }
}
