import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons

// Service entry point for george.omarkmeter
// Renders a Robik-inspired clock on WlrLayer.Background per monitor.
// MVP: hero time (hh.mm dot) + script weekday + date.
// Phase 2 slots (visualizer/metrics) left as Loaders with active:false.

Item {
  id: root

  // Single clock drives every screen — avoids per-panel drift
  SystemClock {
    id: sysClock
    precision: SystemClock.Seconds
  }
  property date now: sysClock.date

  // Optional positioning nudges if wallpaper focal point clashes.
  // Center is true Robik, but expose offsets so user can reposition without code patch.
  property int offsetX: 0
  property int offsetY: -40

  function openSelector() {
    if (!bgSwitchProc.running) bgSwitchProc.running = true
  }
  function openThemeSwitcher() {
    if (!themeSwitchProc.running) themeSwitchProc.running = true
  }

  Process {
    id: bgSwitchProc
    command: ["bash", "-c", "background=$(omarchy-theme-bg-switcher); [[ -n $background ]] && omarchy-theme-bg-set \"$background\""]
  }
  Process {
    id: themeSwitchProc
    command: ["bash", "-c", "theme=$(omarchy-theme-switcher); [[ -n $theme ]] && omarchy-theme-set \"$theme\" >/dev/null 2>&1 &"]
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData
      screen: modelData

      // Full-screen background layer — coexists with omarchy.background
      // If hidden behind wallpaper on your compositor, change Background -> Bottom.
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      visible: true

      WlrLayershell.namespace: "george-omarkmeter"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      // Keep composition enabled — Background layer has lost buffers when disabled (see Background.qml:202)
      // Center the clock. offsets let user shift off true center if needed.
      Item {
        anchors.fill: parent

        RobikClock {
          id: clock
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: root.offsetX
          anchors.verticalCenterOffset: root.offsetY
          date: root.now
          // theme-following accent per user choice
          accent: Color.accent
        }

        // Phase 2 modular containers — inactive in MVP, zero cost
        // Visualizer: mpris/pipewire-driven bars below metrics row (see Robik bottom waveform)
        Loader {
          id: visualizerLoader
          active: false
          // source: Qt.resolvedUrl("Visualizer.qml")
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 80
        }

        // Metrics: HDD/RAM/CPU/network sparklines — two-column grid
        Loader {
          id: metricsLoader
          active: false
          // source: Qt.resolvedUrl("Metrics.qml")
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: clock.bottom
          anchors.topMargin: 32
        }
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onDoubleClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) root.openThemeSwitcher()
          else root.openSelector()
          mouse.accepted = true
        }
      }
    }
  }

}
