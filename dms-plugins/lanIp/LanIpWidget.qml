import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string fallbackIp: ""
    property string toastMsg: ""
    readonly property string pluginId: "lanIp"

    function t(term) {
        return I18n.trFor(pluginId, term)
    }

    readonly property string localIp: {
        const status = NetworkService.networkStatus || "";
        if (status === "ethernet" && NetworkService.ethernetIP)
            return NetworkService.ethernetIP;
        if ((status === "wifi" || status === "wireless") && NetworkService.wifiIP)
            return NetworkService.wifiIP;
        if (NetworkService.ethernetIP)
            return NetworkService.ethernetIP;
        if (NetworkService.wifiIP)
            return NetworkService.wifiIP;
        if (NetworkService.cellularIP)
            return NetworkService.cellularIP;
        return root.fallbackIp;
    }

    readonly property string networkIconName: {
        if (NetworkService.wifiToggling)
            return "sync";
        switch (NetworkService.networkStatus) {
        case "ethernet":
            return "lan";
        case "cellular":
            return "network_cell";
        default:
            return NetworkService.wifiSignalIcon || "wifi";
        }
    }

    readonly property string tooltipText: {
        const ip = root.localIp;
        if (!ip)
            return root.t("No IP · disconnected?");
        const kind = NetworkService.networkStatus || root.t("network");
        return root.t("%1 · %2 · click to copy").arg(ip).arg(kind);
    }

    function refreshFallback() {
        ipProc.running = false;
        ipProc.running = true;
    }

    function copyIp() {
        const ip = root.localIp;
        if (!ip) {
            root.toastMsg = root.t("No IP to copy");
            toastClear.restart();
            return;
        }
        Quickshell.execDetached(["wl-copy", ip]);
        root.toastMsg = root.t("Copied: %1").arg(ip);
        toastClear.restart();
    }

    Process {
        id: ipProc
        command: [
            "sh", "-c",
            "ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"src\"){print $(i+1); exit}}'"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const ip = (text || "").trim();
                if (/^\d+\.\d+\.\d+\.\d+$/.test(ip))
                    root.fallbackIp = ip;
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refreshFallback()
    }

    Timer {
        id: toastClear
        interval: 2500
        onTriggered: root.toastMsg = ""
    }

    horizontalBarPill: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: Math.max(row.implicitHeight, root.iconSize || Theme.iconSize)

        Row {
            id: row
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                name: root.networkIconName
                size: root.iconSize || Theme.iconSize
                color: NetworkService.networkStatus !== "disconnected"
                       ? Theme.primary
                       : Theme.widgetIconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.localIp.length > 0
                text: root.localIp
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor || Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Loader {
            id: tipLoader
            active: false
            sourceComponent: DankTooltip {}
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copyIp()
            onEntered: {
                tipLoader.active = true;
                if (!tipLoader.item || !root.parentScreen)
                    return;
                const localPos = mapToItem(null, width / 2, 0);
                const screen = root.parentScreen || Screen;
                const isBottom = root.axis?.edge === "bottom";
                let tipY;
                if (isBottom) {
                    const tipH = Theme.fontSizeSmall * 1.5 + Theme.spacingS * 2;
                    tipY = screen.height - root.barThickness - root.barSpacing - Theme.spacingXS - tipH;
                } else {
                    tipY = root.barThickness + root.barSpacing + Theme.spacingXS;
                }
                tipLoader.item.show(root.tooltipText, localPos.x, tipY, screen, false, false);
            }
            onExited: {
                if (tipLoader.item)
                    tipLoader.item.hide();
                tipLoader.active = false;
            }
        }
    }

    verticalBarPill: Column {
        spacing: Theme.spacingXXS
        DankIcon {
            name: root.networkIconName
            size: root.iconSize || Theme.iconSize
            color: NetworkService.networkStatus !== "disconnected"
                   ? Theme.primary
                   : Theme.widgetIconColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
        StyledText {
            visible: root.localIp.length > 0
            text: root.localIp.split(".").slice(-1)[0] || ""
            font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
            color: Theme.widgetTextColor || Theme.surfaceText
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutContent: Component {
        Column {
            spacing: Theme.spacingS
            width: 280

            StyledText {
                text: root.t("Local IP")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
                color: Theme.surfaceText
            }

            StyledText {
                text: root.localIp || "—"
                font.pixelSize: Theme.fontSizeLarge
                font.family: Theme.monoFontFamily || Theme.fontFamily
                color: Theme.primary
            }

            StyledText {
                text: root.t("Status: %1").arg(NetworkService.networkStatus || root.t("unknown"))
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                opacity: 0.75
            }

            StyledText {
                visible: root.toastMsg.length > 0
                text: root.toastMsg
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primary
            }

            Rectangle {
                width: parent.width
                height: 36
                radius: Theme.cornerRadius
                color: copyMa.containsMouse ? Theme.primaryHover : Theme.surfaceContainerHigh

                StyledText {
                    anchors.centerIn: parent
                    text: root.t("Copy IP")
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                }

                MouseArea {
                    id: copyMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.copyIp()
                }
            }
        }
    }
}
