import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var status: ({
        connected: false,
        recording: false,
        streaming: false,
        paused: false,
        duration_sec: 0
    })

    readonly property string helper: Quickshell.env("HOME") + "/.config/scripts/obs-rec-status.py"
    readonly property bool hot: status.recording || status.streaming
    readonly property bool live: status.connected && hot

    function refresh() {
        proc.command = [helper, "status"]
        proc.running = false
        proc.running = true
    }

    function runAction(action) {
        act.command = [helper, action]
        act.running = false
        act.running = true
    }

    function fmtDur(sec) {
        sec = Number(sec) || 0
        const h = Math.floor(sec / 3600)
        const m = Math.floor((sec % 3600) / 60)
        const s = sec % 60
        if (h > 0)
            return h + ":" + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0")
    }

    Process {
        id: proc
        command: [root.helper, "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text)
                } catch (e) {
                    console.warn("obsRec parse", e)
                }
            }
        }
    }

    Process {
        id: act
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text)
                } catch (e) {}
                root.refresh()
            }
        }
    }

    Timer {
        interval: root.live ? 1000 : 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    horizontalBarPill: Item {
        visible: root.status.connected
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            spacing: Theme.spacingXS

            DankIcon {
                name: root.status.streaming ? "cell_tower" : (root.status.paused ? "pause_circle" : "fiber_manual_record")
                size: root.iconSize || Theme.iconSize
                color: root.status.paused ? Theme.warning : Theme.error
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.status.recording || root.status.streaming
                text: root.status.streaming && !root.status.recording
                      ? "LIVE"
                      : (root.status.paused ? "REC ‖" : "REC " + root.fmtDur(root.status.duration_sec))
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: root.status.paused ? Theme.warning : Theme.error
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton)
                    root.runAction("stop")
                else if (root.status.recording || root.status.paused)
                    root.runAction("toggle-pause")
                else
                    root.runAction("toggle-record")
            }
        }
    }

    verticalBarPill: Column {
        spacing: 2
        visible: root.status.connected
        DankIcon {
            name: "fiber_manual_record"
            size: root.iconSize || Theme.iconSize
            color: root.hot ? Theme.error : Theme.surfaceText
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        Column {
            spacing: Theme.spacingS
            width: 260

            StyledText {
                text: "OBS"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            StyledText {
                text: !root.status.connected
                      ? "OBS offline"
                      : (root.status.recording
                         ? (root.status.paused ? "Gravando (pausado) " : "Gravando ") + root.fmtDur(root.status.duration_sec)
                         : "Conectado · não gravando")
                      + (root.status.streaming ? " · LIVE" : "")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                width: parent.width
            }

            Row {
                spacing: Theme.spacingS
                DankButton {
                    text: root.status.recording || root.status.paused ? "Pause/Resume" : "Rec"
                    onClicked: root.runAction(root.status.recording || root.status.paused ? "toggle-pause" : "toggle-record")
                }
                DankButton {
                    text: "Stop"
                    enabled: root.status.recording || root.status.paused
                    onClicked: root.runAction("stop")
                }
                DankButton {
                    text: "Atualizar"
                    onClicked: root.refresh()
                }
            }
        }
    }
}
