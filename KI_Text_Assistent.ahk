; ============================================================
; KI Text-Assistent - ASYNC Version mit parallelen API-Calls
; ============================================================

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode 2

; ========== KONFIG ==========
global G_API_URL := "https://api.openai.com/v1/chat/completions"
global G_MODEL   := "gpt-4o-mini"
global G_API_KEY := "YOUR_OPENAI_API_KEY"

; ========== Globale Variablen ==========
global AsyncRequests := {}
global PendingCount := 0
global GuiIsOpen := false  ; NEU: Tracking ob GUI offen ist

; ========== TRAY & MENÜ ==========
Menu, Tray, NoStandard
Menu, Tray, Add, Fenster öffnen, OpenMainWindow
Menu, Tray, Add
Menu, Tray, Add, Freundlich ersetzen, ReplaceFriendly
Menu, Tray, Add, Technisch ersetzen, ReplaceTechnical
Menu, Tray, Add, Kurz ersetzen, ReplaceShort
Menu, Tray, Add
Menu, Tray, Add, Beenden, CloseApp

Menu, QuickReplace, Add, 😊 Freundlich, ReplaceFriendly
Menu, QuickReplace, Add, 🔧 Technisch, ReplaceTechnical
Menu, QuickReplace, Add, ⭐ Kurz, ReplaceShort
Menu, QuickReplace, Add
Menu, QuickReplace, Add, 📝 GUI öffnen, OpenMainWindow
Menu, QuickReplace, Default, 📝 GUI öffnen

; ========== HOTKEYS ==========
^!x::
    ; Prüfe ob GUI bereits offen ist
    if (GuiIsOpen) {
        ToolTip, ⚠️ GUI ist bereits geöffnet!
        SetTimer, RemoveToolTip, -1500
        return
    }
    
    ; Speichere aktuelle Zwischenablage
    clipSaved := ClipboardAll
    Clipboard := ""
    
    ; Kopiere markierten Text
    Send, ^c
    ClipWait, 0.3
    
    ; Prüfe ob Text kopiert wurde
    if (ErrorLevel || Clipboard = "") {
        Clipboard := clipSaved
        ToolTip, ⚠️ Kein Text markiert!
        SetTimer, RemoveToolTip, -1500
        return
    }
    
    ; Stelle alte Zwischenablage wieder her
    Clipboard := clipSaved
    
    ; Zeige Menü nur wenn Text markiert war
    Menu, QuickReplace, Show
return

^!c::
    ; Prüfe ob GUI bereits offen ist
    if (GuiIsOpen) {
        WinActivate, KI Text-Assistent
        return
    }
    
    Clipboard := ""
    Send, ^c
    ClipWait, 0.3
    if (ErrorLevel) {
        ToolTip, ⚠️ Kein Text markiert!
        SetTimer, RemoveToolTip, -1500
        return
    }
    inputText := Clipboard
    
    GuiIsOpen := true  ; Setze Status auf "offen"
    
    Gui, Destroy
    Gui, Font, s9, Segoe UI
    Gui, Color, F5F5F5
    Gui, Margin, 15, 15

    Gui, Font, s10 Bold
    Gui, Add, Text, cNavy, 📝 Eingabetext (editierbar)
    Gui, Font, s9 Normal
    Gui, Add, Edit, w600 r3 vInputTextField BackgroundWhite, %inputText%
    Gui, Add, Button, x+10 yp w130 h60 gRegenerateAll, 🔄 Neu generieren

    Gui, Font, s10 Bold
    Gui, Add, Text, xm y+15 cNavy, ⚡ Schnellvorschau
    Gui, Font, s8 Normal

    Gui, Add, GroupBox, xm y+8 w240 h220
    Gui, Add, Text, xp+8 yp+12 w224 Center, 😊 FREUNDLICH
    Gui, Add, Edit, xp yp+22 w224 r8 vOutputFreundlich ReadOnly BackgroundWhite
    Gui, Add, Button, xp yp+140 w224 h28 gCopyFreundlich, 📋 Kopieren

    Gui, Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Add, Text, xp+8 yp+12 w224 Center, 🔧 TECHNISCH
    Gui, Add, Edit, xp yp+22 w224 r8 vOutputTechnisch ReadOnly BackgroundWhite
    Gui, Add, Button, xp yp+140 w224 h28 gCopyTechnisch, 📋 Kopieren

    Gui, Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Add, Text, xp+8 yp+12 w224 Center, ⭐ KURZ
    Gui, Add, Edit, xp yp+22 w224 r8 vOutputKurz ReadOnly BackgroundFFFFCC
    Gui, Add, Button, xp yp+140 w224 h28 gCopyKurz, 📋 Kopieren

    Gui, Font, s10 Bold
    Gui, Add, Text, xm y+18 cNavy, 🎨 Individuell
    Gui, Font, s8 Normal
    Gui, Add, Text, xm y+8, Anweisung:
    Gui, Add, Edit, w600 r2 vFreierStil BackgroundWhite
    Gui, Add, Button, x+10 yp w130 h46 gSendFreiStil, 🚀 Generieren

    Gui, Add, Edit, xm y+8 w750 r5 vOutputFrei ReadOnly BackgroundWhite
    Gui, Add, Button, x440 y+5 w150 h28 gCopyFrei, 📋 Kopieren

    Gui, Font, s9
    Gui, Add, Button, x+10 yp w150 h28 gCloseApp, ❌ Schließen

    Gui, Show, AutoSize Center, KI Text-Assistent
    Gui, +Escape

    if (inputText != "") {
        GuiControl,, OutputFreundlich, ⏳ Lädt...
        GuiControl,, OutputTechnisch, ⏳ Lädt...
        GuiControl,, OutputKurz, ⏳ Lädt...
        SetTimer, StartAllRequestsAsync, -100
    }
