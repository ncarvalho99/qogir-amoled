import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    property alias cfg_showDate: showDate.checked
    property alias cfg_showSeparator: showSeparator.checked
    property alias cfg_showSeconds: showSeconds.checked
    property alias cfg_showWeekNumbers: showWeekNumbers.checked
    property alias cfg_boldText: boldText.checked
    property alias cfg_italicText: italicText.checked
    property alias cfg_backgroundColorCheckBox: customColor.checked
    property string cfg_backgroundColor
    property string cfg_fontFamily
    property string cfg_dateFormat
    property alias cfg_customDateFormat: customDateFormat.text
    property int cfg_use24hFormat

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showDate
            Kirigami.FormData.label: i18n("Information:")
            text: i18n("Show date")
        }
        QQC2.CheckBox {
            id: showSeparator
            text: i18n("Show separator between date and time")
            enabled: showDate.checked
        }
        QQC2.CheckBox {
            id: showSeconds
            text: i18n("Show seconds")
        }
        QQC2.CheckBox {
            id: showWeekNumbers
            text: i18n("Show week numbers in the calendar")
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Time format:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Use region defaults"), value: 1 },
                { text: i18n("12-hour"), value: 0 },
                { text: i18n("24-hour"), value: 2 },
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_use24hFormat)
            onActivated: cfg_use24hFormat = currentValue
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Date format:")
            enabled: showDate.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Short date"), value: "shortDate" },
                { text: i18n("Long date"), value: "longDate" },
                { text: i18n("ISO date"), value: "isoDate" },
                { text: i18n("Custom"), value: "custom" },
            ]
            Component.onCompleted: currentIndex = indexOfValue(cfg_dateFormat)
            onActivated: cfg_dateFormat = currentValue
        }
        QQC2.TextField {
            id: customDateFormat
            visible: cfg_dateFormat === "custom"
            placeholderText: "ddd d"
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Font:")
            model: [i18n("Default")].concat(Qt.fontFamilies())
            Component.onCompleted: currentIndex = cfg_fontFamily ? Math.max(0, find(cfg_fontFamily)) : 0
            onActivated: cfg_fontFamily = currentIndex === 0 ? "" : currentText
        }
        QQC2.CheckBox {
            id: boldText
            text: i18n("Bold")
        }
        QQC2.CheckBox {
            id: italicText
            text: i18n("Italic")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Text color:")
            QQC2.CheckBox {
                id: customColor
                text: i18n("Custom")
            }
            QQC2.Button {
                enabled: customColor.checked
                implicitWidth: height
                onClicked: colorDialog.open()
                contentItem: Rectangle {
                    color: cfg_backgroundColor
                    border.color: Kirigami.Theme.textColor
                    radius: 2
                }
            }
        }
    }

    ColorDialog {
        id: colorDialog
        selectedColor: cfg_backgroundColor
        onAccepted: cfg_backgroundColor = selectedColor.toString()
    }
}
