# Omark Meter

Robik-inspired Rainmeter clock for Omarchy (Hyprland + Quickshell) — renders on the desktop **Background** layer as a `PanelWindow` per monitor.

![Omark Meter preview](preview.png)

## Features (MVP)

*   Huge translucent time `hh:mm` (colon separator, 24h) — **Montserrat SemiBold** (Google Fonts, SIL Open Font License 1.1)
*   Script weekday overlay — **Dancing Script** (Google Fonts, SIL Open Font License 1.1)
*   Divider + `D MMMM YYYY` date
*   Theme-following accent (`Color.accent`)
*   Double-click desktop: left → `omarchy-theme-bg-switcher`, right → `omarchy-theme-switcher`
*   Modular `Loader` stubs for Phase 2 visualizer/metrics

## Install

```bash
# manual
mkdir -p ~/.config/omarchy/plugins/george.omarkmeter
cp -r assets Clock.qml RobikClock.qml manifest.json ~/.config/omarchy/plugins/george.omarkmeter/
quickshell ipc -p /usr/share/omarchy/shell call shell rescanPlugins
# or via helper
omarchy plugin add https://github.com/Compourri/omarkmeter.git --enable --yes
```

Add to `~/.config/omarchy/shell.json` `plugins: [{id:"george.omarkmeter"}]` is handled by the helper.

## Layout knobs

`RobikClock.qml`: `heroSize`, `scriptSize`, `heroOpacity`, `heroColor`, `dividerWidth` — `Clock.qml`: `offsetX/Y` to shift off center.

## Plugin & Font Attribution

*   `id: george.omarkmeter` — `name: Omark Meter` — `kinds: [service]` — `entryPoints.service: Clock.qml`
*   **Fonts & Licenses:**
    *   **Montserrat-SemiBold.ttf**: Google Fonts (Julieta Ulanovsky), SIL Open Font License 1.1 (`assets/OFL.txt`). Upstream pin: [google/fonts@c287431f/ofl/montserrat](https://github.com/google/fonts/blob/c287431fa3a02798e986cb08c3504ba4e0a5c43d/ofl/montserrat/static/Montserrat-SemiBold.ttf). SHA-256: `e3e1c254ac42e0de79d337a45c39c9421e49e032365d56f3edf58eacfd1c7845`.
    *   **DancingScript.ttf**: Google Fonts (Impallari Type), SIL Open Font License 1.1 (`assets/OFL.txt`). Upstream pin: [google/fonts@c287431f/ofl/dancingscript](https://github.com/google/fonts/blob/c287431fa3a02798e986cb08c3504ba4e0a5c43d/ofl/dancingscript/DancingScript%5Bwght%5D.ttf). SHA-256: `21808625578fe8d8cd10cb684be546dca077b27cd03a53a2f1ec11dc743c924c`.

## License

*   **Omark Meter (Code):** MIT — see `LICENSE`.
*   **Fonts:** SIL Open Font License 1.1 — see `assets/OFL.txt`.

