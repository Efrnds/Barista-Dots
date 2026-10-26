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
        summary: { without_rtk: 0, with_rtk: 0, projects_total: 0, saved_tokens_all: 0 },
        without_rtk: [],
        with_rtk: []
    })
    property string statusMsg: ""
    property string busyPath: ""

    readonly property string rtkBin: Quickshell.env("HOME") + "/.local/bin/rtk"
    readonly property string rtkBarBin: Quickshell.env("HOME") + "/.local/bin/rtk-bar"

    function refresh() {
        proc.running = false
        proc.running = true
    }

    function fmtTokens(n) {
        n = Number(n) || 0
        if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
        if (n >= 1e3) return (n / 1e3).toFixed(1) + "k"
        return String(Math.round(n))
    }

    function openFolder(path) {
        if (!path) return
        Quickshell.execDetached(["xdg-open", path])
    }

    function activateRtk(path, name) {
        if (!path || root.busyPath !== "") return
        root.busyPath = path
        root.statusMsg = "Ativando RTK em " + (name || path) + "…"
        initProc.command = [
            "sh", "-c",
            "cd \"$1\" && \"$2\" init --claude-md --auto-patch",
            "sh", path, root.rtkBin
        ]
        initProc.running = true
    }

    Process {
        id: proc
        // DMS PATH is only /usr/local/bin:/usr/bin — use absolute path
        command: [root.rtkBarBin]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.report = JSON.parse(text)
                } catch (e) {
                    console.warn("rtkStatus parse error", e)
                }
            }
        }
    }

    Process {
        id: initProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (text || "").trim()
                root.busyPath = ""
                root.statusMsg = out.length ? out.split("\n")[0] : "RTK ativado"
                root.refresh()
                statusClear.restart()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (root.busyPath === "") return
                const err = (text || "").trim()
                if (err.length)
                    root.statusMsg = err.split("\n")[0]
            }
        }
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0 && root.busyPath !== "") {
                root.busyPath = ""
                if (!root.statusMsg || root.statusMsg.startsWith("Ativando"))
                    root.statusMsg = "Falha ao ativar RTK (exit " + exitCode + ")"
                statusClear.restart()
            }
        }
    }

    Timer {
        id: statusClear
        interval: 4000
        onTriggered: root.statusMsg = ""
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    component ProjectRow: Row {
        id: row
        property var project: ({})
        property bool showActivate: false
        width: 320
        spacing: Theme.spacingXS

        StyledText {
            text: "· " + (row.project.name || row.project.path || "")
                  + (row.project.saved_tokens ? "  " + root.fmtTokens(row.project.saved_tokens) : "")
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideMiddle
            width: parent.width - 56
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 24
            height: 24
            radius: Theme.cornerRadius
            color: folderMa.containsMouse ? Theme.surfaceHover : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: "folder_open"
                size: 14
                color: Theme.surfaceText
            }
            MouseArea {
                id: folderMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openFolder(row.project.path)
            }
        }

        Rectangle {
            visible: row.showActivate
            width: 24
            height: 24
            radius: Theme.cornerRadius
            color: {
                if (root.busyPath === row.project.path) return Theme.primaryHover
                return activateMa.containsMouse ? Theme.surfaceHover : "transparent"
            }
            opacity: root.busyPath !== "" && root.busyPath !== row.project.path ? 0.4 : 1
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: root.busyPath === row.project.path ? "hourglass_empty" : "savings"
                size: 14
                color: Theme.warning
            }
            MouseArea {
                id: activateMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.busyPath === "" ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                enabled: root.busyPath === ""
                onClicked: root.activateRtk(row.project.path, row.project.name)
            }
        }
    }

    horizontalBarPill: Row {
        spacing: Theme.spacingXS

        DankIcon {
            name: "savings"
            size: root.iconSize || Theme.iconSize
            color: (root.report.summary.without_rtk || 0) > 0 ? Theme.warning : Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: (root.report.summary.without_rtk || 0) > 0
                  ? (root.report.summary.without_rtk + " sem RTK")
                  : (root.fmtTokens(root.report.summary.saved_tokens_all) + " saved")
            font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    verticalBarPill: Column {
        spacing: Theme.spacingXS
        DankIcon {
            name: "savings"
            size: root.iconSize || Theme.iconSize
            color: (root.report.summary.without_rtk || 0) > 0 ? Theme.warning : Theme.primary
            anchors.horizontalCenter: parent.horizontalCenter
        }
        StyledText {
            text: String(root.report.summary.without_rtk || 0)
            font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        Column {
            spacing: Theme.spacingS
            width: 320

            StyledText {
                text: "RTK · projetos"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            StyledText {
                text: (root.report.summary.with_rtk || 0) + " com RTK · "
                      + (root.report.summary.without_rtk || 0) + " sem · "
                      + root.fmtTokens(root.report.summary.saved_tokens_all) + " tokens salvos"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                opacity: 0.8
                wrapMode: Text.Wrap
                width: parent.width
            }

            StyledText {
                visible: root.statusMsg.length > 0
                text: root.statusMsg
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primary
                wrapMode: Text.Wrap
                width: parent.width
            }

            StyledText {
                visible: (root.report.without_rtk || []).length > 0
                text: "Sem RTK"
                font.weight: Font.DemiBold
                color: Theme.warning
            }

            Repeater {
                model: root.report.without_rtk || []
                delegate: ProjectRow {
                    required property var modelData
                    project: modelData
                    showActivate: true
                }
            }

            StyledText {
                visible: (root.report.with_rtk || []).length > 0
                text: "Top savings"
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            Repeater {
                model: (root.report.with_rtk || []).slice(0, 8)
                delegate: ProjectRow {
                    required property var modelData
                    project: modelData
                    showActivate: false
                }
            }

            Row {
                spacing: Theme.spacingS
                DankButton {
                    text: "Atualizar"
                    onClicked: root.refresh()
                }
            }
        }
    }
}
