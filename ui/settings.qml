import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Popup {
    id: dlg
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent ? parent.width - 80 : 560, 560)
    height: Math.min(parent ? parent.height - 80 : 660, 660)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Accessible.role: Accessible.Dialog
    Accessible.name: "Settings"

    signal openLibrary()
    signal appearanceChange(string key, string value)

    Overlay.modal: Rectangle { color: Theme.overlay }
    background: C.Glass { radius: 20; fill: Theme.popup }
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
        NumberAnimation { property: "scale"; from: 0.98; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }

    component SectionTitle: Text {
        color: Theme.textTertiary
        font.pixelSize: Theme.fontXs
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        Layout.topMargin: 18
        Layout.bottomMargin: 4
    }

    component SettingRow: RowLayout {
        property string label
        property string hint
        default property alias control: holder.data
        Layout.fillWidth: true
        spacing: 16
        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Text { text: label; color: Theme.text; font.pixelSize: Theme.fontMd - 1; Layout.fillWidth: true }
            Text { visible: hint !== ""; text: hint; color: Theme.textTertiary; font.pixelSize: Theme.fontXs + 1; wrapMode: Text.Wrap; Layout.fillWidth: true }
        }
        Item { id: holder; implicitWidth: childrenRect.width; implicitHeight: childrenRect.height }
    }

    // Segmented control
    component Segmented: Row {
        id: seg
        property var options: []   // [{ key, label }]
        property string value
        property string accessibleName: ""
        signal picked(string key)
        spacing: 2

        Accessible.role: Accessible.PageTabList
        Accessible.name: accessibleName

        Repeater {
            model: seg.options
            AbstractButton {
                id: sb
                required property var modelData
                required property int index
                readonly property bool active: seg.value === modelData.key
                implicitHeight: 28
                implicitWidth: sbText.implicitWidth + 22
                hoverEnabled: true
                focusPolicy: Qt.TabFocus

                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                Accessible.selected: active
                Accessible.focusable: true
                Accessible.focused: visualFocus

                onClicked: seg.picked(modelData.key)

                Keys.onLeftPressed: {
                    if (sb.index > 0) {
                        seg.picked(seg.options[sb.index - 1].key)
                    }
                }
                Keys.onRightPressed: {
                    if (sb.index < seg.options.length - 1) {
                        seg.picked(seg.options[sb.index + 1].key)
                    }
                }

                background: Rectangle {
                    radius: 8
                    color: sb.active ? Theme.hoverStrong : sb.hovered ? Theme.hover : "transparent"
                    border.width: sb.visualFocus ? 2 : (sb.active ? 1 : 0)
                    border.color: sb.visualFocus ? Theme.brand : (sb.active ? Theme.border : "transparent")
                }
                contentItem: Text {
                    id: sbText
                    text: sb.modelData.label
                    color: sb.active ? Theme.text : Theme.textSecondary
                    font.pixelSize: Theme.fontSm + 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    component Toggle: Switch {
        id: sw
        property string accessibleName: ""
        property string accessibleDescription: ""
        implicitWidth: 40
        implicitHeight: 24
        focusPolicy: Qt.TabFocus

        Accessible.role: Accessible.Switch
        Accessible.name: accessibleName
        Accessible.description: accessibleDescription
        Accessible.checkable: true
        Accessible.checked: checked
        Accessible.focusable: true
        Accessible.focused: visualFocus

        indicator: Rectangle {
            implicitWidth: 38
            implicitHeight: 22
            radius: 11
            color: sw.checked ? Theme.brand : Theme.hoverStrong
            border.width: sw.visualFocus ? 2 : 0
            border.color: sw.checked ? Theme.accent : Theme.brand
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Rectangle {
                width: 18; height: 18; radius: 9
                y: 2
                x: sw.checked ? parent.width - width - 2 : 2
                color: "#ffffff"
                Behavior on x { NumberAnimation { duration: Theme.fast } }
            }
        }
        contentItem: null
    }

    component ThemePane: Item {
        id: pane
        property bool darkPane: true
        readonly property color bgc: darkPane ? "#1f1f21" : "#ffffff"
        readonly property color side: darkPane ? "#161618" : "#f7f7f8"
        readonly property color line: darkPane ? "#3a3a3e" : "#dcdce0"
        readonly property color bubble: darkPane ? "#2e2e32" : "#ececef"
        Rectangle { anchors.fill: parent; color: pane.bgc }
        Rectangle { width: parent.width * 0.3; height: parent.height; color: pane.side
            Column {
                x: 6; y: 8; spacing: 4
                Repeater { model: 3; Rectangle { width: 30 - (index * 6); height: 4; radius: 2; color: pane.line } }
            }
        }
        Rectangle { x: parent.width * 0.62; y: 10; width: parent.width * 0.3; height: 10; radius: 5; color: pane.bubble }
        Rectangle { x: parent.width * 0.36; y: 26; width: parent.width * 0.5; height: 4; radius: 2; color: pane.line }
        Rectangle { x: parent.width * 0.36; y: 34; width: parent.width * 0.38; height: 4; radius: 2; color: pane.line }
        Rectangle {
            x: parent.width * 0.36; y: parent.height - 16
            width: parent.width * 0.58; height: 10; radius: 5
            color: pane.bubble
            Rectangle { anchors.right: parent.right; anchors.rightMargin: 2; anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: 3; color: Theme.brand }
        }
    }

    // Miniature window drawn in the colours of a theme.
    component ThemePreview: Item {
        id: tp
        property string mode: "dark"
        clip: true
        Item {
            anchors.fill: parent
            clip: true
            ThemePane { visible: tp.mode !== "light"; anchors.fill: parent; darkPane: true }
            ThemePane { visible: tp.mode === "light"; anchors.fill: parent; darkPane: false }
            // System: diagonal split light / dark
            Item {
                visible: tp.mode === "system"
                anchors.fill: parent
                clip: true
                Item {
                    width: parent.width / 2; height: parent.height; clip: true
                    ThemePane { width: tp.width; height: tp.height; darkPane: false }
                }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 14
            Layout.topMargin: 18
            Layout.bottomMargin: 8
            Text { text: "Settings"; color: Theme.text; font.pixelSize: Theme.fontXl - 2; font.weight: Font.DemiBold; Layout.fillWidth: true }
            C.IconButton {
                id: closeBtn
                iconName: "close"
                tip: "Close settings"
                onClicked: dlg.close()
            }
        }
        C.Separator { Layout.fillWidth: true }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width - 48
                x: 24
                spacing: 12

                SectionTitle { text: "APPEARANCE" }
                // Theme cards with live mini previews
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Repeater {
                        model: [
                            { key: "system", label: "System", icon: "monitor" },
                            { key: "light", label: "Light", icon: "sun" },
                            { key: "dark", label: "Dark", icon: "moon" }
                        ]
                        AbstractButton {
                            id: tc
                            required property var modelData
                            readonly property bool active: backend.theme === modelData.key
                            Layout.fillWidth: true
                            implicitHeight: 118
                            hoverEnabled: true
                            focusPolicy: Qt.TabFocus

                            Accessible.role: Accessible.RadioButton
                            Accessible.name: modelData.label + " theme"
                            Accessible.checked: active
                            Accessible.focusable: true
                            Accessible.focused: visualFocus

                            onClicked: if (!active) dlg.appearanceChange("theme", modelData.key)
                            scale: down ? 0.97 : 1
                            Behavior on scale { NumberAnimation { duration: 90 } }
                            background: null
                            contentItem: ColumnLayout {
                                spacing: 8
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    radius: 12
                                    color: "transparent"
                                    border.width: tc.visualFocus ? 3 : (tc.active ? 2 : 1)
                                    border.color: tc.visualFocus ? Theme.brand : (tc.active ? Theme.brand : tc.hovered ? Theme.textTertiary : Theme.border)
                                    Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                                    ThemePreview {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        mode: tc.modelData.key
                                    }
                                }
                                Row {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6
                                    C.Icon { name: tc.modelData.icon; size: 13; color: tc.active ? Theme.brand : Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }
                                    Text {
                                        text: tc.modelData.label
                                        color: tc.active ? Theme.text : Theme.textSecondary
                                        font.pixelSize: Theme.fontSm + 1
                                        font.weight: tc.active ? Font.DemiBold : Font.Normal
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                SettingRow {
                    label: "Accent colour"
                    hint: Theme.accents[backend.accent] ? Theme.accents[backend.accent].label : ""
                    Row {
                        spacing: 8
                        Repeater {
                            model: Theme.accentKeys
                            AbstractButton {
                                id: swAccent
                                required property string modelData
                                readonly property bool active: backend.accent === modelData
                                width: 24; height: 24
                                hoverEnabled: true
                                focusPolicy: Qt.TabFocus

                                Accessible.role: Accessible.RadioButton
                                Accessible.name: Theme.accents[modelData].label + " accent"
                                Accessible.checked: active
                                Accessible.focusable: true
                                Accessible.focused: visualFocus

                                onClicked: if (!active) dlg.appearanceChange("accent", modelData)
                                ToolTip.visible: hovered
                                ToolTip.delay: 400
                                ToolTip.text: Theme.accents[modelData].label
                                background: Rectangle {
                                    radius: 12
                                    color: Theme.accentColor(swAccent.modelData, Theme.dark)
                                    scale: swAccent.hovered || swAccent.visualFocus ? 1.12 : 1
                                    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 30; height: 30; radius: 15
                                        color: "transparent"
                                        border.width: 2
                                        border.color: swAccent.visualFocus ? Theme.text : Theme.accentColor(swAccent.modelData, Theme.dark)
                                        opacity: swAccent.active || swAccent.visualFocus ? 1 : 0
                                        scale: swAccent.active || swAccent.visualFocus ? 1 : 0.7
                                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                                        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8; height: 8; radius: 4
                                        color: "#ffffff"
                                        opacity: swAccent.active ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                                    }
                                }
                            }
                        }
                    }
                }

                SectionTitle { text: "MODEL SELECTION" }
                SettingRow {
                    label: "Automatic mode prefers"
                    hint: "How Auto balances response speed against answer quality."
                    Segmented {
                        accessibleName: "Automatic mode prefers"
                        options: [{ key: "speed", label: "Speed" }, { key: "balanced", label: "Balanced" }, { key: "quality", label: "Quality" }]
                        value: backend.routingPreference
                        onPicked: (k) => backend.setSetting("routing_preference", k)
                    }
                }
                SettingRow {
                    label: "SmolLM3 thinking"
                    hint: "Let SmolLM3 reason step by step before answering. Slower, better on hard problems."
                    Toggle {
                        accessibleName: "SmolLM3 thinking"
                        accessibleDescription: "Let SmolLM3 reason step by step before answering. Slower, better on hard problems."
                        checked: backend.enableThinking
                        onToggled: backend.setSetting("enable_thinking", checked)
                    }
                }

                SectionTitle { text: "GENERATION" }
                SettingRow {
                    label: "Temperature  " + backend.temperature.toFixed(1)
                    hint: "Lower is more focused, higher is more creative."
                    Slider {
                        id: tempSlider
                        implicitWidth: 180
                        focusPolicy: Qt.TabFocus

                        Accessible.role: Accessible.Slider
                        Accessible.name: "Temperature"
                        Accessible.description: "Value " + backend.temperature.toFixed(1) + ". Lower is more focused, higher is more creative."
                        Accessible.focusable: true
                        Accessible.focused: visualFocus

                        handle: Rectangle {
                            x: tempSlider.leftPadding + tempSlider.visualPosition * (tempSlider.availableWidth - width)
                            y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                            width: 18; height: 18; radius: 9
                            color: "#ffffff"
                            border.width: tempSlider.visualFocus ? 2 : 1
                            border.color: tempSlider.visualFocus ? Theme.brand : Theme.border
                        }
                        background: Rectangle {
                            x: tempSlider.leftPadding
                            y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                            width: tempSlider.availableWidth
                            height: 4; radius: 2
                            color: Theme.hoverStrong
                            Rectangle { width: tempSlider.visualPosition * parent.width; height: parent.height; radius: 2; color: Theme.brand }
                        }
                        from: 0; to: 1.5; stepSize: 0.1
                        value: backend.temperature
                        onMoved: backend.setSetting("temperature", value)
                    }
                }
                SettingRow {
                    label: "Maximum response length"
                    hint: backend.maxTokens >= backend.contextLength
                          ? "Too long for the context window. Replies are limited to half of the window."
                          : ""
                    Segmented {
                        accessibleName: "Maximum response length"
                        options: [{ key: "512", label: "512" }, { key: "1024", label: "1K" }, { key: "2048", label: "2K" }, { key: "4096", label: "4K" }]
                        value: String(backend.maxTokens)
                        onPicked: (k) => backend.setSetting("max_tokens", parseInt(k))
                    }
                }
                SettingRow {
                    label: "Context window"
                    hint: "Larger windows remember more of the chat but use more memory."
                    Segmented {
                        accessibleName: "Context window"
                        options: [{ key: "2048", label: "2K" }, { key: "4096", label: "4K" }, { key: "8192", label: "8K" }]
                        value: String(backend.contextLength)
                        onPicked: (k) => backend.setSetting("context_length", parseInt(k))
                    }
                }
                SettingRow {
                    label: "Use Metal GPU acceleration"
                    hint: "Recommended on Apple Silicon. Turn off to run on the CPU only."
                    Toggle {
                        accessibleName: "Use Metal GPU acceleration"
                        accessibleDescription: "Recommended on Apple Silicon. Turn off to run on the CPU only."
                        checked: backend.useGpu
                        onToggled: backend.setSetting("use_gpu", checked)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: "System prompt"; color: Theme.text; font.pixelSize: Theme.fontMd - 1 }
                    TextArea {
                        id: systemPrompt
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        text: backend.systemPrompt
                        wrapMode: TextArea.Wrap
                        color: Theme.text
                        font.pixelSize: Theme.fontSm + 1
                        padding: 10
                        focusPolicy: Qt.StrongFocus

                        Accessible.role: Accessible.EditableText
                        Accessible.name: "System prompt"
                        Accessible.description: "System instructions given to models"
                        Accessible.focusable: true
                        Accessible.focused: activeFocus

                        background: Rectangle {
                            radius: Theme.radiusMd
                            color: "transparent"
                            border.width: systemPrompt.activeFocus ? 2 : 1
                            border.color: systemPrompt.activeFocus ? Theme.brand : Theme.borderSubtle
                        }
                        onEditingFinished: backend.setSetting("system_prompt", text)
                    }
                }

                SectionTitle { text: "STORAGE & PRIVACY" }
                SettingRow {
                    label: "Models folder"
                    hint: backend.modelsFolder
                    C.ActionButton { text: "Show in Finder"; compact: true; iconName: "folder"; onClicked: backend.revealModelsFolder() }
                }
                SettingRow {
                    label: "Manage models"
                    hint: "Download or delete models."
                    C.ActionButton { text: "Model Library"; compact: true; iconName: "library"; onClicked: { dlg.close(); dlg.openLibrary() } }
                }
                Text {
                    Layout.fillWidth: true
                    text: "SmolChat has no telemetry and no cloud services. Chats are stored only in a local database on this Mac, and the internet is used only to download models from Hugging Face."
                    color: Theme.textTertiary
                    font.pixelSize: Theme.fontXs + 1
                    wrapMode: Text.Wrap
                }

                SectionTitle { text: "ABOUT" }
                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 24
                    text: "SmolChat " + backend.appVersion + " · SmolWorks\n" + backend.hardwareSummary
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSm
                    wrapMode: Text.Wrap
                    lineHeight: 1.3
                }
            }
        }
    }
}
