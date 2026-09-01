import QtQuick
import qs.Commons

// Pure visual — no Wayland, no timers. Clock.qml owns time and passes `date` in.
Item {
  id: root

  property date date: new Date()
  // Theme-following accent (Color.accent). Falls back to Robik orange before Color loads.
  property color accent: Color.accent || "#ec9844"

  // Layout knobs — tweak here to match wallpaper focal point
  property int heroSize: 132
  property int scriptSize: 54
  property int dateSize: 13
  property real heroOpacity: 0.58
  property int dividerWidth: 140
  property color heroColor: Qt.rgba(1, 1, 1, 0.72)
  property color dateColor: "white"

  // Fonts — MovingSkate for weekday script, Montserrat SemiBold for hero clock (middleground + touch heavier)
  FontLoader { id: scriptFont; source: Qt.resolvedUrl("assets/MovingSkate.ttf") }
  FontLoader { id: clockFont; source: Qt.resolvedUrl("assets/Montserrat-SemiBold.otf") }

  // Helpers (24h colon as requested: 16:23)
  readonly property string timeText: Qt.formatDateTime(root.date, "hh:mm")
  readonly property string weekdayText: Qt.locale("en_US").dayName(root.date.getDay(), Locale.LongFormat)
  readonly property string dateText: Qt.formatDate(root.date, "d MMMM yyyy").toUpperCase()

  implicitWidth: 560
  implicitHeight: column.implicitHeight

  Column {
    id: column
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 0

    // --- Hero: huge translucent time + script weekday overlaid ---
    Item {
      id: heroWrap
      anchors.horizontalCenter: parent.horizontalCenter
      width: heroText.implicitWidth
      height: heroText.implicitHeight

      Text {
        id: heroText
        anchors.centerIn: parent
        text: root.timeText
        color: root.heroColor
        opacity: root.heroOpacity
        font.family: clockFont.status === FontLoader.Ready ? clockFont.name : "Montserrat SemiBold"
        font.pixelSize: root.heroSize
        font.weight: Font.DemiBold
        font.letterSpacing: -4
        horizontalAlignment: Text.AlignHCenter
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
        color: "white"
        opacity: 0.92
      }
    }

    Text {
      id: dateLabel
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.dateText
      color: root.dateColor
      opacity: 0.96
      font.family: clockFont.status === FontLoader.Ready ? clockFont.name : Style.font.family
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