return

; ========== TRAY: FENSTER ÖFFNEN ==========
OpenMainWindow:
    ; Prüfe ob GUI bereits offen ist
    if (GuiIsOpen) {
        WinActivate, KI Text-Assistent
        return
    }
    
    tempClip := ClipboardAll
    Clipboard := ""
    Send, ^c
    ClipWait, 0.5
    if (ErrorLevel)
        inputText := ""
    else
        inputText := Clipboard
    Clipboard := tempClip
    
    GuiIsOpen := true  ; Setze Status auf "offen"
    
    Gui, Destroy
    Gui, Font, s9, Segoe UI
    Gui, Color, F5F5F5
    Gui, Margin, 15, 15

    Gui, Font, s10 Bold
    Gui, Add, Text, cNavy, 📝 Eingabetext (editierbar)
    Gui, Font, s9 Normal
    Gui, Add, Edit, w600 r3 vInputTextField BackgroundWhite, %inputText%
    Gui, Add, Button, x+10 yp w130 h60 gRegenerateAll, 🔄 Neu generieren

    Gui, Font, s10 Bold
    Gui, Add, Text, xm y+15 cNavy, ⚡ Schnellvorschau
    Gui, Font, s8 Normal

    Gui, Add, GroupBox, xm y+8 w240 h220
    Gui, Add, Text, xp+8 yp+12 w224 Center, 😊 FREUNDLICH
    Gui, Add, Edit, xp yp+22 w224 r8 vOutputFreundlich ReadOnly BackgroundWhite
    Gui, Add, Button, xp yp+140 w224 h28 gCopyFreundlich, 📋 Kopieren

    Gui, Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Add, Text, xp+8 yp+12 w224 Center, 🔧 TECHNISCH
    Gui, Add, Edit, xp yp+22 w224 r8 vOutputTechnisch ReadOnly BackgroundWhite
    Gui, Add, Button, xp yp+140 w224 h28 gCopyTechnisch, 📋 Kopieren

    Gui, Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Add, Text, xp+8 yp+12 w224 Center, ⭐ KURZ
    Gui, Add, Edit, xp yp+22 w224 r8 vOutputKurz ReadOnly BackgroundFFFFCC
    Gui, Add, Button, xp yp+140 w224 h28 gCopyKurz, 📋 Kopieren

    Gui, Font, s10 Bold
    Gui, Add, Text, xm y+18 cNavy, 🎨 Individuell
    Gui, Font, s8 Normal
    Gui, Add, Text, xm y+8, Anweisung:
    Gui, Add, Edit, w600 r2 vFreierStil BackgroundWhite
    Gui, Add, Button, x+10 yp w130 h46 gSendFreiStil, 🚀 Generieren

    Gui, Add, Edit, xm y+8 w750 r5 vOutputFrei ReadOnly BackgroundWhite
    Gui, Add, Button, x440 y+5 w150 h28 gCopyFrei, 📋 Kopieren

    Gui, Font, s9
    Gui, Add, Button, x+10 yp w150 h28 gCloseApp, ❌ Schließen

    Gui, Show, AutoSize Center, KI Text-Assistent
    Gui, +Escape

    if (inputText != "") {
        GuiControl,, OutputFreundlich, ⏳ Lädt...
        GuiControl,, OutputTechnisch, ⏳ Lädt...
        GuiControl,, OutputKurz, ⏳ Lädt...
        SetTimer, StartAllRequestsAsync, -100
    }
