#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================================
; Script de contrôle souris/clavier pour Zelda: Breath of the Wild (Cemu)
; ============================================================================
; VERSION SANS HOOKS - utilise le polling (GetAsyncKeyState) au lieu
; d'intercepter les inputs. Compatible avec Cemu sans crash.
;
; CONTRÔLES :
; - Souris : Déplacer la caméra
; - Clic gauche : Attaque / Tir à l'arc (maintenir pour viser)
; - Clic droit : Bouclier / Viser
; - Clic milieu : Action spéciale
; - Touche V : Se baisser (crouch/sneak)
; - Touche Tab : Ouvrir/fermer la tablette Sheikah
; - Molette haut/bas : Zoomer/Dézoomer (via PgUp/PgDn car polling molette impossible)
;
; CONFIGURATION CEMU REQUISE :
; - Stick droit : u (haut), i (bas), o (gauche), p (droite)
; - Bouton A : l
; - Bouton B : m
; - Bouton X : y
; - ZL (crouch) : Ctrl gauche
;
; ============================================================================

; === PAS DE HOOKS ===
; On n'utilise AUCUN hotkey (pas de ~LButton::, etc.)
; Tout est géré par polling dans un timer
SendMode "Input"
SetKeyDelay -1, -1
SetMouseDelay -1
InstallKeybdHook false
InstallMouseHook false

; Variables globales
global threshold := 2
global holdTimer := Map()
global keys := Map("Up", false, "Down", false, "Left", false, "Right", false)
global enableCursorLock := true

; État des boutons (polling)
global prevLButton := false
global prevRButton := false
global prevMButton := false
global prevVKey := false
global prevTabKey := false
global prevPgUp := false
global prevPgDn := false

; Touches associées aux directions (caméra)
global keyRight := "p"
global keyLeft := "o"
global keyUp := "u"
global keyDown := "i"

; Touches associées aux clics de souris
global mouseLeftKey := "l"      ; Attaque / Tir à l'arc
global mouseRightKey := "m"     ; Bouclier / Viser
global mouseMiddleKey := "y"    ; Action spéciale

; Touche pour se baisser (crouch)
global crouchKey := "LCtrl"

; Touches pour la tablette Sheikah et le zoom
global sheikahTabletKey := "2"
global zoomInKey := "c"
global zoomOutKey := "w"

; Résolution de l'écran
global screenWidth := A_ScreenWidth
global screenHeight := A_ScreenHeight
global centerX := screenWidth // 2
global centerY := screenHeight // 2

; Paramètres du cercle virtuel pour la caméra
global r := 50
global k := 0.01
global nnp := 1.0
global invertedX := 0
global invertedY := 0
global pmX := invertedX ? -1 : 1
global pmY := invertedY ? -1 : 1

; Un seul timer pour tout gérer
SetTimer(MainLoop, 16)
if (enableCursorLock)
    SetTimer(LockCursorInCemu, 200)

; ==== BOUCLE PRINCIPALE (POLLING) ====

