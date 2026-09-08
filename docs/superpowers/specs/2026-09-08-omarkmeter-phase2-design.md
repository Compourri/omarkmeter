# Implementation Plan - Omark Meter Phase 2: Authentic Robik Suite

Bring the authentic Rainmeter Robik layout (clean floating text, thin accent progress bars, network/CPU sparklines, weather, media, and bottom audio visualizer) into Omark Meter while keeping the native desktop background integration.

## Proposed Changes

### 1. New Modular Components (`*.qml`)
- **`WeatherWidget.qml`**: Top-left weather indicator (condition icon, temperature).
- **`MediaWidget.qml`**: Top-right MPRIS media track display with accent note icon.
- **`MetricsWidget.qml`**: Middle metrics block below the clock containing:
  - Thin progress bars / text readouts for HDD, RAM, CPU, Upload/Download stats.
  - Minimalist sparkline / area chart elements matching Robik style.
- **`VisualizerWidget.qml`**: Bottom audio spectrum visualizer bars spanning across the screen.

### 2. Integration in `Clock.qml` & `RobikClock.qml`
- Wire up the active Loaders in `Clock.qml` to render Weather (top-left), Media (top-right), Metrics (below clock), and Visualizer (bottom).
- Expose positioning knobs so users can fine-tune spacing to match wallpaper focal points.

### 3. Verification
- Test compile with `quickshell` and verify correct layout rendering on the desktop background layer.