return

; ========== GUI AKTIONEN ==========
RegenerateAll:
    Gui, Submit, NoHide
    if (InputTextField = "") {
        MsgBox, 48, Hinweis, Bitte Text eingeben.
        return
    }
    GuiControl,, OutputFreundlich, ⏳ Lädt...
    GuiControl,, OutputTechnisch, ⏳ Lädt...
    GuiControl,, OutputKurz, ⏳ Lädt...
    
    SendRequestAsync("Freundlich", "Formuliere den Text freundlich, respektvoll und natürlich. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:", InputTextField)
    SendRequestAsync("Technisch", "Formuliere den Text sachlich, technisch und präzise. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:", InputTextField)
    SendRequestAsync("Kurz", "Fasse den Text kurz, prägnant und professionell zusammen. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:", InputTextField)
return

StartAllRequestsAsync:
    Gui, Submit, NoHide
    SendRequestAsync("Freundlich", "Formuliere den Text freundlich, respektvoll und natürlich. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:", InputTextField)
    SendRequestAsync("Technisch", "Formuliere den Text sachlich, technisch und präzise. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:", InputTextField)
    SendRequestAsync("Kurz", "Fasse den Text kurz, prägnant und professionell zusammen. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:", InputTextField)
return

SendFreiStil:
    Gui, Submit, NoHide
    if (FreierStil = "" || InputTextField = "") {
        MsgBox, 48, Hinweis, Bitte Stil und Text eingeben.
        return
    }
    GuiControl,, OutputFrei, ⏳ Lädt...
    SendRequestAsync("Frei", FreierStil, InputTextField)
return

