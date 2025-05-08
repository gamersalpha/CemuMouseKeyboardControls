#Requires AutoHotkey v2.0
#SingleInstance Force

; Variables globales
global threshold := 2
global holdTimer := Map()
global keys := Map("Up", false, "Down", false, "Left", false, "Right", false)
global enableCursorLock := true  ; Variable pour activer/désactiver le verrouillage du curseur (true = activé, false = désactivé)

; Touches associées aux directions
global keyRight := "p"
global keyLeft := "o"
global keyUp := "u"
global keyDown := "i"

; Touches associées aux clics de souris (inchangées, car elles fonctionnent déjà)
global mouseLeftKey := "l"
global mouseRightKey := "m"
global mouseMiddleKey := "y"

; Résolution de l'écran
global screenWidth := A_ScreenWidth
global screenHeight := A_ScreenHeight
global centerX := screenWidth // 2
global centerY := screenHeight // 2

; Paramètres du cercle virtuel (inspirés du script fourni)
global r := 30        ; Rayon du cercle de contrôle (sensibilité)
global k := 0.02      ; Deadzone (zone morte au centre)
global nnp := 0.80    ; Non-linéarité de la sensibilité (1 = linéaire, <1 = plus sensible au centre)
global invertedX := 0  ; Inverser l'axe X (0 = non, 1 = oui)
global invertedY := 0  ; Inverser l'axe Y (0 = non, 1 = oui)
global pmX := invertedX ? -1 : 1  ; Signe pour l'inversion de l'axe X
global pmY := invertedY ? -1 : 1  ; Signe pour l'inversion de l'axe Y

; Lancement des timers
SetTimer(WatchMouse, 5)  ; Timer rapide pour un mouvement fluide
if (enableCursorLock)
    SetTimer(LockCursorInCemu, 100)

; ==== CLIC SOURIS (inchangé, car ça fonctionne) ====

~LButton::
{
    if WinActive("ahk_exe Cemu.exe")
    {
        BlockInput(true)
        Send("{" mouseLeftKey " down}")
        Sleep(50)
        Send("{" mouseLeftKey " up}")
        BlockInput(false)
    }
    return
}

~RButton::
{
    if WinActive("ahk_exe Cemu.exe")
    {
        BlockInput(true)
        Send("{" mouseRightKey " down}")
        Sleep(50)
        Send("{" mouseRightKey " up}")
        BlockInput(false)
    }
    return
}

~MButton::
{
    if WinActive("ahk_exe Cemu.exe")
    {
        BlockInput(true)
        Send("{" mouseMiddleKey " down}")
        Sleep(50)
        Send("{" mouseMiddleKey " up}")
        BlockInput(false)
    }
    return
}

; ==== GESTION MOUVEMENT SOURIS ====

WatchMouse()
{
    if WinGetProcessName("A") != "Cemu.exe"
    {
        ReleaseAll()
        return
    }

    ; Désactiver temporairement le verrouillage du curseur pour éviter les interférences
    if (enableCursorLock)
        DllCall("ClipCursor", "Ptr", 0)

    ; Appeler la fonction inspirée du script fourni
    mouse2joystick(r, 0, centerX, centerY)

    ; Réappliquer le verrouillage du curseur si activé
    if (enableCursorLock)
    {
        hwnd := WinExist("ahk_exe Cemu.exe")
        if (hwnd && WinActive("ahk_id " hwnd))
        {
            WinGetPos(&X, &Y, &W, &H, "ahk_id " hwnd)
            RECT := Buffer(16, 0)
            NumPut("Int", X, RECT, 0)
            NumPut("Int", Y, RECT, 4)
            NumPut("Int", X + W, RECT, 8)
            NumPut("Int", Y + H, RECT, 12)
            DllCall("ClipCursor", "Ptr", RECT)
        }
    }

    ; Relâcher les touches après un délai si plus de mouvement
    for dir, time in holdTimer
    {
        if keys[dir] && (A_TickCount - time > 100)
        {
            Release(dir, getKeyForDirection(dir))
            holdTimer.Delete(dir)
        }
    }
}

