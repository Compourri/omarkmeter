import QtQuick

// Pure visual — no Wayland, no timers. Clock.qml owns time and passes `date` in.
// No qs.Commons import here — stays standalone for qmllint/preview outside Omarchy.
// Clock.qml (Omarchy) passes accent: Color.accent in.
Item {
  id: root

  property date date: new Date()
  // Theme-following accent passed from Clock.qml; defaults to Robik orange standalone.
  property color accent: "#ec9844"

  // Layout knobs — tweak here to match wallpaper focal point
  property int heroSize: 132
  property int scriptSize: 54
  property int dateSize: 13
  property real heroOpacity: 0.58
  property int dividerWidth: 140
  property color heroColor: Qt.rgba(1, 1, 1, 0.72)
  property color dateColor: "white"

  // Fonts — Freehand (OFL, Danh Hong) for weekday script, Montserrat SemiBold for hero clock (middle ground + touch heavier)
  FontLoader { id: scriptFont; source: Qt.resolvedUrl("assets/Freehand-Regular.ttf") }
  FontLoader { id: clockFont; source: Qt.resolvedUrl("assets/Montserrat-SemiBold.otf") }

  // Helpers (24h colon as requested: 16:23 — HH is 24h, hh is 12h)
  readonly property string timeText: Qt.formatDateTime(root.date, "HH:mm")
  readonly property string weekdayText: Qt.formatDate(root.date, "dddd")
  readonly property string dateText: Qt.formatDate(root.date, "d MMMM yyyy")

  implicitWidth: 560
  implicitHeight: column.implicitHeight
  // responsive clamp: prevents clipping on small screens/ultrawide (PanelWindow fills screen)
  width: parent ? Math.min(implicitWidth, parent.width - 32) : implicitWidth

  Column {
    id: column
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 0

    // --- Hero: huge translucent time + script weekday overlaid ---
    Item {
      id: heroWrap
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(heroText.implicitWidth, parent.width)
      // include buffer for rotated script (rotated bounds exceed implicitHeight)
      height: Math.max(heroText.implicitHeight, scriptText.implicitHeight + 16)

      Text {
        id: heroText
        anchors.centerIn: parent
        text: root.timeText
        color: root.heroColor
        opacity: root.heroOpacity
        font.family: clockFont.status === FontLoader.Ready ? clockFont.name : "Montserrat"
        font.pixelSize: root.heroSize
        font.weight: Font.DemiBold
        font.letterSpacing: -4 * (root.heroSize / 132)
        horizontalAlignment: Text.AlignHCenter
        // subtle outline keeps 0.42 effective alpha readable on bright wallpapers
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.28)
      }

      Text {
        id: scriptText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -6
        anchors.horizontalCenterOffset: 6
        text: root.weekdayText
        color: root.accent
        font.family: scriptFont.status === FontLoader.Ready ? scriptFont.name : "cursive"
        font.pixelSize: root.scriptSize
        font.letterSpacing: 0.5
        // subtle shadow so script reads over hero digits irrespective of wallpaper brightness
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.45)
        horizontalAlignment: Text.AlignHCenter
        // Robik script leans inline — slight rotation makes it feel handwritten
        // layer enabled for smooth rotated rasterization
        layer.enabled: true
        layer.smooth: true
        rotation: -4
        transformOrigin: Item.Center
      }
    }

    // --- Divider + date ---
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      height: 28

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        width: root.dividerWidth
        height: 2
        radius: 1
        color: root.dateColor
        opacity: 0.92
      }
    }

    Text {
      id: dateLabel
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.dateText
      color: root.dateColor
      opacity: 0.96
      font.family: clockFont.status === FontLoader.Ready ? clockFont.name : "Montserrat"
      font.pixelSize: root.dateSize
      font.weight: Font.DemiBold
      font.letterSpacing: 1.1
      font.capitalization: Font.AllUppercase
      horizontalAlignment: Text.AlignHCenter
    }

    // --- Modular slots for Phase 2 (visualizer / metrics) ---
    // Keep invisible in MVP but leave anchors so future modules drop in without reflow.
    // Example:
    // Loader { id: visualizerSlot; active: false; source: "Visualizer.qml"; anchors.horizontalCenter: parent.horizontalCenter }
    // Loader { id: metricsSlot; active: false; source: "Metrics.qml"; anchors.horizontalCenter: parent.horizontalCenter }
  }
}
