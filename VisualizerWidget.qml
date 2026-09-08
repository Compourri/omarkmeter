import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property color accent: Color.accent

  implicitWidth: 800
  implicitHeight: 80

  property var levels: new Array(60).fill(0.05)
  property int barCount: 60

  Process {
    id: audioProc
    running: true
    command: ["python3", Qt.resolvedUrl("get-audio.py").toString().replace("file://", "")]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        if (!s) return
        var parts = s.split(",")
        if (parts.length < 2) return
        var arr = new Array(parts.length)
        for (var i = 0; i < parts.length; i++) {
          var v = parseFloat(parts[i])
          arr[i] = isNaN(v) ? 0.05 : Math.max(0.0, Math.min(1.0, v))
        }
        root.levels = arr
        root.barCount = arr.length
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: { if (!audioProc.running) audioProc.running = true }
  }

  Row {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 3

    Repeater {
      model: root.barCount
      delegate: Item {
        id: bar
        required property int index
        width: 10
        height: 80

        property real currentHeight: {
          var idx = bar.index >= 0 && bar.index < root.levels.length ? bar.index : 0
          var lvl = root.levels[idx]
          return Math.max(2, lvl * 70)
        }

        Rectangle {
          width: 6
          height: parent.currentHeight
          anchors.bottom: centerLine.top
          anchors.horizontalCenter: parent.horizontalCenter
          color: root.accent
          opacity: 0.85
          radius: 2
        }

        Rectangle {
          id: centerLine
          width: 6
          height: 1
          anchors.centerIn: parent
          color: "white"
          opacity: 0.3
        }

        Rectangle {
          width: 6
          height: parent.currentHeight * 0.4
          anchors.top: centerLine.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          color: Qt.rgba(1, 1, 1, 0.4)
          radius: 2
        }
      }
    }
  }
}