MainLoop()
{
    global prevLButton, prevRButton, prevMButton, prevVKey, prevTabKey
    global prevPgUp, prevPgDn
    global mouseLeftKey, mouseRightKey, mouseMiddleKey
    global crouchKey, sheikahTabletKey, zoomInKey, zoomOutKey

    ; Vérifier que Cemu est actif
    try {
        if WinGetProcessName("A") != "Cemu.exe"
        {
            ReleaseAll()
            return
        }
    } catch {
        return
    }

    ; === Mouvement caméra ===
    mouse2joystick(r, 0, centerX, centerY)

    ; Relâcher les touches de direction après un délai si plus de mouvement
    for dir, time in holdTimer
    {
        if keys[dir] && (A_TickCount - time > 100)
        {
            Release(dir, getKeyForDirection(dir))
            holdTimer.Delete(dir)
        }
    }

    ; === Polling des boutons souris et touches ===

    ; Clic gauche
    curLButton := GetKeyState("LButton", "P")
    if (curLButton && !prevLButton)
        SendInput("{" mouseLeftKey " down}")
    else if (!curLButton && prevLButton)
        SendInput("{" mouseLeftKey " up}")
    prevLButton := curLButton

    ; Clic droit
    curRButton := GetKeyState("RButton", "P")
    if (curRButton && !prevRButton)
        SendInput("{" mouseRightKey " down}")
    else if (!curRButton && prevRButton)
        SendInput("{" mouseRightKey " up}")
    prevRButton := curRButton

    ; Clic milieu
    curMButton := GetKeyState("MButton", "P")
    if (curMButton && !prevMButton)
        SendInput("{" mouseMiddleKey " down}")
    else if (!curMButton && prevMButton)
        SendInput("{" mouseMiddleKey " up}")
    prevMButton := curMButton

    ; Touche V (crouch)
    curVKey := GetKeyState("v", "P")
    if (curVKey && !prevVKey)
        SendInput("{" crouchKey " down}")
    else if (!curVKey && prevVKey)
        SendInput("{" crouchKey " up}")
    prevVKey := curVKey

    ; Touche Tab (tablette Sheikah)
    curTabKey := GetKeyState("Tab", "P")
    if (curTabKey && !prevTabKey)
        SendInput("{" sheikahTabletKey " down}")
    else if (!curTabKey && prevTabKey)
        SendInput("{" sheikahTabletKey " up}")
    prevTabKey := curTabKey

    ; PgUp = Zoom in (remplace la molette haut)
    curPgUp := GetKeyState("PgUp", "P")
    if (curPgUp && !prevPgUp)
        SendInput("{" zoomInKey " down}")
    else if (!curPgUp && prevPgUp)
        SendInput("{" zoomInKey " up}")
    prevPgUp := curPgUp

    ; PgDn = Zoom out (remplace la molette bas)
    curPgDn := GetKeyState("PgDn", "P")
    if (curPgDn && !prevPgDn)
        SendInput("{" zoomOutKey " down}")
    else if (!curPgDn && prevPgDn)
        SendInput("{" zoomOutKey " up}")
    prevPgDn := curPgDn
}

; ==== GESTION MOUVEMENT SOURIS ====

mouse2joystick(r, dr, OX, OY)
{
    global k, nnp, pmX, pmY

    POINT := Buffer(8, 0)
    DllCall("GetCursorPos", "Ptr", POINT)
    rawX := NumGet(POINT, 0, "Int")
    rawY := NumGet(POINT, 4, "Int")

    X := rawX - OX
    Y := rawY - OY
    RR := sqrt(X**2 + Y**2)

    ; Si la souris n'a pas bougé, rien à faire
    if (RR < 1)
    {
        Release("Right", keyRight)
        Release("Left", keyLeft)
        Release("Up", keyUp)
        Release("Down", keyDown)
        return
    }

    if (RR > r)
    {
        X := round(X * (r - dr) / RR)
        Y := round(Y * (r - dr) / RR)
        RR := sqrt(X**2 + Y**2)
        DllCall("SetCursorPos", "Int", X + OX, "Int", Y + OY)
    }

    phi := getAngle(X, Y)

    if (RR > k * r)
    {
        tilt := ((RR - k * r) / (r - k * r))**nnp
        action(phi, tilt)
    }
    else
    {
        Release("Right", keyRight)
        Release("Left", keyLeft)
        Release("Up", keyUp)
        Release("Down", keyDown)
    }

    DllCall("SetCursorPos", "Int", OX, "Int", OY)
}

action(phi, tilt)
{
    global pmX, pmY

    tilt := tilt > 1 ? 1 : tilt
    tilt := 1 - tilt <= 0.005 ? 1 : tilt

    pi := 4 * atan(1)

    lb := 3 * pi / 2
    ub := 7 * pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt * scale(phi, ub, lb)
        y := pmY * tilt
        setKeys(x, y)
        return
    }

    lb := 7 * pi / 4
    ub := 2 * pi
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt
        y := pmY * tilt * scale(phi, lb, ub)
        setKeys(x, y)
        return
    }

    lb := 0
    ub := pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt
        y := -pmY * tilt * scale(phi, ub, lb)
        setKeys(x, y)
        return
    }

    lb := pi / 4
    ub := pi / 2
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt * scale(phi, lb, ub)
        y := -pmY * tilt
        setKeys(x, y)
        return
    }

    lb := pi / 2
    ub := 3 * pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt * scale(phi, ub, lb)
        y := -pmY * tilt
        setKeys(x, y)
        return
    }

    lb := 3 * pi / 4
    ub := pi
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt
        y := -pmY * tilt * scale(phi, lb, ub)
        setKeys(x, y)
        return
    }

    lb := pi
    ub := 5 * pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt
        y := pmY * tilt * scale(phi, ub, lb)
        setKeys(x, y)
        return
    }

    lb := 5 * pi / 4
    ub := 3 * pi / 2
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt * scale(phi, lb, ub)
        y := pmY * tilt
        setKeys(x, y)
        return
    }

    Release("Right", keyRight)
    Release("Left", keyLeft)
    Release("Up", keyUp)
    Release("Down", keyDown)
}

