import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property color accent: Color.accent

  property var disks: []
  property string ram: "RAM: --"
  property real ramPercent: 0.0
  property string netUp: "UPLOAD: --"
  property string netDown: "DOWNLOAD: --"
  property string cpu: "CPU: --"
  property real cpuPercent: 0.0

  Process {
    id: statsProc
    running: true
    command: ["python3", Qt.resolvedUrl("get-metrics.py").toString().replace("file://", "")]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        if (!s) return
        try {
          var data = JSON.parse(s)
          root.disks = data.disks || []
          root.ram = "RAM: " + data.ram_str
          root.ramPercent = data.ram_pct
          root.cpu = "CPU: " + data.cpu_str
          root.cpuPercent = data.cpu_pct
          root.netUp = "UPLOAD: " + data.net_up
          root.netDown = "DOWNLOAD: " + data.net_down
        } catch (e) {
          console.warn("[MetricsWidget] Parse error:", e)
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: { if (!statsProc.running) statsProc.running = true }
  }

  implicitWidth: 500
  implicitHeight: (2 + Math.ceil(root.disks.length / 2)) * 36

  Column {
    anchors.fill: parent
    spacing: 12

    // Row 1: CPU | RAM
    Row {
      width: parent.width
      spacing: 40

      Column {
        width: (parent.width - 40) / 2
        spacing: 4
        Text {
          text: root.cpu
          font.family: "Montserrat"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: Qt.rgba(1, 1, 1, 0.8)
        }
        Rectangle {
          width: parent.width
          height: 2
          color: Qt.rgba(1, 1, 1, 0.2)
          radius: 1
          Rectangle {
            width: parent.width * root.cpuPercent
            height: parent.height
            color: root.accent
            radius: 1
          }
        }
      }

      Column {
        width: (parent.width - 40) / 2
        spacing: 4
        Text {
          text: root.ram
          font.family: "Montserrat"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: Qt.rgba(1, 1, 1, 0.8)
        }
        Rectangle {
          width: parent.width
          height: 2
          color: Qt.rgba(1, 1, 1, 0.2)
          radius: 1
          Rectangle {
            width: parent.width * root.ramPercent
            height: parent.height
            color: root.accent
            radius: 1
          }
        }
      }
    }

    // Row 2: Download | Upload
    Row {
      width: parent.width
      spacing: 40

      Column {
        width: (parent.width - 40) / 2
        spacing: 4
        Text {
          text: root.netDown
          font.family: "Montserrat"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: Qt.rgba(1, 1, 1, 0.8)
        }
        Rectangle {
          width: parent.width
          height: 2
          color: Qt.rgba(1, 1, 1, 0.2)
          radius: 1
          Rectangle {
            width: parent.width * 0.15
            height: parent.height
            color: root.accent
            radius: 1
          }
        }
      }

      Column {
        width: (parent.width - 40) / 2
        spacing: 4
        Text {
          text: root.netUp
          font.family: "Montserrat"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: Qt.rgba(1, 1, 1, 0.8)
        }
        Rectangle {
          width: parent.width
          height: 2
          color: Qt.rgba(1, 1, 1, 0.2)
          radius: 1
          Rectangle {
            width: parent.width * 0.15
            height: parent.height
            color: root.accent
            radius: 1
          }
        }
      }
    }

    // Row 3+: Disks (2 per row)
    Repeater {
      model: Math.ceil(root.disks.length / 2)
      delegate: Row {
        property int rowIndex: index
        width: parent.width
        spacing: 40

        // Left disk
        Column {
          width: (parent.width - 40) / 2
          spacing: 4
          property int diskIdx: rowIndex * 2
          Text {
            text: parent.diskIdx < root.disks.length ? "DISK: " + root.disks[parent.diskIdx].name + "  " + root.disks[parent.diskIdx].used + " / " + root.disks[parent.diskIdx].size : ""
            font.family: "Montserrat"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Qt.rgba(1, 1, 1, 0.8)
            visible: parent.diskIdx < root.disks.length
          }
          Rectangle {
            width: parent.width
            height: 2
            color: Qt.rgba(1, 1, 1, 0.2)
            radius: 1
            visible: parent.diskIdx < root.disks.length
            Rectangle {
              width: parent.width * (parent.parent.diskIdx < root.disks.length ? root.disks[parent.parent.diskIdx].pct : 0.0)
              height: parent.height
              color: root.accent
              radius: 1
            }
          }
        }

        // Right disk
        Column {
          width: (parent.width - 40) / 2
          spacing: 4
          property int diskIdx: rowIndex * 2 + 1
          Text {
            text: parent.diskIdx < root.disks.length ? "DISK: " + root.disks[parent.diskIdx].name + "  " + root.disks[parent.diskIdx].used + " / " + root.disks[parent.diskIdx].size : ""
            font.family: "Montserrat"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Qt.rgba(1, 1, 1, 0.8)
            visible: parent.diskIdx < root.disks.length
          }
          Rectangle {
            width: parent.width
            height: 2
            color: Qt.rgba(1, 1, 1, 0.2)
            radius: 1
            visible: parent.diskIdx < root.disks.length
            Rectangle {
              width: parent.width * (parent.parent.diskIdx < root.disks.length ? root.disks[parent.parent.diskIdx].pct : 0.0)
              height: parent.height
              color: root.accent
              radius: 1
            }
          }
        }
      }
    }
  }
}
