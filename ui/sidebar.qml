import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "."

Rectangle {
    id: root
    color: Theme.sidebar

    signal openLibrary()
    signal openSettings()
    signal collapse()
    signal toggleTheme()

    function focusSearch() { search.forceActiveFocus() }


    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 1
        spacing: 0

        // ---------------------------------------------------------------- top
        // Title-bar row: traffic lights sit on the left; empty space drags the window.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.titleBarHeight
            MouseArea {
                anchors.fill: parent
                onPressed: window.startDrag()
                onDoubleClicked: window.toggleZoom()
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                C.IconButton {
                    iconName: "sidebar"
                    tip: "Hide sidebar  ⌘\\"
                    accessibleName: "Hide sidebar"
                    accessibleDescription: "Collapse sidebar navigation (Command+\\)"
                    onClicked: root.collapse()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 12
            Layout.bottomMargin: 6
            spacing: 10
            C.LogoMark { size: 32 }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    text: "SmolChat"
                    color: Theme.text
                    font.pixelSize: Theme.fontLg
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.2
                }
                Text {
                    text: "by SmolWorks"
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fontXs
                }
            }
        }

        // New chat
        AbstractButton {
            id: newChatBtn
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 14
            implicitHeight: 40
            hoverEnabled: true
            focusPolicy: Qt.TabFocus

            Accessible.role: Accessible.Button
            Accessible.name: "New chat"
            Accessible.description: "Start a new conversation (Command+N)"
            Accessible.focusable: true
            Accessible.focused: visualFocus

            onClicked: backend.newChat()
            scale: down ? 0.98 : 1
            Behavior on scale { NumberAnimation { duration: 90 } }
            background: C.Glass {
                radius: 12
                hovered: newChatBtn.hovered
                active: newChatBtn.visualFocus
            }
            contentItem: RowLayout {
                spacing: 10
                Rectangle {
                    Layout.leftMargin: 6
                    width: 24; height: 24; radius: 8
                    color: Theme.brandSoft
                    C.Icon { anchors.centerIn: parent; name: "plus"; size: 15; color: Theme.brand }
                }
                Text { text: "New chat"; color: Theme.text; font.pixelSize: Theme.fontMd; font.weight: Font.Medium; Layout.fillWidth: true }
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
            accessibleName: "Search chats"
            accessibleDescription: "Filter conversations by keyword"
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

            Accessible.role: Accessible.List
            Accessible.name: "Conversations"

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                NumberAnimation { property: "x"; from: -12; to: 0; duration: Theme.normal; easing.type: Easing.OutCubic }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast }
            }
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: Theme.normal; easing.type: Easing.OutCubic }
            }
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

                Accessible.role: Accessible.ListItem
                Accessible.name: row.title
                Accessible.selected: row.current

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    radius: Theme.radiusMd - 2
                    color: row.current ? Theme.selected : rowMouse.containsMouse || moreBtn.hovered ? Theme.hover : "transparent"
                    border.width: rowSelectBtn.visualFocus ? 2 : 0
                    border.color: Theme.brand
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Rectangle {
                        width: 3
                        height: row.current ? 16 : 0
                        radius: 1.5
                        anchors.left: parent.left
                        anchors.leftMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.brand
                        Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                    }
                }

                AbstractButton {
                    id: rowSelectBtn
                    anchors.fill: parent
                    anchors.rightMargin: 36
                    visible: !row.renaming
                    focusPolicy: Qt.TabFocus
                    hoverEnabled: false
                    Accessible.role: Accessible.Button
                    Accessible.name: row.title
                    Accessible.description: "Open conversation " + row.title
                    Accessible.focusable: true
                    Accessible.focused: visualFocus
                    onClicked: backend.openConversation(row.id)
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
                    accessibleName: "Rename conversation"
                    accessibleDescription: "Enter new title for conversation"
                    onAccepted: { backend.renameConversation(row.id, text); row.renaming = false }
                    onActiveFocusChanged: if (!activeFocus && row.renaming) { backend.renameConversation(row.id, text); row.renaming = false }
                    Keys.onEscapePressed: row.renaming = false
                }

                C.IconButton {
                    id: moreBtn
                    visible: !row.renaming && (rowMouse.containsMouse || hovered || contextMenu.visible || row.current || visualFocus)
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 26
                    implicitHeight: 26
                    iconName: "more"
                    iconSize: 16
                    tip: "Options"
                    accessibleName: "Options for " + row.title
                    accessibleDescription: "Open menu to rename or delete this conversation"
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
                        text: "Export chat…"
                        iconName: "external"
                        onTriggered: {
                            exportFormatDialog.conversationId = row.id
                            exportFormatDialog.conversationTitle = row.title
                            exportFormatDialog.open()
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


        // -------------------------------------------------------------- bottom
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 8
            Layout.topMargin: 8
            Layout.bottomMargin: 12
            spacing: 4

            // Compact status: what's loaded; opens the Model Library.
            AbstractButton {
                id: statusBtn
                Layout.fillWidth: true
                implicitHeight: 46
                hoverEnabled: true
                focusPolicy: Qt.TabFocus

                Accessible.role: Accessible.Button
                Accessible.name: "Model Library status: " + (backend.runtimeState === "loading" ? backend.statusText : backend.loadedModelName ? backend.loadedModelName : backend.hasInstalledModels ? "Ready" : "No models yet")
                Accessible.description: (backend.activeDownloads > 0 ? "Downloading " + backend.activeDownloads + " models. " : "") + "Click to open Model Library"
                Accessible.focusable: true
                Accessible.focused: visualFocus

                onClicked: root.openLibrary()
                scale: down ? 0.98 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                ToolTip.visible: hovered && backend.hardwareSummary !== ""
                ToolTip.delay: 700
                ToolTip.text: backend.hardwareSummary
                background: C.Glass {
                    radius: 12
                    hovered: statusBtn.hovered
                    active: statusBtn.visualFocus
                }
                contentItem: RowLayout {
                    spacing: 10
                    Rectangle {
                        Layout.leftMargin: 12
                        width: 8; height: 8; radius: 4
                        color: backend.runtimeState === "loading" ? Theme.warning
                             : backend.loadedModelId ? Theme.success : Theme.textTertiary
                        SequentialAnimation on opacity {
                            running: backend.runtimeState !== "idle"
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) parent.opacity = 1
                            NumberAnimation { to: 0.3; duration: 550 }
                            NumberAnimation { to: 1; duration: 550 }
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            text: backend.runtimeState === "loading" ? backend.statusText
                                : backend.loadedModelName ? backend.loadedModelName
                                : backend.hasInstalledModels ? "Ready" : "No models yet"
                            color: Theme.text
                            font.pixelSize: Theme.fontSm + 1
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: backend.activeDownloads > 0 ? "Downloading " + backend.activeDownloads + " model" + (backend.activeDownloads > 1 ? "s" : "") + "…"
                                : "Model Library"
                            color: backend.activeDownloads > 0 ? Theme.brand : Theme.textTertiary
                            font.pixelSize: Theme.fontXs
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    C.Icon { name: "chevron-right"; size: 13; color: Theme.textTertiary; Layout.rightMargin: 10 }
                }
            }
            C.IconButton {
                id: themeBtn
                iconName: Theme.dark ? "sun" : "moon"
                tip: Theme.dark ? "Switch to light  ⇧⌘L" : "Switch to dark  ⇧⌘L"
                accessibleName: Theme.dark ? "Switch to light theme" : "Switch to dark theme"
                accessibleDescription: "Toggle application appearance between light and dark (Shift+Command+L)"
                onClicked: { spin.restart(); root.toggleTheme() }
                RotationAnimation on rotation { id: spin; running: false; from: -90; to: 0; duration: 420; easing.type: Easing.OutBack }
            }
            C.IconButton {
                iconName: "settings"
                tip: "Settings  ⌘,"
                accessibleName: "Settings"
                accessibleDescription: "Open application settings dialog (Command+,)"
                onClicked: root.openSettings()
            }
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

    // ------------------------------------------------------------ export flow
    // Step 1: format picker (Markdown vs JSON)
    Dialog {
        id: exportFormatDialog
        property string conversationId: ""
        property string conversationTitle: ""
        title: "Export chat"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Cancel

        ColumnLayout {
            spacing: 12
            width: 260

            Text {
                text: "Choose export format:"
                color: Theme.text
                font.pixelSize: Theme.fontMd
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                AbstractButton {
                    id: mdBtn
                    Layout.fillWidth: true
                    implicitHeight: 40
                    hoverEnabled: true
                    background: C.Glass { radius: 10; hovered: mdBtn.hovered }
                    contentItem: ColumnLayout {
                        spacing: 2
                        Text { text: "Markdown"; color: Theme.text; font.pixelSize: Theme.fontMd; font.weight: Font.Medium; Layout.alignment: Qt.AlignHCenter }
                        Text { text: ".md"; color: Theme.textTertiary; font.pixelSize: Theme.fontXs; Layout.alignment: Qt.AlignHCenter }
                    }
                    onClicked: {
                        exportFormatDialog.close()
                        exportSaveDialog.pendingFmt = "md"
                        exportSaveDialog.pendingConversationId = exportFormatDialog.conversationId
                        exportSaveDialog.currentFile = Qt.resolvedUrl("file:///" + backend.exportDefaultFilename(exportFormatDialog.conversationId, "md"))
                        exportSaveDialog.open()
                    }
                }

                AbstractButton {
                    id: jsonBtn
                    Layout.fillWidth: true
                    implicitHeight: 40
                    hoverEnabled: true
                    background: C.Glass { radius: 10; hovered: jsonBtn.hovered }
                    contentItem: ColumnLayout {
                        spacing: 2
                        Text { text: "JSON"; color: Theme.text; font.pixelSize: Theme.fontMd; font.weight: Font.Medium; Layout.alignment: Qt.AlignHCenter }
                        Text { text: ".json"; color: Theme.textTertiary; font.pixelSize: Theme.fontXs; Layout.alignment: Qt.AlignHCenter }
                    }
                    onClicked: {
                        exportFormatDialog.close()
                        exportSaveDialog.pendingFmt = "json"
                        exportSaveDialog.pendingConversationId = exportFormatDialog.conversationId
                        exportSaveDialog.currentFile = Qt.resolvedUrl("file:///" + backend.exportDefaultFilename(exportFormatDialog.conversationId, "json"))
                        exportSaveDialog.open()
                    }
                }
            }
        }
    }

    // Step 2: native save-file dialog
    FileDialog {
        id: exportSaveDialog
        property string pendingFmt: "md"
        property string pendingConversationId: ""
        title: "Save conversation"
        fileMode: FileDialog.SaveFile
        nameFilters: pendingFmt === "json" ? ["JSON files (*.json)", "All files (*)"]
                                           : ["Markdown files (*.md)", "All files (*)"]
        onAccepted: {
            backend.exportConversation(pendingConversationId, selectedFile, pendingFmt)
        }
    }
}
