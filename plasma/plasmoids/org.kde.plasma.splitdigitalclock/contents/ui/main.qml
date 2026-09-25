import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property date currentTime: new Date()
    readonly property var cfg: Plasmoid.configuration
    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    readonly property string timeFormat: {
        var format
        if (cfg.use24hFormat === 2) {
            format = "hh:mm"
        } else if (cfg.use24hFormat === 0) {
            format = "h:mm AP"
        } else {
            format = Qt.locale().timeFormat(Locale.ShortFormat)
        }
        if (cfg.showSeconds && format.indexOf("ss") < 0) {
            format = format.replace(/(m+)/, "$1:ss")
        }
        return format
    }

    readonly property string dateText: {
        switch (cfg.dateFormat) {
        case "longDate": return currentTime.toLocaleDateString(Qt.locale(), Locale.LongFormat)
        case "isoDate": return Qt.formatDate(currentTime, "yyyy-MM-dd")
        case "custom": return Qt.formatDate(currentTime, cfg.customDateFormat)
        default: return currentTime.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.currentTime = new Date()
    }

    toolTipMainText: Qt.formatTime(currentTime, timeFormat)
    toolTipSubText: currentTime.toLocaleDateString(Qt.locale(), Locale.LongFormat)

    compactRepresentation: MouseArea {
        id: compact

        readonly property color textColor: root.cfg.backgroundColorCheckBox ? root.cfg.backgroundColor : Kirigami.Theme.textColor

        Layout.minimumWidth: root.isVertical ? 0 : row.implicitWidth
        Layout.minimumHeight: root.isVertical ? column.implicitHeight : 0
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        component ClockLabel: PlasmaComponents.Label {
            color: compact.textColor
            font.family: root.cfg.fontFamily || Kirigami.Theme.defaultFont.family
            font.bold: root.cfg.boldText
            font.italic: root.cfg.italicText
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            id: row
            visible: !root.isVertical
            anchors.centerIn: parent
            height: parent.height
            spacing: Kirigami.Units.smallSpacing

            ClockLabel {
                visible: root.cfg.showDate
                text: root.dateText
                font.pixelSize: Math.round(timeLabel.font.pixelSize * 0.8)
            }
            Rectangle {
                visible: root.cfg.showDate && root.cfg.showSeparator
                Layout.preferredWidth: 1
                Layout.preferredHeight: timeLabel.font.pixelSize * 1.2
                color: Kirigami.Theme.textColor
                opacity: 0.4
            }
            ClockLabel {
                id: timeLabel
                text: Qt.formatTime(root.currentTime, root.timeFormat)
                font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize, Math.round(row.height * 0.45))
            }
        }

        ColumnLayout {
            id: column
            visible: root.isVertical
            anchors.centerIn: parent
            width: parent.width
            spacing: 0

            ClockLabel {
                Layout.fillWidth: true
                text: Qt.formatTime(root.currentTime, root.cfg.use24hFormat === 0 ? "h" : "hh")
                font.pixelSize: Math.round(column.width * 0.4)
            }
            ClockLabel {
                Layout.fillWidth: true
                text: Qt.formatTime(root.currentTime, "mm")
                font.pixelSize: Math.round(column.width * 0.4)
            }
        }
    }

    fullRepresentation: PlasmaCalendar.MonthView {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20
        today: root.currentTime
        showWeekNumbers: root.cfg.showWeekNumbers
    }
}
