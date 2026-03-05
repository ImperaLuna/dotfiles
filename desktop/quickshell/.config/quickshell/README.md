# Quickshell Notes

## Run / Reload

- Active entrypoint: `shell.qml`
- Default run:
```bash
qs
```
- If using named config:
```bash
qs -c <name>
```

## Linting

- Lint all QML:
```bash
cd /home/imperaluna/dotfiles/desktop/quickshell/.config/quickshell
qmllint $(find . -name '*.qml' | sort)
```
- Lint one file:
```bash
qmllint drawers/Drawers.qml
```

Notes:
- `launcher/*.js` files are QML JS (`.pragma library`), not Node.js JS.
- Do not use `node --check` on these files.

## Project Structure

- `shell.qml`
  - Root entrypoint. Spawns one `Drawers` instance per screen and launcher IPC toggle.
- `drawers/`
  - Composition layer: window, mask, z-order, exclusions, bar/border mounting.
  - Should not contain feature-specific UI logic beyond layout/wiring.
- `bar/`
  - Top bar UI components (workspaces, clock, tray controls).
- `notifications/`
  - Notification feature module.
  - `Wrapper.qml`: feature wrapper + open/close animation + list binding.
  - `NotifModel.qml`: current placeholder model (replace with service-backed model).
  - `NotificationItem.qml`: one notification card delegate.
  - `Background.qml`: shape path used by drawers background pass.
- `powermenu/`
  - Power menu feature module.
  - `Wrapper.qml`: power actions panel and interaction.
  - `Background.qml`: shape path used by drawers background pass.
- `launcher/`
  - Launcher feature module (QML + QML JS helpers).
- `theme/`
  - Shared design tokens (`Colors`, `Fonts`, `Metrics`).

## Rendering Process (Keep This Pattern)

Current pipeline in `drawers/Drawers.qml`:

1. `PanelWindow` owns full-screen composition.
2. `Exclusions` reserves edges for bar/border.
3. `mask` defines pass-through/click-through shape.
4. `Panels` (`z: 2`) renders interactive content wrappers (bar, powermenu, notifications).
5. `Shape` background pass (`z: 1.5`) renders panel background paths.
6. `Border` (`z: 1`) renders outer frame/chrome ring.

### Feature contract

For drawer-like features (notifications/powermenu/etc), keep this split:

1. Feature `Wrapper` owns motion/state sizing (`width`/`height` transitions, visibility).
2. Feature `Background` owns shape path only.
3. `drawers/Panels.qml` mounts wrappers.
4. `drawers/Drawers.qml` mounts background shape paths and controls z/mask.

Do not put panel background rectangles inside feature wrappers if the feature is intended to match the shared chrome model.

## Styling Contract

- Shared chrome color lives in `Drawers.chromeColor`.
- Bar and border consume the same chrome color input.
- Global font families are centralized in `theme/Fonts.qml`:
  - `Fonts.text`
  - `Fonts.symbols`

## Caelestia Inspiration / Reference

Primary local references:

- Source cache:
  - `/home/imperaluna/.cache/yay/caelestia-shell`
- Tarball:
  - `/home/imperaluna/.cache/yay/caelestia-shell/caelestia-shell-v1.5.0.tar.gz`
- Installed config used by `qs -c caelestia`:
  - `/etc/xdg/quickshell/caelestia`

Most useful Cael files for matching architecture:

- `release/modules/drawers/Drawers.qml`
- `release/modules/drawers/Panels.qml`
- `release/modules/drawers/Backgrounds.qml`
- `release/modules/drawers/Border.qml`
- `release/modules/bar/BarWrapper.qml`
- `release/modules/notifications/Wrapper.qml`
- `release/modules/notifications/Background.qml`

## Suggested Next Steps

1. Replace `notifications/NotifModel.qml` with service-backed model data.
2. Provide real `iconSource` values (app icon / sender avatar / screenshot thumbnail).
3. Keep any new panel feature in its own folder (`<feature>/Wrapper.qml`, `<feature>/Background.qml`, optional `<feature>/Model.qml`).
