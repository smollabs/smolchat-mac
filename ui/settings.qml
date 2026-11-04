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

    signal openLibrary()

    Overlay.modal: Rectangle { color: Theme.overlay }
    background: Rectangle { color: Theme.popup; radius: Theme.radiusLg + 2; border.color: Theme.border }
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
        signal picked(string key)
        spacing: 2
        Repeater {
            model: seg.options
            AbstractButton {
                id: sb
                required property var modelData
                readonly property bool active: seg.value === modelData.key
                implicitHeight: 28
                implicitWidth: sbText.implicitWidth + 22
                hoverEnabled: true
                onClicked: seg.picked(modelData.key)
                background: Rectangle {
                    radius: 8
                    color: sb.active ? Theme.hoverStrong : sb.hovered ? Theme.hover : "transparent"
                    border.color: sb.active ? Theme.border : "transparent"
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
        implicitWidth: 40
        implicitHeight: 24
        indicator: Rectangle {
            implicitWidth: 38
            implicitHeight: 22
            radius: 11
            color: sw.checked ? Theme.success : Theme.hoverStrong
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

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 14
            Layout.topMargin: 18
            Layout.bottomMargin: 8
            Text { text: "Settings"; color: Theme.text; font.pixelSize: Theme.fontXl - 2; font.weight: Font.DemiBold; Layout.fillWidth: true }
            C.IconButton { iconName: "close"; tip: "Close"; onClicked: dlg.close() }
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
                SettingRow {
                    label: "Theme"
                    Segmented {
                        options: [{ key: "dark", label: "Dark" }, { key: "light", label: "Light" }]
                        value: backend.theme
                        onPicked: (k) => backend.setSetting("theme", k)
                    }
                }

                SectionTitle { text: "MODEL SELECTION" }
                SettingRow {
                    label: "Automatic mode prefers"
                    hint: "How Auto balances response speed against answer quality."
                    Segmented {
                        options: [{ key: "speed", label: "Speed" }, { key: "balanced", label: "Balanced" }, { key: "quality", label: "Quality" }]
                        value: backend.routingPreference
                        onPicked: (k) => backend.setSetting("routing_preference", k)
                    }
                }
                SettingRow {
                    label: "SmolLM3 thinking"
                    hint: "Let SmolLM3 reason step by step before answering. Slower, better on hard problems."
                    Toggle { checked: backend.enableThinking; onToggled: backend.setSetting("enable_thinking", checked) }
                }

                SectionTitle { text: "GENERATION" }
                SettingRow {
                    label: "Temperature  " + backend.temperature.toFixed(1)
                    hint: "Lower is more focused, higher is more creative."
                    Slider {
                        id: tempSlider
                        implicitWidth: 180
                        handle: Rectangle {
                            x: tempSlider.leftPadding + tempSlider.visualPosition * (tempSlider.availableWidth - width)
                            y: tempSlider.topPadding + tempSlider.availableHeight / 2 - height / 2
                            width: 18; height: 18; radius: 9
                            color: "#ffffff"
                            border.color: Theme.border
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
                    Segmented {
                        options: [{ key: "512", label: "512" }, { key: "1024", label: "1K" }, { key: "2048", label: "2K" }, { key: "4096", label: "4K" }]
                        value: String(backend.maxTokens)
                        onPicked: (k) => backend.setSetting("max_tokens", parseInt(k))
                    }
                }
                SettingRow {
                    label: "Context window"
                    hint: "Larger windows remember more of the chat but use more memory."
                    Segmented {
                        options: [{ key: "2048", label: "2K" }, { key: "4096", label: "4K" }, { key: "8192", label: "8K" }]
                        value: String(backend.contextLength)
                        onPicked: (k) => backend.setSetting("context_length", parseInt(k))
                    }
                }
                SettingRow {
                    label: "Use Metal GPU acceleration"
                    hint: "Recommended on Apple Silicon. Turn off to run on the CPU only."
                    Toggle { checked: backend.useGpu; onToggled: backend.setSetting("use_gpu", checked) }
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
                        background: Rectangle { radius: Theme.radiusMd; color: "transparent"; border.color: systemPrompt.activeFocus ? Theme.textTertiary : Theme.borderSubtle }
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