; Fonction inspirée du script fourni, adaptée pour les touches clavier
mouse2joystick(r, dr, OX, OY)
{
    global k, nnp, pmX, pmY

    MouseGetPos(&X, &Y)
    X -= OX  ; Move to controller coord system
    Y -= OY
    RR := sqrt(X**2 + Y**2)

    ; Si la souris est en dehors du cercle de contrôle, recentrer
    if (RR > r)
    {
        X := round(X * (r - dr) / RR)
        Y := round(Y * (r - dr) / RR)
        RR := sqrt(X**2 + Y**2)
        MouseMove(X + OX, Y + OY, 0)  ; Recentrer la souris sur le cercle
    }

    ; Calculer l'angle
    phi := getAngle(X, Y)

    ; Vérifier si on est en dehors de la zone morte
    if (RR > k * r)
    {
        tilt := ((RR - k * r) / (r - k * r))**nnp  ; Appliquer la non-linéarité
        action(phi, tilt)  ; Simuler les touches en fonction de l'angle et de l'amplitude
    }
    else
    {
        Release("Right", keyRight)
        Release("Left", keyLeft)
        Release("Up", keyUp)
        Release("Down", keyDown)
    }

    ; Recentrer la souris au centre après chaque mouvement
    MouseMove(OX, OY, 0)
}

action(phi, tilt)
{
    global pmX, pmY

    ; Ajuster l'amplitude (tilt)
    tilt := tilt > 1 ? 1 : tilt
    tilt := 1 - tilt <= 0.005 ? 1 : tilt  ; Snap to full tilt si proche de 1

    ; Déterminer la direction en fonction de l'angle (phi) et presser les touches correspondantes
    pi := 4 * atan(1)

    ; Tilt vers l'avant et légèrement à droite
    lb := 3 * pi / 2
    ub := 7 * pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt * scale(phi, ub, lb)
        y := pmY * tilt
        setKeys(x, y)
        return
    }

    ; Tilt légèrement vers l'avant et à droite
    lb := 7 * pi / 4
    ub := 2 * pi
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt
        y := pmY * tilt * scale(phi, lb, ub)
        setKeys(x, y)
        return
    }

    ; Tilt vers la droite et légèrement vers le bas
    lb := 0
    ub := pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt
        y := -pmY * tilt * scale(phi, ub, lb)
        setKeys(x, y)
        return
    }

    ; Tilt vers le bas et légèrement à droite
    lb := pi / 4
    ub := pi / 2
    if (phi >= lb && phi <= ub)
    {
        x := pmX * tilt * scale(phi, lb, ub)
        y := -pmY * tilt
        setKeys(x, y)
        return
    }

    ; Tilt vers le bas et légèrement à gauche
    lb := pi / 2
    ub := 3 * pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt * scale(phi, ub, lb)
        y := -pmY * tilt
        setKeys(x, y)
        return
    }

    ; Tilt vers la gauche et légèrement vers le bas
    lb := 3 * pi / 4
    ub := pi
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt
        y := -pmY * tilt * scale(phi, lb, ub)
        setKeys(x, y)
        return
    }

    ; Tilt vers la gauche et légèrement vers l'avant
    lb := pi
    ub := 5 * pi / 4
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt
        y := pmY * tilt * scale(phi, ub, lb)
        setKeys(x, y)
        return
    }

    ; Tilt vers l'avant et légèrement à gauche
    lb := 5 * pi / 4
    ub := 3 * pi / 2
    if (phi >= lb && phi <= ub)
    {
        x := -pmX * tilt * scale(phi, lb, ub)
        y := pmY * tilt
        setKeys(x, y)
        return
    }

    ; Erreur (ne devrait pas arriver)
    Release("Right", keyRight)
    Release("Left", keyLeft)
    Release("Up", keyUp)
    Release("Down", keyDown)
}

setKeys(x, y)
{
    ; Presser les touches en fonction des valeurs de x et y
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
        DllCall("ClipCursor", "Ptr", 0) ; Libère le curseur
    }
}

; ==== UTILS ====

Press(dir, key)
{
    if !keys[dir]
    {
        Send("{" key " down}")
        keys[dir] := true
    }
}

Release(dir, key)
{
    if keys[dir]
    {
        Send("{" key " up}")
        keys[dir] := false
    }
}

ReleaseAll()
{
    for dir, key in keys
    {
        Release(dir, getKeyForDirection(dir))
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
