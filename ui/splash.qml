import QtQuick
import QtQuick.Layouts
import "."

// Full-window splash shown while the backend initialises, then faded out.
Rectangle {
    id: splash
    color: Theme.splashBg

    property string status: ""
    property bool finished: false
    signal dismissed()

    // Keep the splash up just long enough for the fade to feel intentional,
    // without delaying startup when initialisation is fast.
    property bool minTimeElapsed: false
    Timer { interval: 650; running: true; onTriggered: splash.minTimeElapsed = true }

    readonly property bool canDismiss: finished && minTimeElapsed
    onCanDismissChanged: if (canDismiss) fadeOut.start()

    MouseArea { anchors.fill: parent; hoverEnabled: true } // swallow input

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Image {
            id: logo
            source: "../resources/icons/logo.svg"
            sourceSize: Qt.size(176, 176)
            Layout.preferredWidth: 88
            Layout.preferredHeight: 88
            Layout.alignment: Qt.AlignHCenter
            opacity: 0
            scale: 0.92
            Component.onCompleted: intro.start()
            ParallelAnimation {
                id: intro
                NumberAnimation { target: logo; property: "opacity"; to: 1; duration: 420; easing.type: Easing.OutCubic }
                NumberAnimation { target: logo; property: "scale"; to: 1; duration: 520; easing.type: Easing.OutBack }
            }
        }

        Text {
            text: "SmolChat"
            color: "#f5f5f7"
            font.family: Theme.fontFamily
            font.pixelSize: 30
            font.weight: Font.DemiBold
            font.letterSpacing: -0.4
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 22
        }

        Text {
            text: "by SmolWorks"
            color: "#8e8e93"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.letterSpacing: 0.4
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
        }

        // Thin indeterminate bar
        Rectangle {
            Layout.preferredWidth: 140
            Layout.preferredHeight: 3
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 36
            radius: 1.5
            color: "#26ffffff"
            clip: true
            Rectangle {
                id: runner
                width: 46
                height: parent.height
                radius: 1.5
                color: "#d9ffffff"
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: -46; to: 140; duration: 1050; easing.type: Easing.InOutSine }
                }
            }
        }

        Text {
            text: splash.status
            color: "#6e6e73"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14
        }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 26
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Private, on-device AI · Download once, run locally, chat offline"
        color: "#48484a"
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }

    NumberAnimation {
        id: fadeOut
        target: splash
        property: "opacity"
        to: 0
        duration: Theme.slow
        easing.type: Easing.InOutQuad
        onFinished: splash.dismissed()
    }
}
