import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

// Shared building blocks, used as C.Icon, C.IconButton, C.Button, ...
QtObject {

    // Tinted SVG icon from resources/icons via the "icon" image provider.
    component Icon: Item {
        id: icon
        property string name
        property color color: Theme.textSecondary
        property int size: 18
        implicitWidth: size
        implicitHeight: size
        width: size
        height: size
        Image {
            anchors.fill: parent
            sourceSize: Qt.size(icon.size * 2, icon.size * 2)
            source: icon.name ? "image://icon/" + icon.name + "?color=" + String(icon.color).replace("#", "") : ""
            smooth: true
            fillMode: Image.PreserveAspectFit
        }
    }

    // Square, borderless icon button with hover background and tooltip.
    component IconButton: AbstractButton {
        id: ib
        property string iconName
        property int iconSize: 18
        property color iconColor: Theme.textSecondary
        property string tip
        property bool highlighted: false
        implicitWidth: 32
        implicitHeight: 32
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        background: Rectangle {
            radius: Theme.radiusSm + 2
            color: ib.down ? Theme.hoverStrong : (ib.hovered || ib.highlighted) ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        contentItem: Item {
            Icon {
                anchors.centerIn: parent
                name: ib.iconName
                size: ib.iconSize
                color: ib.enabled ? ib.iconColor : Theme.textTertiary
                opacity: ib.enabled ? 1 : 0.5
            }
        }
        ToolTip.visible: tip !== "" && hovered
        ToolTip.delay: 600
        ToolTip.text: tip
    }

    // Text button. kind: "primary" | "secondary" | "ghost" | "danger"
    component ActionButton: AbstractButton {
        id: btn
        property string kind: "secondary"
        property string iconName
        property bool compact: false
        implicitHeight: compact ? 28 : 34
        implicitWidth: row.implicitWidth + (compact ? 20 : 28)
        hoverEnabled: true
        font.family: Theme.fontFamily
        font.pixelSize: compact ? Theme.fontSm : Theme.fontMd - 1
        font.weight: Font.Medium
        readonly property color fg: kind === "primary" ? Theme.textOnAccent
                                   : kind === "danger" ? "#ffffff" : Theme.text
        background: Rectangle {
            radius: btn.height / 2
            color: {
                if (!btn.enabled) return btn.kind === "primary" ? Theme.accentMuted : "transparent"
                if (btn.kind === "primary") return btn.hovered ? Qt.darker(Theme.accent, 1.12) : Theme.accent
                if (btn.kind === "danger") return btn.hovered ? Qt.darker(Theme.danger, 1.1) : Theme.danger
                if (btn.kind === "ghost") return btn.hovered ? Theme.hover : "transparent"
                return btn.hovered ? Theme.hover : "transparent"
            }
            border.width: btn.kind === "secondary" ? 1 : 0
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        contentItem: Item {
            implicitWidth: row.implicitWidth
            implicitHeight: row.implicitHeight
            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6
                Icon {
                    visible: btn.iconName !== ""
                    name: btn.iconName
                    size: btn.compact ? 14 : 16
                    color: btn.fg
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: btn.text
                    font: btn.font
                    color: btn.fg
                    opacity: btn.enabled ? 1 : 0.6
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // Small pill label.
    component Badge: Rectangle {
        property alias text: label.text
        property color tint: Theme.textSecondary
        implicitWidth: label.implicitWidth + 12
        implicitHeight: 20
        radius: 10
        color: Theme.dark ? Qt.rgba(tint.r, tint.g, tint.b, 0.12) : Qt.rgba(tint.r, tint.g, tint.b, 0.10)
        Text {
            id: label
            anchors.centerIn: parent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontXs
            font.weight: Font.Medium
            color: parent.tint
        }
    }

    component Separator: Rectangle {
        implicitHeight: 1
        implicitWidth: 1
        color: Theme.borderSubtle
    }

    // Thin progress bar. While `indeterminate` (e.g. connecting) a short runner
    // sweeps across; otherwise the fill grows from the left edge with `value`.
    component SlimProgress: Rectangle {
        id: bar
        property real value: 0
        property bool indeterminate: false
        implicitHeight: 6
        radius: height / 2
        color: Theme.hoverStrong
        clip: true

        Rectangle {
            visible: !bar.indeterminate
            x: 0
            height: parent.height
            radius: parent.radius
            color: Theme.brand
            // Keep tiny but non-zero progress visible on slow connections.
            width: bar.value > 0 ? Math.max(bar.height, bar.width * Math.min(1, bar.value)) : 0
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            id: runner
            visible: bar.indeterminate
            width: bar.width * 0.3
            height: parent.height
            radius: parent.radius
            color: Theme.brand
            NumberAnimation on x {
                running: bar.indeterminate && bar.visible
                loops: Animation.Infinite
                from: -runner.width
                to: bar.width
                duration: 1100
                easing.type: Easing.InOutQuad
            }
        }
    }

    // Styled text field (used for search and rename).
    component Field: TextField {
        id: field
        property string iconName
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMd - 1
        color: Theme.text
        placeholderTextColor: Theme.textTertiary
        selectionColor: Theme.brand
        selectedTextColor: "#ffffff"
        leftPadding: iconName ? 32 : 10
        rightPadding: 10
        implicitHeight: 34
        background: Rectangle {
            radius: Theme.radiusMd
            color: Theme.dark ? "#00000000" : "#00ffffff"
            border.width: 1
            border.color: field.activeFocus ? Theme.textTertiary : Theme.borderSubtle
            Icon {
                visible: field.iconName !== ""
                name: field.iconName
                size: 15
                color: Theme.textTertiary
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component MenuItemStyled: MenuItem {
        id: mi
        property string iconName
        property bool destructive: false
        property bool checkedMark: false
        property string detail
        implicitHeight: detail ? 46 : 34
        implicitWidth: 240
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMd - 1
        background: Rectangle {
            radius: Theme.radiusSm + 2
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            color: mi.highlighted ? Theme.hoverStrong : "transparent"
        }
        contentItem: RowLayout {
            spacing: 10
            Icon {
                visible: mi.iconName !== ""
                name: mi.iconName
                size: 16
                color: mi.destructive ? Theme.danger : Theme.textSecondary
                Layout.leftMargin: 6
            }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Layout.leftMargin: mi.iconName ? 0 : 6
                Text {
                    text: mi.text
                    font: mi.font
                    color: mi.destructive ? Theme.danger : Theme.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: mi.detail !== ""
                    text: mi.detail
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontXs
                    color: Theme.textTertiary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Icon {
                visible: mi.checkedMark
                name: "check"
                size: 15
                color: Theme.text
                Layout.rightMargin: 8
            }
        }
        indicator: null
        arrow: null
    }

    component MenuStyled: Menu {
        id: menu
        padding: 5
        implicitWidth: 260
        delegate: MenuItemStyled {}
        background: Rectangle {
            implicitWidth: 220
            color: Theme.popup
            radius: Theme.radiusMd + 2
            border.color: Theme.border
            border.width: 1
        }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }
    }

    component MenuSeparatorStyled: MenuSeparator {
        contentItem: Rectangle { implicitHeight: 1; color: Theme.borderSubtle }
        topPadding: 4
        bottomPadding: 4
    }

    // Modal confirmation dialog.
    component ConfirmDialog: Popup {
        id: dlg
        property string title
        property string message
        property string confirmText: "Confirm"
        property string cancelText: "Cancel"
        property bool destructive: false
        property string extraText: ""  // optional third action
        signal confirmed()
        signal extra()
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        padding: 22
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: Theme.overlay }
        background: Rectangle {
            color: Theme.popup
            radius: Theme.radiusLg
            border.color: Theme.border
        }
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
            NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: Theme.normal; easing.type: Easing.OutCubic }
        }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast } }
        contentItem: ColumnLayout {
            spacing: 10
            Text {
                text: dlg.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLg
                font.weight: Font.DemiBold
                color: Theme.text
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Text {
                text: dlg.message
                visible: text !== ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMd - 1
                color: Theme.textSecondary
                wrapMode: Text.Wrap
                lineHeight: 1.2
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.topMargin: 12
                spacing: 8
                Item { Layout.fillWidth: true }
                ActionButton {
                    text: dlg.cancelText
                    kind: "secondary"
                    onClicked: dlg.close()
                }
                ActionButton {
                    visible: dlg.extraText !== ""
                    text: dlg.extraText
                    kind: "secondary"
                    onClicked: { dlg.close(); dlg.extra() }
                }
                ActionButton {
                    visible: dlg.confirmText !== ""
                    text: dlg.confirmText
                    kind: dlg.destructive ? "danger" : "primary"
                    onClicked: { dlg.close(); dlg.confirmed() }
                }
            }
        }
    }

    // Three softly pulsing dots used while a model is loading/thinking.
    component LoadingDots: Row {
        property color color: Theme.textTertiary
        property int dot: 6
        spacing: 5
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: parent.dot
                height: parent.dot
                radius: width / 2
                color: parent.color
                opacity: 0.25
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 160 }
                    NumberAnimation { to: 1; duration: 380; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.25; duration: 380; easing.type: Easing.InOutQuad }
                    PauseAnimation { duration: (2 - index) * 160 }
                }
            }
        }
    }
}
