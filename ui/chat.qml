import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "."

Rectangle {
    id: root
    color: Theme.bg

    property bool sidebarVisible: true
    signal toggleSidebar()
    signal openLibrary(string filter)

    readonly property bool hasMessages: messages.count > 0
    readonly property bool generatingHere: backend.isGenerating
        && backend.generatingConversationId === backend.currentConversationId

    // ================================================================= header
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        z: 2

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 4

            C.IconButton {
                visible: !root.sidebarVisible
                iconName: "sidebar"
                tip: "Show sidebar  ⌘\\"
                onClicked: root.toggleSidebar()
            }
            C.IconButton {
                visible: !root.sidebarVisible
                iconName: "new-chat"
                tip: "New chat  ⌘N"
                onClicked: backend.newChat()
            }

            // Model selector
            AbstractButton {
                id: modelButton
                implicitHeight: 36
                implicitWidth: pickerRow.implicitWidth + 24
                hoverEnabled: true
                Layout.leftMargin: root.sidebarVisible ? 4 : 6
                onClicked: modelPicker.opened ? modelPicker.close() : modelPicker.open()
                background: Rectangle {
                    radius: Theme.radiusMd
                    color: modelButton.hovered || modelPicker.opened ? Theme.hover : "transparent"
                }
                contentItem: Item {
                    implicitWidth: pickerRow.implicitWidth
                    Row {
                        id: pickerRow
                        anchors.centerIn: parent
                        spacing: 6
                        C.Icon {
                            visible: backend.modelMode === "auto"
                            name: "sparkles"
                            size: 15
                            color: Theme.brand
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: backend.selectedModelLabel
                            color: backend.selectedModelMissing ? Theme.danger : Theme.text
                            font.pixelSize: Theme.fontLg
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        C.Badge {
                            text: backend.modelMode === "auto" ? "Automatic" : "Manual"
                            tint: backend.modelMode === "auto" ? Theme.brand : Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        C.Icon { name: "chevron-down"; size: 15; color: Theme.textTertiary; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Offline indicator
            Row {
                spacing: 6
                visible: backend.loadedModelId !== ""
                C.Icon { name: "check"; size: 13; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "Running locally"
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fontXs + 1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Popup {
            id: modelPicker
            y: header.height - 6
            x: modelButton.x + 8
            width: 320
            padding: 6
            background: Rectangle {
                color: Theme.popup
                radius: Theme.radiusLg - 2
                border.color: Theme.border
            }
            enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast } }
            exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }

            contentItem: ColumnLayout {
                spacing: 0

                PickerRow {
                    title: "Auto"
                    subtitle: "Picks the best downloaded model for each message"
                    iconName: "sparkles"
                    iconTint: Theme.brand
                    selected: backend.modelMode === "auto"
                    onClicked: { backend.setAutoMode(); modelPicker.close() }
                }

                Text {
                    text: "DOWNLOADED MODELS"
                    visible: backend.installedModels.length > 0
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fontXs - 1
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                    Layout.leftMargin: 12
                    Layout.topMargin: 10
                    Layout.bottomMargin: 4
                }

                Repeater {
                    model: backend.installedModels
                    PickerRow {
                        required property var modelData
                        title: modelData.name
                        subtitle: modelData.detail + (modelData.loaded ? " · Loaded" : "")
                        iconName: "chip"
                        selected: backend.modelMode === "manual" && backend.selectedModelId === modelData.id
                        onClicked: { backend.selectModel(modelData.id); modelPicker.close() }
                    }
                }

                Text {
                    visible: backend.installedModels.length === 0
                    text: "No models downloaded yet."
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fontSm
                    Layout.margins: 12
                }

                C.Separator { Layout.fillWidth: true; Layout.topMargin: 6; Layout.bottomMargin: 6 }

                PickerRow {
                    title: "Model Library…"
                    subtitle: "Download, manage and delete models"
                    iconName: "library"
                    onClicked: { modelPicker.close(); root.openLibrary("all") }
                }
            }
        }
    }

    component PickerRow: AbstractButton {
        id: pr
        property string title
        property string subtitle
        property string iconName
        property color iconTint: Theme.textSecondary
        property bool selected: false
        Layout.fillWidth: true
        implicitHeight: 48
        hoverEnabled: true
        background: Rectangle { radius: Theme.radiusMd; color: pr.hovered ? Theme.hover : "transparent" }
        contentItem: RowLayout {
            spacing: 10
            C.Icon { name: pr.iconName; size: 17; color: pr.iconTint; Layout.leftMargin: 8 }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text { text: pr.title; color: Theme.text; font.pixelSize: Theme.fontMd - 1; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: pr.subtitle; color: Theme.textTertiary; font.pixelSize: Theme.fontXs; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            C.Icon { visible: pr.selected; name: "check"; size: 16; color: Theme.text; Layout.rightMargin: 8 }
        }
    }

    // ========================================================= welcome states
    Item {
        id: welcome
        anchors.top: header.bottom
        anchors.bottom: composerArea.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: !root.hasMessages
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }

        // No models installed: onboarding
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 520)
            visible: backend.ready && !backend.hasInstalledModels
            spacing: 0

            Image {
                source: "../resources/icons/logo.svg"
                sourceSize: Qt.size(112, 112)
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Welcome to SmolChat"
                color: Theme.text
                font.pixelSize: Theme.fontHero
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }
            Text {
                text: "SmolChat runs small language models entirely on your Mac. Download a model once, then chat offline — your conversations never leave this computer."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontMd + 1
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.25
                Layout.fillWidth: true
                Layout.topMargin: 10
            }

            // Quick start suggestion
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 28
                implicitHeight: quick.implicitHeight + 32
                radius: Theme.radiusLg
                color: "transparent"
                border.color: Theme.border
                ColumnLayout {
                    id: quick
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4
                    Text { text: "Recommended for your Mac"; color: Theme.textTertiary; font.pixelSize: Theme.fontXs; font.weight: Font.DemiBold }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Text {
                                text: backend.recommendedModel.name || "No model fits this Mac right now"
                                color: Theme.text
                                font.pixelSize: Theme.fontMd + 1
                                font.weight: Font.Medium
                            }
                            Text {
                                text: backend.recommendedModel.description || "Free up storage or memory, then check the Model Library for models marked Runs well."
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSm
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                        ColumnLayout {
                            spacing: 6
                            visible: backend.recommendedModel.id !== undefined && backend.recommendedModel.id !== ""
                            Text {
                                text: backend.recommendedModel.sizeText || ""
                                color: Theme.text
                                font.pixelSize: Theme.fontMd
                                font.weight: Font.DemiBold
                                Layout.alignment: Qt.AlignRight
                            }
                            C.ActionButton {
                                kind: "primary"
                                compact: true
                                text: backend.recommendedModel.downloading ? "Downloading…" : "Download"
                                iconName: "download"
                                enabled: !backend.recommendedModel.downloading
                                onClicked: backend.downloadModel(backend.recommendedModel.id)
                            }
                        }
                    }
                    ColumnLayout {
                        visible: backend.recommendedModel.downloading === true
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        spacing: 4
                        C.SlimProgress {
                            Layout.fillWidth: true
                            value: backend.recommendedModel.progress || 0
                            indeterminate: !backend.recommendedModel.progressText
                        }
                        Text {
                            text: backend.recommendedModel.progressText || "Connecting to Hugging Face…"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontXs + 1
                        }
                    }
                    Text {
                        text: backend.hardwareSummary
                        visible: text !== ""
                        color: Theme.textTertiary
                        font.pixelSize: Theme.fontXs
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                    }
                }
            }
            C.ActionButton {
                text: "Browse all models"
                iconName: "library"
                kind: "ghost"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                onClicked: root.openLibrary("all")
            }
        }

        // Models installed: empty conversation
        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            width: Math.min(parent.width - 64, 620)
            visible: backend.ready && backend.hasInstalledModels
            spacing: 0
            Text {
                text: "What can I help with?"
                color: Theme.text
                font.pixelSize: Theme.fontHero
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: backend.modelMode === "auto"
                      ? "SmolChat will choose a downloaded model for each message."
                      : "Using " + backend.selectedModelLabel + " for this chat."
                color: Theme.textTertiary
                font.pixelSize: Theme.fontMd - 1
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 28
                spacing: 8
                Repeater {
                    model: [
                        "Explain how a transformer model works",
                        "Write a haiku about autumn in the city",
                        "Give me three ideas for a weekend project",
                        "Write a Python function that reverses a string"
                    ]
                    AbstractButton {
                        id: chip
                        required property string modelData
                        hoverEnabled: true
                        implicitHeight: 36
                        implicitWidth: chipText.implicitWidth + 28
                        onClicked: { composer.text = modelData; composer.forceActiveFocus(); composer.cursorPosition = composer.length }
                        background: Rectangle {
                            radius: 18
                            color: chip.hovered ? Theme.hover : "transparent"
                            border.color: Theme.border
                        }
                        contentItem: Text {
                            id: chipText
                            text: chip.modelData
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSm + 1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    // ================================================================ messages
    ListView {
        id: messages
        anchors.top: header.bottom
        anchors.bottom: composerArea.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.hasMessages
        clip: true
        model: backend.messageModel
        spacing: 22
        topMargin: 12
        bottomMargin: 24
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 2000
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 10 }

        property bool stickToBottom: true
        onMovementStarted: stickToBottom = false
        onMovementEnded: stickToBottom = atYEnd
        onContentHeightChanged: if (stickToBottom) Qt.callLater(positionViewAtEnd)

        Connections {
            target: backend
            function onScrollToEnd() {
                if (messages.stickToBottom) Qt.callLater(messages.positionViewAtEnd)
            }
            function onConversationChanged() {
                messages.stickToBottom = true
                Qt.callLater(messages.positionViewAtEnd)
            }
        }

        delegate: Item {
            id: msg
            required property int index
            required property int id
            required property string role
            required property string content
            required property var segments
            required property string modelName
            required property string meta
            required property bool streaming
            required property bool error
            required property var images

            readonly property bool isUser: role === "user"
            readonly property bool isLast: index === messages.count - 1
            width: messages.width
            height: column.implicitHeight

            HoverHandler { id: hover }

            Column {
                id: column
                width: Math.min(messages.width - 48, Theme.contentWidth)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                // ---------- user message
                Column {
                    visible: msg.isUser
                    width: parent.width
                    spacing: 6
                    Flow {
                        visible: msg.images.length > 0
                        layoutDirection: Qt.RightToLeft
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: msg.images
                            Rectangle {
                                required property string modelData
                                width: 140; height: 140; radius: Theme.radiusMd
                                color: Theme.surface
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: modelData
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(280, 280)
                                    asynchronous: true
                                }
                            }
                        }
                    }
                    Rectangle {
                        visible: msg.content !== ""
                        anchors.right: parent.right
                        width: Math.min(userText.implicitWidth + 36, parent.width * 0.78)
                        height: userText.implicitHeight + 20
                        radius: 20
                        color: Theme.userBubble
                        TextEdit {
                            id: userText
                            x: 18
                            y: 10
                            width: Math.min(implicitWidth, column.width * 0.78 - 36)
                            text: msg.content
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            color: Theme.text
                            selectionColor: Theme.brand
                            font.pixelSize: Theme.fontMd + 1
                            textFormat: TextEdit.PlainText
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        opacity: hover.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                        CopyButton { textToCopy: msg.content }
                    }
                }

                // ---------- assistant message
                Column {
                    visible: !msg.isUser
                    width: parent.width
                    spacing: 10

                    // Loading / waiting indicator
                    Row {
                        visible: msg.streaming && msg.content === ""
                        spacing: 10
                        height: 24
                        C.LoadingDots { anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: backend.statusText
                            color: Theme.textTertiary
                            font.pixelSize: Theme.fontSm + 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Error card
                    Rectangle {
                        visible: msg.error
                        width: parent.width
                        height: errRow.implicitHeight + 24
                        radius: Theme.radiusMd
                        color: Theme.dangerBg
                        border.color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.35)
                        RowLayout {
                            id: errRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10
                            C.Icon { name: "alert"; size: 17; color: Theme.danger; Layout.alignment: Qt.AlignTop }
                            Text {
                                text: msg.content
                                color: Theme.text
                                wrapMode: Text.Wrap
                                font.pixelSize: Theme.fontMd
                                Layout.fillWidth: true
                            }
                            C.ActionButton {
                                visible: !backend.hasInstalledModels || msg.content.indexOf("Model Library") >= 0
                                text: "Open Library"
                                compact: true
                                onClicked: root.openLibrary(msg.content.indexOf("image") >= 0 ? "vision" : "all")
                            }
                        }
                    }

                    // Content segments
                    Repeater {
                        model: msg.error ? [] : msg.segments
                        delegate: Loader {
                            required property var modelData
                            width: parent.width
                            sourceComponent: modelData.kind === "code" ? codeBlock
                                           : modelData.kind === "think" ? thinkBlock : textBlock
                            property var seg: modelData
                        }
                    }

                    // Footer actions
                    Row {
                        visible: !msg.streaming && msg.content !== ""
                        spacing: 2
                        opacity: hover.hovered || msg.isLast ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                        CopyButton { textToCopy: msg.content; visible: !msg.error }
                        C.IconButton {
                            visible: msg.isLast && !backend.isGenerating
                            iconName: "refresh"
                            iconSize: 16
                            implicitWidth: 28; implicitHeight: 28
                            tip: "Regenerate response"
                            onClicked: backend.regenerate()
                        }
                        Text {
                            leftPadding: 8
                            text: [msg.modelName, msg.meta].filter(s => s).join(" · ")
                            color: Theme.textTertiary
                            font.pixelSize: Theme.fontXs + 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    // Jump-to-bottom button
    C.IconButton {
        anchors.horizontalCenter: messages.horizontalCenter
        anchors.bottom: composerArea.top
        anchors.bottomMargin: 8
        visible: root.hasMessages && !messages.atYEnd && messages.contentHeight > messages.height
        iconName: "chevron-down"
        tip: "Scroll to bottom"
        background: Rectangle { radius: 16; color: Theme.surfaceRaised; border.color: Theme.border }
        onClicked: { messages.stickToBottom = true; messages.positionViewAtEnd() }
    }

    component CopyButton: C.IconButton {
        id: cb
        property string textToCopy
        property bool copied: false
        iconName: copied ? "check" : "copy"
        iconSize: 15
        implicitWidth: 28
        implicitHeight: 28
        tip: copied ? "Copied" : "Copy"
        onClicked: { backend.copyText(textToCopy); copied = true; resetTimer.restart() }
        Timer { id: resetTimer; interval: 1500; onTriggered: cb.copied = false }
    }

    Component {
        id: textBlock
        TextEdit {
            property var seg: parent ? parent.seg : ({})
            text: seg.text
            textFormat: TextEdit.MarkdownText
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.Wrap
            color: Theme.text
            selectionColor: Theme.brand
            font.pixelSize: Theme.fontMd + 1
            onLinkActivated: (link) => backend.openUrl(link)
            HoverHandler { cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor }
        }
    }

    Component {
        id: codeBlock
        Rectangle {
            property var seg: parent ? parent.seg : ({})
            radius: Theme.radiusMd
            color: Theme.codeBg
            border.color: Theme.borderSubtle
            implicitHeight: codeHeader.height + codeText.implicitHeight + 24
            clip: true
            Rectangle {
                id: codeHeader
                width: parent.width
                height: 34
                color: Theme.codeHeader
                radius: Theme.radiusMd
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.radius; color: parent.color }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: seg.lang || "code"
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fontXs + 1
                    font.family: Theme.monoFamily
                }
                AbstractButton {
                    id: copyCode
                    property bool copied: false
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: 26
                    implicitWidth: copyRow.implicitWidth + 14
                    hoverEnabled: true
                    onClicked: { backend.copyText(seg.text); copied = true; copyReset.restart() }
                    Timer { id: copyReset; interval: 1500; onTriggered: copyCode.copied = false }
                    background: Rectangle { radius: 6; color: copyCode.hovered ? Theme.hover : "transparent" }
                    contentItem: Item {
                        Row {
                            id: copyRow
                            anchors.centerIn: parent
                            spacing: 5
                            C.Icon { name: copyCode.copied ? "check" : "copy"; size: 13; color: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: copyCode.copied ? "Copied" : "Copy code"; color: Theme.textSecondary; font.pixelSize: Theme.fontXs + 1; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
            }
            TextEdit {
                id: codeText
                anchors.top: codeHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                anchors.leftMargin: 14
                text: "<pre style=\"white-space: pre-wrap; margin:0\">" + (seg.html || "") + "</pre>"
                textFormat: TextEdit.RichText
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectionColor: Theme.brand
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSm + 1
            }
        }
    }

    Component {
        id: thinkBlock
        Column {
            id: think
            property var seg: parent ? parent.seg : ({})
            property bool expanded: seg.open
            spacing: 6
            AbstractButton {
                id: thinkToggle
                hoverEnabled: true
                implicitHeight: 26
                implicitWidth: thinkRow.implicitWidth + 8
                onClicked: think.expanded = !think.expanded
                background: null
                contentItem: Row {
                    id: thinkRow
                    spacing: 6
                    C.Icon { name: "brain"; size: 14; color: Theme.textTertiary; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: seg.open ? "Thinking…" : "Thought process"
                        color: thinkToggle.hovered ? Theme.textSecondary : Theme.textTertiary
                        font.pixelSize: Theme.fontSm + 1
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    C.Icon {
                        name: think.expanded ? "chevron-down" : "chevron-right"
                        size: 13
                        color: Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            Rectangle {
                visible: think.expanded
                width: parent.width
                height: thoughtText.implicitHeight
                color: "transparent"
                Rectangle { width: 2; height: parent.height; radius: 1; color: Theme.border }
                Text {
                    id: thoughtText
                    x: 14
                    width: parent.width - 14
                    text: seg.text
                    color: Theme.textTertiary
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontMd - 1
                    lineHeight: 1.2
                }
            }
        }
    }

    // ================================================================ composer
    Item {
        id: composerArea
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: composerBox.height + footer.height + 24

        property var attachments: []
        readonly property bool inputEnabled: backend.ready && backend.hasInstalledModels && backend.runtimeAvailable
        readonly property bool canSend: inputEnabled && !backend.isGenerating
            && (composer.text.trim().length > 0 || attachments.length > 0)

        function send() {
            if (!canSend) return
            if (backend.sendMessage(composer.text, attachments)) {
                composer.text = ""
                attachments = []
                messages.stickToBottom = true
            }
        }

        function addFiles(urls) {
            const exts = [".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"]
            let list = attachments.slice()
            for (const u of urls) {
                const s = String(u)
                if (exts.some(e => s.toLowerCase().endsWith(e)) && list.indexOf(s) < 0) list.push(s)
            }
            attachments = list.slice(0, 4)
        }

        FileDialog {
            id: fileDialog
            title: "Attach images"
            fileMode: FileDialog.OpenFiles
            nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif *.bmp)"]
            onAccepted: composerArea.addFiles(selectedFiles)
        }

        Rectangle {
            id: composerBox
            anchors.bottom: footer.top
            anchors.bottomMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 48, Theme.contentWidth)
            height: boxColumn.implicitHeight + 20
            radius: Theme.radiusXl
            color: Theme.surface
            border.color: composer.activeFocus ? Theme.border : Theme.borderSubtle
            Behavior on height { NumberAnimation { duration: 90 } }

            DropArea {
                anchors.fill: parent
                enabled: backend.visionAvailable
                onDropped: (drop) => { if (drop.hasUrls) composerArea.addFiles(drop.urls) }
            }

            ColumnLayout {
                id: boxColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 6

                // Attachments
                Row {
                    visible: composerArea.attachments.length > 0
                    spacing: 8
                    Layout.leftMargin: 6
                    Layout.topMargin: 4
                    Repeater {
                        model: composerArea.attachments
                        Rectangle {
                            id: thumb
                            required property string modelData
                            required property int index
                            width: 56; height: 56; radius: 10
                            color: Theme.surfaceRaised
                            clip: true
                            Image { anchors.fill: parent; source: thumb.modelData; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(112, 112) }
                            C.IconButton {
                                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 2
                                implicitWidth: 20; implicitHeight: 20
                                iconName: "close"; iconSize: 12; iconColor: "#ffffff"
                                background: Rectangle { radius: 10; color: "#aa000000" }
                                onClicked: {
                                    const list = composerArea.attachments.slice()
                                    list.splice(thumb.index, 1)
                                    composerArea.attachments = list
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    id: composerScroll
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(Math.max(composer.implicitHeight, 24), 220)
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    TextArea {
                        id: composer
                        enabled: composerArea.inputEnabled
                        placeholderText: !backend.ready ? "Starting…"
                            : !backend.hasInstalledModels ? "Download a model to start chatting"
                            : !backend.runtimeAvailable ? "The local runtime could not be loaded"
                            : "Message SmolChat"
                        placeholderTextColor: Theme.textTertiary
                        color: Theme.text
                        selectionColor: Theme.brand
                        selectedTextColor: "#ffffff"
                        font.pixelSize: Theme.fontMd + 1
                        wrapMode: TextArea.Wrap
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 6
                        bottomPadding: 4
                        background: null
                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ShiftModifier) { event.accepted = false; return }
                            event.accepted = true
                            composerArea.send()
                        }
                        Keys.onEnterPressed: (event) => Keys.returnPressed(event)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    C.IconButton {
                        visible: backend.visionAvailable
                        enabled: composerArea.inputEnabled
                        iconName: "paperclip"
                        iconSize: 17
                        tip: "Attach images (vision models)"
                        onClicked: fileDialog.open()
                    }

                    // Selected model indicator
                    AbstractButton {
                        id: chipBtn
                        implicitHeight: 28
                        implicitWidth: chipRow.implicitWidth + 18
                        hoverEnabled: true
                        enabled: backend.ready
                        onClicked: modelPicker.open()
                        background: Rectangle {
                            radius: 14
                            color: chipBtn.hovered ? Theme.hover : "transparent"
                            border.color: Theme.borderSubtle
                        }
                        contentItem: Item {
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 5
                                C.Icon {
                                    name: backend.modelMode === "auto" ? "sparkles" : "chip"
                                    size: 13
                                    color: backend.modelMode === "auto" ? Theme.brand : Theme.textSecondary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: backend.selectedModelLabel
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontXs + 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Generation status
                    Row {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        spacing: 8
                        clip: true
                        C.LoadingDots {
                            visible: backend.runtimeState !== "idle"
                            dot: 4
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: parent.width - 30
                            text: backend.runtimeState !== "idle" ? backend.statusText
                                : backend.modelMode === "auto" && backend.lastRouteReason ? backend.lastRouteReason : ""
                            color: Theme.textTertiary
                            font.pixelSize: Theme.fontXs + 1
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Send / Stop
                    AbstractButton {
                        id: sendBtn
                        implicitWidth: 34
                        implicitHeight: 34
                        hoverEnabled: true
                        readonly property bool stopMode: root.generatingHere
                        enabled: stopMode || composerArea.canSend
                        onClicked: stopMode ? backend.stopGeneration() : composerArea.send()
                        ToolTip.visible: hovered
                        ToolTip.delay: 600
                        ToolTip.text: stopMode ? "Stop generating  ⌘." : "Send  ↩"
                        background: Rectangle {
                            radius: 17
                            color: sendBtn.enabled ? (sendBtn.hovered ? Qt.darker(Theme.accent, 1.12) : Theme.accent) : Theme.accentMuted
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                        }
                        contentItem: Item {
                            C.Icon {
                                anchors.centerIn: parent
                                name: sendBtn.stopMode ? "stop" : "arrow-up"
                                size: sendBtn.stopMode ? 14 : 18
                                color: Theme.textOnAccent
                            }
                        }
                    }
                }
            }
        }

        Text {
            id: footer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            text: "SmolChat runs entirely on this Mac. Small models can make mistakes — check important information."
            color: Theme.textTertiary
            font.pixelSize: Theme.fontXs
            width: Math.min(parent.width - 48, implicitWidth)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Connections {
        target: backend
        function onConversationChanged() {
            composerArea.attachments = []
            if (backend.ready) composer.forceActiveFocus()
        }
    }
}
