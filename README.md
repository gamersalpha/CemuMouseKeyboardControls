# CemuMouseKeyboardControls

🎮 This project lets you play **The Legend of Zelda: Breath of the Wild** on **Cemu** using only **keyboard and mouse**, with smooth analog-like mouse movement for camera control and full input emulation — without needing vJoy or controllers.

---

## ✅ Features

- 🖱️ Mouse movement mapped to **right stick** with circular analog emulation
- 🧭 Keyboard keys mapped to **left stick** and all major gamepad buttons
- 🔒 Automatic **cursor lock** to Cemu window while playing
- 🔁 Non-linear sensitivity and deadzone for smooth control
- 🔌 No driver like vJoy or ViGEm needed
- 🧰 Fully configurable, standalone, AutoHotkey v2 script

---

## 📷 Cemu Keyboard Input Configuration

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
| A / B / X / Y      | `E`, `MAJ`, `ESPACE`, `V` (example)
| ZL / ZR            | `CTRL`, `M`
| D-Pad              | `C`, `W`, `A`, `X` (Up, Down, Left, Right)

🗂️ You can import the exact profile using the `.bin` file provided in this repo under `/cemu_profile/`.

---

## 🚀 How to Use

1. ✅ **Install [AutoHotkey v2](https://www.autohotkey.com/download/)**
2. 🧩 Download this repository
3. 🔧 Launch `CemuMouseControl.ahk` by double-clicking it
4. 🎮 Open Cemu, load the provided keyboard profile
5. 💨 Play BOTW with your keyboard and mouse!

---

## 🖥️ Controls

| Input                  | Action                  |
|------------------------|--------------------------|
| Mouse Move             | Right stick (camera)
| Left Click             | `L` (Attack)
| Right Click            | `M` (Aim)
| Middle Click (wheel)   | `Y` (Bow / item)

---

## 🔒 Extras

- Press `Alt+Tab` to release the mouse if needed.
- You can adjust sensitivity and deadzone in the script (`r`, `k`, `nnp`).
- To disable cursor locking, set `enableCursorLock := false` in the script.

---

## 🤝 Credits

- Inspired by mouse2joystick concepts
- Built entirely in **AutoHotkey v2**
- Developed and tuned by a BOTW/Cemu keyboard+mouse player

---

## 🗃️ Files in this repo
📁 /cemu_profile/ → Keyboard profile to import into Cemu
📄 CemuMouseControl.ahk → The main script
📄 README.md → This file

yaml
Copier
Modifier

---

Happy adventuring in Hyrule 🗺️
