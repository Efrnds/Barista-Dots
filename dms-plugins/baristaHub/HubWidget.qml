import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string tab: "freela" // freela | obs | rtk
    property string statusMsg: ""
    property string busyPath: ""
    property string invoiceMsg: ""

    property var freela: ({
        running: false, project: null, elapsed: "0m00s", elapsed_sec: 0,
        today: "0m00s", projects: []
    })
    property var obs: ({
        connected: false, recording: false, streaming: false, paused: false, duration_sec: 0
    })
    property var rtk: ({
        summary: { without_rtk: 0, with_rtk: 0, saved_tokens_all: 0 },
        without_rtk: [], with_rtk: []
    })

    readonly property string home: Quickshell.env("HOME")
    readonly property string freelaBin: home + "/.config/scripts/freela-timer.sh"
    readonly property string obsBin: home + "/.config/scripts/obs-rec-status.py"
    readonly property string rtkBarBin: home + "/.local/bin/rtk-bar"
    readonly property string rtkBin: home + "/.local/bin/rtk"
    readonly property string pluginId: "baristaHub"

    function t(term) {
        return I18n.trFor(pluginId, term)
    }

    readonly property string pillText: {
        if (obs.recording || obs.streaming)
            return obs.paused ? "REC ‖" : ("REC " + fmtDur(obs.duration_sec))
        if (freela.running)
            return (freela.project || "freela") + " " + freela.elapsed
        if ((rtk.summary.without_rtk || 0) > 0)
            return rtk.summary.without_rtk + " RTK"
        return "Hub"
    }

    readonly property color pillColor: {
        if (obs.recording || obs.streaming)
            return obs.paused ? Theme.warning : Theme.error
        if (freela.running)
            return Theme.primary
        if ((rtk.summary.without_rtk || 0) > 0)
            return Theme.warning
        return Theme.widgetTextColor || Theme.surfaceText
    }

    function fmtTokens(n) {
        n = Number(n) || 0
        if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
        if (n >= 1e3) return (n / 1e3).toFixed(1) + "k"
        return String(Math.round(n))
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

    function refreshAll() {
        freelaProc.running = false; freelaProc.running = true
        obsProc.running = false; obsProc.running = true
        rtkProc.running = false; rtkProc.running = true
    }

    function freelaCmd() {
        const args = Array.prototype.slice.call(arguments)
        freelaAct.command = [freelaBin].concat(args)
        freelaAct.running = false
        freelaAct.running = true
    }

    function obsCmd(action) {
        obsAct.command = [obsBin, action]
        obsAct.running = false
        obsAct.running = true
    }

    function openFolder(path) {
        if (path) Quickshell.execDetached(["xdg-open", path])
    }

    function activateRtk(path, name) {
        if (!path || root.busyPath !== "") return
        root.busyPath = path
        root.statusMsg = root.t("Activating RTK in %1…").arg(name || path)
        rtkInit.command = [
            "sh", "-c",
            "cd \"$1\" && \"$2\" init --claude-md --auto-patch",
            "sh", path, root.rtkBin
        ]
        rtkInit.running = true
    }

    function invoice(period) {
        root.invoiceMsg = root.t("Generating invoice…")
        invoiceAct.command = [freelaBin, "invoice", period]
        invoiceAct.running = false
        invoiceAct.running = true
    }

    Process {
        id: freelaProc
        command: [root.freelaBin, "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.freela = JSON.parse(text) } catch (e) {}
            }
        }
    }
    Process {
        id: obsProc
        command: [root.obsBin, "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.obs = JSON.parse(text) } catch (e) {}
            }
        }
    }
    Process {
        id: rtkProc
        command: [root.rtkBarBin]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.rtk = JSON.parse(text) } catch (e) {}
            }
        }
    }

    Process {
        id: freelaAct
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.freela = JSON.parse(text) } catch (e) {}
            }
        }
    }
    Process {
        id: obsAct
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.obs = JSON.parse(text) } catch (e) {}
            }
        }
    }
    Process {
        id: invoiceAct
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    if (d.path_md) {
                        root.invoiceMsg = root.t("Invoice: %1 → %2").arg(d.total).arg(d.path_md)
                        root.openFolder(d.path_md)
                    } else {
                        root.invoiceMsg = d.error || root.t("failed")
                    }
                } catch (e) {
                    root.invoiceMsg = root.t("error generating invoice")
                }
                msgClear.restart()
            }
        }
    }
    Process {
        id: rtkInit
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.busyPath = ""
                root.statusMsg = ((text || "").trim().split("\n")[0]) || root.t("RTK ok")
                rtkProc.running = false; rtkProc.running = true
                msgClear.restart()
            }
        }
        onExited: function (code) {
            if (code !== 0 && root.busyPath !== "") {
                root.busyPath = ""
                root.statusMsg = root.t("RTK failed")
                msgClear.restart()
            }
        }
    }

    Timer {
        id: msgClear
        interval: 5000
        onTriggered: { root.statusMsg = ""; root.invoiceMsg = "" }
    }

    Timer {
        interval: (root.obs.recording || root.freela.running) ? 1000 : 8000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    component TabBtn: Rectangle {
        property string label: ""
        property string key: ""
        property bool active: root.tab === key
        signal activated
        width: tabLabel.implicitWidth + 16
        height: 28
        radius: Theme.cornerRadius
        color: active ? Theme.primaryHover : (ma.containsMouse ? Theme.surfaceHover : "transparent")
        StyledText {
            id: tabLabel
            anchors.centerIn: parent
            text: label
            font.pixelSize: Theme.fontSizeSmall
            font.weight: active ? Font.DemiBold : Font.Normal
            color: active ? Theme.primary : Theme.surfaceText
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

    component IconBtn: Rectangle {
        property string icon: ""
        property color iconColor: Theme.surfaceText
        signal activated
        width: 24; height: 24
        radius: Theme.cornerRadius
        color: ma.containsMouse ? Theme.surfaceHover : "transparent"
        DankIcon {
            anchors.centerIn: parent
            name: icon
            size: 14
            color: iconColor
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

    horizontalBarPill: Row {
        spacing: Theme.spacingXS

        DankIcon {
            name: root.obs.recording || root.obs.streaming ? "fiber_manual_record"
                  : (root.freela.running ? "timer" : "apps")
            size: root.iconSize || Theme.iconSize
            color: root.pillColor
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.pillText
            font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            color: root.pillColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    verticalBarPill: Column {
        spacing: 2
        DankIcon {
            name: "apps"
            size: root.iconSize || Theme.iconSize
            color: root.pillColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        Column {
            spacing: Theme.spacingS
            width: 340

            StyledText {
                text: "Barista Hub"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            Row {
                spacing: Theme.spacingXS
                TabBtn { label: "Freela"; key: "freela"; onActivated: root.tab = "freela" }
                TabBtn { label: "OBS"; key: "obs"; onActivated: root.tab = "obs" }
                TabBtn { label: "RTK"; key: "rtk"; onActivated: root.tab = "rtk" }
            }

            StyledText {
                visible: root.statusMsg.length > 0 || root.invoiceMsg.length > 0
                text: root.invoiceMsg || root.statusMsg
                color: Theme.primary
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                width: parent.width
            }

            Column {
                visible: root.tab === "freela"
                spacing: Theme.spacingS
                width: parent.width

                StyledText {
                    text: root.freela.running
                          ? ("▶ " + root.freela.project + " · " + root.freela.elapsed)
                          : root.t("Stopped · today %1").arg(root.freela.today)
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    width: parent.width
                }

                Row {
                    spacing: Theme.spacingS
                    DankButton {
                        text: root.t("Stop")
                        enabled: root.freela.running
                        onClicked: root.freelaCmd("stop")
                    }
                    DankButton {
                        text: root.t("Invoice week")
                        onClicked: root.invoice("week")
                    }
                    DankButton {
                        text: root.t("Invoice today")
                        onClicked: root.invoice("today")
                    }
                }

                StyledText {
                    text: root.t("Projects")
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }

                Repeater {
                    model: root.freela.projects || []
                    delegate: Row {
                        required property var modelData
                        width: 340
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
                            onClicked: root.freelaCmd("toggle", modelData.name)
                        }
                    }
                }
            }

            Column {
                visible: root.tab === "obs"
                spacing: Theme.spacingS
                width: parent.width

                StyledText {
                    text: !root.obs.connected
                          ? root.t("OBS offline")
                          : (root.obs.recording
                             ? ((root.obs.paused ? root.t("Paused ") : root.t("Recording ")) + root.fmtDur(root.obs.duration_sec))
                             : root.t("Connected · idle"))
                          + (root.obs.streaming ? " · LIVE" : "")
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    width: parent.width
                }

                Row {
                    spacing: Theme.spacingS
                    DankButton {
                        text: root.obs.recording || root.obs.paused ? root.t("Pause/Resume") : root.t("Rec")
                        enabled: root.obs.connected
                        onClicked: root.obsCmd(root.obs.recording || root.obs.paused ? "toggle-pause" : "toggle-record")
                    }
                    DankButton {
                        text: root.t("Stop")
                        enabled: root.obs.connected && (root.obs.recording || root.obs.paused)
                        onClicked: root.obsCmd("stop")
                    }
                }
            }

            Column {
                visible: root.tab === "rtk"
                spacing: Theme.spacingS
                width: parent.width

                StyledText {
                    text: root.t("%1 with · %2 without · %3 saved")
                          .arg(root.rtk.summary.with_rtk || 0)
                          .arg(root.rtk.summary.without_rtk || 0)
                          .arg(root.fmtTokens(root.rtk.summary.saved_tokens_all))
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    width: parent.width
                }

                StyledText {
                    visible: (root.rtk.without_rtk || []).length > 0
                    text: root.t("Without RTK")
                    font.weight: Font.DemiBold
                    color: Theme.warning
                }

                Repeater {
                    model: root.rtk.without_rtk || []
                    delegate: Row {
                        required property var modelData
                        width: 340
                        spacing: Theme.spacingXS
                        StyledText {
                            text: "· " + (modelData.name || "")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideMiddle
                            width: parent.width - 56
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        IconBtn {
                            icon: "folder_open"
                            onActivated: root.openFolder(modelData.path)
                        }
                        IconBtn {
                            icon: "savings"
                            iconColor: Theme.warning
                            onActivated: root.activateRtk(modelData.path, modelData.name)
                        }
                    }
                }

                StyledText {
                    visible: (root.rtk.with_rtk || []).length > 0
                    text: root.t("Top savings")
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }

                Repeater {
                    model: (root.rtk.with_rtk || []).slice(0, 6)
                    delegate: Row {
                        required property var modelData
                        width: 340
                        spacing: Theme.spacingXS
                        StyledText {
                            text: "· " + (modelData.name || "") + "  " + root.fmtTokens(modelData.saved_tokens)
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideMiddle
                            width: parent.width - 28
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        IconBtn {
                            icon: "folder_open"
                            onActivated: root.openFolder(modelData.path)
                        }
                    }
                }
            }

            DankButton {
                text: root.t("Refresh")
                onClicked: root.refreshAll()
            }
        }
    }
}
