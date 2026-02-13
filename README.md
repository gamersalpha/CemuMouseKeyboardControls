
# CemuMouseKeyboardControls

This project lets you play **The Legend of Zelda: Breath of the Wild** on **Cemu** using only **keyboard and mouse**, with smooth analog-like mouse movement for camera control and full input emulation — without needing vJoy or controllers.

---

## Features

- Mouse movement mapped to **right stick** with circular analog emulation
- Keyboard keys mapped to **left stick** and all major gamepad buttons
- **Proper bow aiming**: Hold left-click to draw, release to shoot
- **Crouch/Sneak**: Press `V` to crouch (mapped to ZL)
- **Sheikah Tablet**: Press `Tab` to open/close the tablet
- **Zoom control**: Use `PgUp`/`PgDn` to zoom in/out with the tablet
- **Improved camera fluidity**: Enhanced sensitivity and linear response
- Automatic **cursor lock** to Cemu window while playing
- Optimized sensitivity and deadzone for smooth control
- No driver like vJoy or ViGEm needed
- Fully configurable, standalone, AutoHotkey v2 script

### v3 - Hook-free rewrite (Cemu crash fix)

The script has been completely rewritten to avoid crashing Cemu. Previous versions used AHK keyboard/mouse hooks (`~LButton::`, `~RButton::`, etc.) which installed low-level `WH_KEYBOARD_LL` and `WH_MOUSE_LL` hooks system-wide. These hooks interfered with Cemu's input pipeline and caused consistent crashes ~1 minute after launch.

**What changed:**
- **Zero hooks** - `InstallKeybdHook false` + `InstallMouseHook false`, no hotkey directives
- **Polling-based input** - All button states are read via `GetKeyState()` in a timer loop instead of intercepting input events
- **Win32 API for mouse** - Uses `GetCursorPos`/`SetCursorPos` instead of `MouseGetPos`/`MouseMove` to avoid injecting synthetic `WM_MOUSEMOVE` events
- **Zoom on PgUp/PgDn** - Mouse wheel cannot be polled, so zoom is now mapped to `PgUp`/`PgDn` keys

---

## Cemu Keyboard Input Configuration

To use this script, make sure Cemu is set to **Keyboard [Keyboard]** and you configure the key bindings like this:

| Stick/Action       | Key  |
|--------------------|------|
| Left Stick Up      | `Z`  |
| Left Stick Down    | `S`  |
| Left Stick Left    | `Q`  |
| Left Stick Right   | `D`  |
| Right Stick Up     | `U`  |
| Right Stick Down   | `I`  |
| Right Stick Left   | `O`  |
| Right Stick Right  | `P`  |
| Right Stick Click  | `Y`  |
| A / B / X / Y      | `L`, `M`, `Y`, `V` (example)
| ZL (Crouch)        | `CTRL GAUCHE` - Important for crouching
| ZR                 | Your choice
| D-Pad              | Your choice

You can import the exact controller configuration using the file:

```
2025-05-08-19-48.xml
```

Simply place it in your `Cemu/controllerProfiles/` folder, then load it in Cemu from the Input Settings using the "Load" button.

---

## How to Use

1. **Install [AutoHotkey v2](https://www.autohotkey.com/download/)**
2. Download this repository
3. Launch `MouseToKey_Cemu_v2.ahk` by double-clicking it
4. Open Cemu, load the provided keyboard profile
5. Play BOTW with your keyboard and mouse!

---

## Controls

| Input                    | Action                                |
|--------------------------|---------------------------------------|
| Mouse Move               | Right stick (camera)                  |
| Left Click (hold)        | Attack / Draw bow (release to shoot)  |
| Right Click (hold)       | Shield / Aim                          |
| Middle Click             | Special action                        |
| `PgUp` key               | Zoom In (Sheikah Tablet)              |
| `PgDn` key               | Zoom Out (Sheikah Tablet)             |
| `V` key                  | Crouch / Sneak                        |
| `Tab` key                | Open/Close Sheikah Tablet             |

---

## Configuration

- Press `Alt+Tab` to release the mouse if needed.
- **To disable cursor locking**, set `enableCursorLock := false` in the script.

### Camera sensitivity

You can adjust camera sensitivity in the script by modifying these variables:

```ahk
global r := 50        ; Camera sensitivity (higher = more sensitive)
global k := 0.01      ; Deadzone (lower = more reactive)
global nnp := 1.0     ; Non-linearity (1.0 = linear, <1 = more sensitive at center)
```

---

## Credits

- Inspired by mouse2joystick concepts
- Built entirely in **AutoHotkey v2**
- Developed and tuned by a BOTW/Cemu keyboard+mouse player

---

## Files in this repo

```
2025-05-08-19-48.xml      - Keyboard profile for Cemu (place in controllerProfiles/)
MouseToKey_Cemu_v2.ahk    - The main script
README.md                 - This file
```
