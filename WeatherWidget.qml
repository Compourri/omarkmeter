import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property color accent: Color.accent
  property string condition: ""
  property string temperature: ""
  property string icon: ""

  Process {
    id: weatherProc
    running: true
    command: ["python3", Qt.resolvedUrl("get-weather.py").toString().replace("file://", "")]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        if (!s) return
        var parts = s.split("|")
        if (parts.length >= 3) {
          root.icon = parts[0]
          root.condition = parts[1]
          root.temperature = parts[2]
        }
      }
    }
  }

  Timer {
    interval: 600000
    running: true
    repeat: true
    onTriggered: { if (!weatherProc.running) weatherProc.running = true }
  }

  // Safety net: the helper enforces its own 8s deadline, but don't leave a
  // stuck process running if that ever fails.
  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: {
      if (weatherProc.running) {
        weatherProc.running = false
        weatherProc.running = true
      }
    }
  }

  visible: root.condition !== "" && root.condition !== "--"

  implicitWidth: 150
  implicitHeight: 50

  Row {
    anchors.centerIn: parent
    spacing: 8

    Text {
      text: root.icon || "☀"
      font.pixelSize: 24
      color: root.accent
      anchors.verticalCenter: parent.verticalCenter
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      Text {
        text: root.condition
        font.family: "Montserrat"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        color: Qt.rgba(1, 1, 1, 0.7)
      }

      Text {
        text: root.temperature
        font.family: "Montserrat"
        font.pixelSize: 12
        font.weight: Font.Bold
        color: "white"
      }
    }
  }
}