import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var report: ({
        running: false,
        project: null,
        elapsed: "0m00s",
        elapsed_sec: 0,
        today: "0m00s",
        projects: []
    })

    readonly property string helper: Quickshell.env("HOME") + "/.config/scripts/freela-timer.sh"
    readonly property string pluginId: "freelaTimer"

    function t(term) {
        return I18n.trFor(pluginId, term)
    }

    function refresh() {
        proc.command = [helper, "status"]
        proc.running = false
        proc.running = true
    }

    function run() {
        const args = Array.prototype.slice.call(arguments)
        act.command = [helper].concat(args)
        act.running = false
        act.running = true
    }

    Process {
        id: proc
        command: [root.helper, "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.report = JSON.parse(text)
                } catch (e) {
                    console.warn("freelaTimer parse", e)
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
                    root.report = JSON.parse(text)
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: root.report.running ? 1000 : 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    horizontalBarPill: Row {
        spacing: Theme.spacingXS

        DankIcon {
            name: root.report.running ? "timer" : "timer_off"
            size: root.iconSize || Theme.iconSize
            color: root.report.running ? Theme.primary : Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.report.running
                  ? ((root.report.project || "?") + " " + root.report.elapsed)
                  : root.t("today %1").arg(root.report.today || "0m")
            font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    verticalBarPill: Column {
        spacing: 2
        DankIcon {
            name: "timer"
            size: root.iconSize || Theme.iconSize
            color: root.report.running ? Theme.primary : Theme.surfaceText
            anchors.horizontalCenter: parent.horizontalCenter
        }
        StyledText {
            text: root.report.running ? root.report.elapsed : "—"
            font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        Column {
            spacing: Theme.spacingS
            width: 300

            StyledText {
                text: root.t("Freela timer")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            StyledText {
                text: (root.report.running
                      ? ("▶ " + root.report.project + " · " + root.report.elapsed)
                      : root.t("Stopped"))
                      + root.t(" · today %1").arg(root.report.today)
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                width: parent.width
            }

            Row {
                spacing: Theme.spacingS
                DankButton {
                    text: root.t("Stop")
                    enabled: root.report.running
                    onClicked: root.run("stop")
                }
                DankButton {
                    text: root.t("Refresh")
                    onClicked: root.refresh()
                }
            }

            StyledText {
                text: root.t("Projects")
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            Repeater {
                model: root.report.projects || []
                delegate: Row {
                    required property var modelData
                    width: 300
                    spacing: Theme.spacingXS

                    StyledText {
                        text: (modelData.active ? "● " : "· ") + modelData.name
                              + (modelData.today_sec > 0 ? "  " + modelData.today : "")
                        color: modelData.active ? Theme.primary : Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideMiddle
                        width: parent.width - 72
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DankButton {
                        text: modelData.active ? root.t("Stop") : root.t("Start")
                        onClicked: root.run("toggle", modelData.name)
                    }
                }
            }
        }
    }
}