setKeys(x, y)
{
    if (x > threshold / 10)
    {
        Press("Right", keyRight)
        holdTimer["Right"] := A_TickCount
        Release("Left", keyLeft)
    }
    else if (x < -threshold / 10)
    {
        Press("Left", keyLeft)
        holdTimer["Left"] := A_TickCount
        Release("Right", keyRight)
    }
    else
    {
        Release("Right", keyRight)
        Release("Left", keyLeft)
    }

    if (y > threshold / 10)
    {
        Press("Up", keyUp)
        holdTimer["Up"] := A_TickCount
        Release("Down", keyDown)
    }
    else if (y < -threshold / 10)
    {
        Press("Down", keyDown)
        holdTimer["Down"] := A_TickCount
        Release("Up", keyUp)
    }
    else
    {
        Release("Up", keyUp)
        Release("Down", keyDown)
    }
}

getAngle(x, y)
{
    pi := 4 * atan(1)
    if (x = 0)
        return 3 * pi / 2 - (y > 0) * pi
    phi := atan(y / x)
    if (x < 0 && y > 0)
        return phi + pi
    if (x < 0 && y <= 0)
        return phi + pi
    if (x > 0 && y < 0)
        return phi + 2 * pi
    return phi
}

scale(phi, lb, ub)
{
    return (phi - ub) / (lb - ub)
}

; ==== VERROUILLAGE CURSEUR ====

LockCursorInCemu()
{
    if (!enableCursorLock)
        return

    hwnd := WinExist("ahk_exe Cemu.exe")
    if !hwnd
        return

    if WinActive("ahk_id " hwnd)
    {
        WinGetPos(&X, &Y, &W, &H, "ahk_id " hwnd)
        RECT := Buffer(16, 0)
        NumPut("Int", X, RECT, 0)
        NumPut("Int", Y, RECT, 4)
        NumPut("Int", X + W, RECT, 8)
        NumPut("Int", Y + H, RECT, 12)
        DllCall("ClipCursor", "Ptr", RECT)
    }
    else
    {
        DllCall("ClipCursor", "Ptr", 0)
    }
}

; ==== UTILS ====

Press(dir, key)
{
    if !keys[dir]
    {
        SendInput("{" key " down}")
        keys[dir] := true
    }
}

Release(dir, key)
{
    if keys[dir]
    {
        SendInput("{" key " up}")
        keys[dir] := false
    }
}

ReleaseAll()
{
    global prevLButton, prevRButton, prevMButton, prevVKey, prevTabKey
    global mouseLeftKey, mouseRightKey, mouseMiddleKey, crouchKey, sheikahTabletKey

    for dir, key in keys
    {
        Release(dir, getKeyForDirection(dir))
    }

    if (prevLButton)
    {
        SendInput("{" mouseLeftKey " up}")
        prevLButton := false
    }
    if (prevRButton)
    {
        SendInput("{" mouseRightKey " up}")
        prevRButton := false
    }
    if (prevMButton)
    {
        SendInput("{" mouseMiddleKey " up}")
        prevMButton := false
    }
    if (prevVKey)
    {
        SendInput("{" crouchKey " up}")
        prevVKey := false
    }
    if (prevTabKey)
    {
        SendInput("{" sheikahTabletKey " up}")
        prevTabKey := false
    }
}

getKeyForDirection(dir)
{
    return dir = "Right" ? keyRight
         : dir = "Left" ? keyLeft
         : dir = "Up" ? keyUp
         : dir = "Down" ? keyDown
         : ""
}