; ========== HTTP HILFSFUNKTIONEN ==========
SanitizeForJson(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, """", "\""")
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`t", "\t")
    return str
}

GetAssistantContent(json) {
    content := ""
    if RegExMatch(json, """choices""\s*:\s*\[\s*\{.*?""message""\s*:\s*\{.*?""content""\s*:\s*""((?:[^""\\]|\\.)*)""", m)
        content := m1
    if (content != "") {
        content := StrReplace(content, "\r", "`r")
        content := StrReplace(content, "\n", "`n")
        content := StrReplace(content, "\t", "`t")
        content := StrReplace(content, "\""", """")
        content := StrReplace(content, "\\", "\")
    }
    return content
}

; ========== ASYNCHRONE REQUEST-FUNKTION ==========
SendRequestAsync(styleType, tone, inputText) {
    global G_API_URL, G_MODEL, G_API_KEY, AsyncRequests, PendingCount
    
    prompt := tone . "`n`nText:`n" . inputText
    prompt := SanitizeForJson(prompt)
    body := "{""model"":""" . G_MODEL . """"
          . ",""messages"":[{""role"":""user"",""content"":""" . prompt . """}]"
          . ",""temperature"":0.7"
          . "}"
    
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.Open("POST", G_API_URL, true)
    req.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    req.SetRequestHeader("Authorization", "Bearer " . G_API_KEY)
    
    AsyncRequests[styleType] := {req: req, type: styleType}
    PendingCount++
    
    req.onreadystatechange := Func("OnRequestComplete").Bind(styleType)
    req.Send(body)
}

; ========== CALLBACK FÜR ASYNC-REQUESTS ==========
OnRequestComplete(styleType) {
    global AsyncRequests, PendingCount
    
    reqInfo := AsyncRequests[styleType]
    req := reqInfo.req
    
    if (req.readyState != 4)
        return
    
    PendingCount--
    
    if (req.status == 200) {
        response := req.responseText
        content := GetAssistantContent(response)
        
        if (content != "") {
            GuiControl,, Output%styleType%, %content%
            
            if (styleType = "Kurz") {
                Clipboard := content
                ToolTip, ✅ "Kurz" automatisch kopiert!
                SetTimer, RemoveToolTip, -2000
            }
        } else {
            GuiControl,, Output%styleType%, ⚠️ Leere Antwort
        }
    } else {
        status := req.status
        GuiControl,, Output%styleType%, ⚠️ Fehler (HTTP %status%)
    }
    
    AsyncRequests.Delete(styleType)
}

; ========== QUICK REPLACE (SWAP) ==========
ReplaceFriendly:
    QuickSwapWithGPT("Formuliere den Text freundlich, respektvoll und natürlich. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:")
return

ReplaceTechnical:
    QuickSwapWithGPT("Formuliere den Text sachlich, technisch und präzise. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:")
return

ReplaceShort:
    QuickSwapWithGPT("Fasse den Text kurz, prägnant und professionell zusammen. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:")
return

QuickSwapWithGPT(tone) {
    clipSaved := ClipboardAll
    Clipboard := ""
    Send, ^x
    ClipWait, 1
    if (ErrorLevel) {
        ToolTip, ⚠️ Keine Auswahl gefunden.
        SetTimer, RemoveToolTip, -1500
        Clipboard := clipSaved
        return
    }
    original := Clipboard

    prompt := tone . "`n`nText:`n" . original
    res := CallOpenAISync(prompt)
    respOK := res.ok
    respStatus := res.status
    respContent := res.content

    if (!respOK || respContent = "") {
        Clipboard := original
        Send, ^v
        Sleep, 80
        Clipboard := clipSaved
        ToolTip, ⚠️ Keine Antwort (HTTP %respStatus%)
        SetTimer, RemoveToolTip, -2000
        return
    }

    Clipboard := respContent
    Send, ^v
    Sleep, 120
    Clipboard := original
    Sleep, 80
    Clipboard := clipSaved

    ToolTip, ✅ Ersetzt (Swap mit Historie)!
    SetTimer, RemoveToolTip, -1500
}

; ========== SYNCHRONER CALL ==========
CallOpenAISync(prompt) {
    global G_API_URL, G_MODEL, G_API_KEY

    prompt := SanitizeForJson(prompt)
    body := "{""model"":""" . G_MODEL . """"
          . ",""messages"":[{""role"":""user"",""content"":""" . prompt . """}]"
          . ",""temperature"":0.7"
          . "}"
    
    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", G_API_URL, false)
    http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    http.SetRequestHeader("Accept-Encoding", "identity")
    http.SetRequestHeader("Authorization", "Bearer " . G_API_KEY)
    http.Send(body)

    status := 0
    try status := http.Status

    if (status != 200)
        return {ok: false, status: status, content: ""}

    stream := ComObjCreate("ADODB.Stream")
    stream.Type := 1
    stream.Open()
    stream.Write(http.ResponseBody)
    stream.Position := 0
    stream.Type := 2
    stream.Charset := "UTF-8"
    response := stream.ReadText()
    stream.Close()

    content := GetAssistantContent(response)
    if (content = "")
        return {ok: false, status: status, content: ""}

    return {ok: true, status: status, content: content}
}

; ========== COPY-BUTTONS ==========
CopyFreundlich:
    GuiControlGet, OutputFreundlich
    if (OutputFreundlich = "" || InStr(OutputFreundlich, "⏳") || InStr(OutputFreundlich, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputFreundlich
    ToolTip, ✅ Freundlich kopiert!
    SetTimer, RemoveToolTip, -1500
return

CopyTechnisch:
    GuiControlGet, OutputTechnisch
    if (OutputTechnisch = "" || InStr(OutputTechnisch, "⏳") || InStr(OutputTechnisch, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputTechnisch
    ToolTip, ✅ Technisch kopiert!
    SetTimer, RemoveToolTip, -1500
return

CopyKurz:
    GuiControlGet, OutputKurz
    if (OutputKurz = "" || InStr(OutputKurz, "⏳") || InStr(OutputKurz, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputKurz
    ToolTip, ✅ Kurz kopiert!
    SetTimer, RemoveToolTip, -1500
return

CopyFrei:
    GuiControlGet, OutputFrei
    if (OutputFrei = "" || InStr(OutputFrei, "⏳") || InStr(OutputFrei, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputFrei
    ToolTip, ✅ Frei kopiert!
    SetTimer, RemoveToolTip, -1500
return

; ========== SCHLIEßEN ==========
GuiEscape:
CloseApp:
GuiClose:
    GuiIsOpen := false  ; Setze Status zurück auf "geschlossen"
    Gui, Destroy
return

RemoveToolTip:
    ToolTip
return
