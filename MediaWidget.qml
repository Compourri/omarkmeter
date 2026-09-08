import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property color accent: Color.accent
  property string artist: ""
  property string title: ""

  Process {
    id: mprisProc
    running: true
    command: ["python3", Qt.resolvedUrl("get-media.py").toString().replace("file://", "")]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        if (!s) return
        var parts = s.split("|")
        if (parts.length >= 2) {
          root.artist = parts[0]
          root.title = parts[1]
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: { if (!mprisProc.running) mprisProc.running = true }
  }

  implicitWidth: 220
  implicitHeight: 50
  visible: root.title !== ""

  Row {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: 10

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      width: 180

      Text {
        text: root.artist
        font.family: "Montserrat"
        font.pixelSize: 10
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        color: Qt.rgba(1, 1, 1, 0.7)
        width: parent.width
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        visible: root.artist !== ""
      }

      Text {
        text: root.title
        font.family: "Montserrat"
        font.pixelSize: 11
        font.weight: Font.Bold
        color: "white"
        width: parent.width
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
      }
    }

    Text {
      text: "♫"
      font.pixelSize: 20
      color: root.accent
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}