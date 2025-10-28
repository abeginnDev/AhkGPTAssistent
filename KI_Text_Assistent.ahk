; ============================================================
; KI Text-Assistent - ASYNC Version mit Prompt-Verwaltung
; ============================================================

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode 2

; ========== KONFIG ==========
global G_API_URL := "https://api.openai.com/v1/chat/completions"
global G_MODEL   := "gpt-4o-mini"
global G_API_KEY := ""  ; ⚡ Wird nun aus INI geladen

; ========== Globale Variablen ==========
global AsyncRequests := {}
global PendingCount := 0
global GuiIsOpen := false
global OptionsGuiOpen := false
global PROMPTS_FILE := A_ScriptDir . "\prompts.ini"

; Standard-Werte (werden nur beim ersten Start verwendet)
global DEFAULT_API_KEY := ""
global DEFAULT_PROMPT_FREUNDLICH := "Formuliere den Text freundlich, respektvoll und natürlich. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:"
global DEFAULT_PROMPT_TECHNISCH := "Formuliere den Text sachlich, technisch und präzise. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:"
global DEFAULT_PROMPT_UMGANGSSPRACHLICH := "Fasse den Text umgangssprachlich, prägnant und professionell zusammen. Dabei gib wirklich nur den angepassten text zurück, keine beschreibung oder ähnliches. Korrigiere:"

global DEFAULT_TEMP_FREUNDLICH := "0.7"
global DEFAULT_TEMP_TECHNISCH := "0.5"
global DEFAULT_TEMP_UMGANGSSPRACHLICH := "0.7"

; Aktuelle Werte (werden aus Datei geladen)
global PromptFreundlich := ""
global PromptTechnisch := ""
global PromptUmgangssprachlich := ""

global TempFreundlich := 0.7
global TempTechnisch := 0.5
global TempUmgangssprachlich := 0.7

; ========== INITIALISIERUNG ==========
InitializePrompts()
LoadPrompts()

; ========== CONFIG INITIALISIEREN ==========
InitializePrompts() {
    global PROMPTS_FILE, DEFAULT_API_KEY, DEFAULT_PROMPT_FREUNDLICH, DEFAULT_PROMPT_TECHNISCH, DEFAULT_PROMPT_UMGANGSSPRACHLICH
    global DEFAULT_TEMP_FREUNDLICH, DEFAULT_TEMP_TECHNISCH, DEFAULT_TEMP_UMGANGSSPRACHLICH
    
    if !FileExist(PROMPTS_FILE) {
        IniWrite, %DEFAULT_API_KEY%, %PROMPTS_FILE%, Config, APIKey
        IniWrite, %DEFAULT_PROMPT_FREUNDLICH%, %PROMPTS_FILE%, Prompts, Freundlich
        IniWrite, %DEFAULT_PROMPT_TECHNISCH%, %PROMPTS_FILE%, Prompts, Technisch
        IniWrite, %DEFAULT_PROMPT_UMGANGSSPRACHLICH%, %PROMPTS_FILE%, Prompts, Umgangssprachlich
        
        IniWrite, %DEFAULT_TEMP_FREUNDLICH%, %PROMPTS_FILE%, Temperatures, Freundlich
        IniWrite, %DEFAULT_TEMP_TECHNISCH%, %PROMPTS_FILE%, Temperatures, Technisch
        IniWrite, %DEFAULT_TEMP_UMGANGSSPRACHLICH%, %PROMPTS_FILE%, Temperatures, Umgangssprachlich
        
        ToolTip, ✅ Config-Datei erstellt!
        SetTimer, RemoveToolTip, -2000
    }
}

; ========== CONFIG AUS DATEI LADEN ==========
LoadPrompts() {
    global PROMPTS_FILE, G_API_KEY, PromptFreundlich, PromptTechnisch, PromptUmgangssprachlich
    global TempFreundlich, TempTechnisch, TempUmgangssprachlich
    global DEFAULT_API_KEY, DEFAULT_PROMPT_FREUNDLICH, DEFAULT_PROMPT_TECHNISCH, DEFAULT_PROMPT_UMGANGSSPRACHLICH
    global DEFAULT_TEMP_FREUNDLICH, DEFAULT_TEMP_TECHNISCH, DEFAULT_TEMP_UMGANGSSPRACHLICH
    
    IniRead, G_API_KEY, %PROMPTS_FILE%, Config, APIKey, %DEFAULT_API_KEY%
    IniRead, PromptFreundlich, %PROMPTS_FILE%, Prompts, Freundlich, %DEFAULT_PROMPT_FREUNDLICH%
    IniRead, PromptTechnisch, %PROMPTS_FILE%, Prompts, Technisch, %DEFAULT_PROMPT_TECHNISCH%
    IniRead, PromptUmgangssprachlich, %PROMPTS_FILE%, Prompts, Umgangssprachlich, %DEFAULT_PROMPT_UMGANGSSPRACHLICH%
    
    IniRead, TempFreundlich, %PROMPTS_FILE%, Temperatures, Freundlich, %DEFAULT_TEMP_FREUNDLICH%
    IniRead, TempTechnisch, %PROMPTS_FILE%, Temperatures, Technisch, %DEFAULT_TEMP_TECHNISCH%
    IniRead, TempUmgangssprachlich, %PROMPTS_FILE%, Temperatures, Umgangssprachlich, %DEFAULT_TEMP_UMGANGSSPRACHLICH%
    
    ; Werte in Zahlen konvertieren
    TempFreundlich := TempFreundlich + 0.0
    TempTechnisch := TempTechnisch + 0.0
    TempUmgangssprachlich := TempUmgangssprachlich + 0.0
}

; ========== CONFIG IN DATEI SPEICHERN ==========
SavePrompts(newAPIKey, newFreundlich, newTechnisch, newUmgangssprachlich, newTempFreundlich, newTempTechnisch, newTempUmgangssprachlich) {
    global PROMPTS_FILE, G_API_KEY, PromptFreundlich, PromptTechnisch, PromptUmgangssprachlich
    global TempFreundlich, TempTechnisch, TempUmgangssprachlich
    
    IniWrite, %newAPIKey%, %PROMPTS_FILE%, Config, APIKey
    IniWrite, %newFreundlich%, %PROMPTS_FILE%, Prompts, Freundlich
    IniWrite, %newTechnisch%, %PROMPTS_FILE%, Prompts, Technisch
    IniWrite, %newUmgangssprachlich%, %PROMPTS_FILE%, Prompts, Umgangssprachlich
    
    IniWrite, %newTempFreundlich%, %PROMPTS_FILE%, Temperatures, Freundlich
    IniWrite, %newTempTechnisch%, %PROMPTS_FILE%, Temperatures, Technisch
    IniWrite, %newTempUmgangssprachlich%, %PROMPTS_FILE%, Temperatures, Umgangssprachlich
    
    G_API_KEY := newAPIKey
    PromptFreundlich := newFreundlich
    PromptTechnisch := newTechnisch
    PromptUmgangssprachlich := newUmgangssprachlich
    TempFreundlich := newTempFreundlich + 0.0
    TempTechnisch := newTempTechnisch + 0.0
    TempUmgangssprachlich := newTempUmgangssprachlich + 0.0
}

; ========== TRAY & MENÜ ==========
Menu, Tray, NoStandard
Menu, Tray, Add, Fenster öffnen, OpenMainWindow
Menu, Tray, Add, Optionen / Einstellungen bearbeiten, OpenOptionsWindow
Menu, Tray, Add
Menu, Tray, Add, Freundlich ersetzen, ReplaceFriendly
Menu, Tray, Add, Technisch ersetzen, ReplaceTechnical
Menu, Tray, Add, Umgangssprachlich ersetzen, ReplaceShort
Menu, Tray, Add
Menu, Tray, Add, Beenden, CloseApp

Menu, QuickReplace, Add, 😊 Freundlich, ReplaceFriendly
Menu, QuickReplace, Add, 🔧 Technisch, ReplaceTechnical
Menu, QuickReplace, Add, ⭐ Umgangssprachlich, ReplaceShort
Menu, QuickReplace, Add
Menu, QuickReplace, Add, 📝 GUI öffnen, OpenMainWindow
Menu, QuickReplace, Default, 📝 GUI öffnen

; ========== HOTKEYS ==========
^!x::
    if (GuiIsOpen) {
        ToolTip, ⚠️ GUI ist bereits geöffnet!
        SetTimer, RemoveToolTip, -1000
        return
    }
    
    clipSaved := ClipboardAll
    Clipboard := ""
    Send, ^c
    ClipWait, 0.3
    
    if (ErrorLevel || Clipboard = "") {
        Clipboard := clipSaved
        ToolTip, ⚠️ Kein Text markiert!
        SetTimer, RemoveToolTip, -1000
        return
    }
    
    Clipboard := clipSaved
    Menu, QuickReplace, Show
return

^!c::
    if (GuiIsOpen) {
        WinActivate, KI Text-Assistent
        return
    }
    
    Clipboard := ""
    Send, ^c
    ClipWait, 0.3
    inputText := Clipboard
    
    GuiIsOpen := true
    
    Gui, Main:Destroy
    Gui, Main:Font, s9, Segoe UI
    Gui, Main:Color, F5F5F5
    Gui, Main:Margin, 15, 15

    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, cNavy, 📝 Eingabetext (editierbar)
    Gui, Main:Font, s9 Normal
    Gui, Main:Add, Edit, w600 r3 vInputTextField BackgroundWhite, %inputText%
    Gui, Main:Add, Button, x+10 yp w130 h60 gRegenerateAll, 🔄 Neu generieren

    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, xm y+15 cNavy, ⚡ Schnellvorschau
    Gui, Main:Font, s8 Normal

    Gui, Main:Add, GroupBox, xm y+8 w240 h220
    Gui, Main:Add, Text, xp+8 yp+12 w224 Center, 😊 FREUNDLICH
    Gui, Main:Add, Edit, xp yp+22 w224 r8 vOutputFreundlich ReadOnly BackgroundWhite
    Gui, Main:Add, Button, xp yp+140 w224 h28 gCopyFreundlich, 📋 Kopieren

    Gui, Main:Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Main:Add, Text, xp+8 yp+12 w224 Center, 🔧 TECHNISCH
    Gui, Main:Add, Edit, xp yp+22 w224 r8 vOutputTechnisch ReadOnly BackgroundWhite
    Gui, Main:Add, Button, xp yp+140 w224 h28 gCopyTechnisch, 📋 Kopieren

    Gui, Main:Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Main:Add, Text, xp+8 yp+12 w224 Center, ⭐ UMGANGSSPRACHLICH
    Gui, Main:Add, Edit, xp yp+22 w224 r8 vOutputUmgangssprachlich ReadOnly BackgroundFFFFCC
    Gui, Main:Add, Button, xp yp+140 w224 h28 gCopyUmgangssprachlich, 📋 Kopieren

    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, xm y+18 cNavy, 🎨 Individuell
    Gui, Main:Font, s8 Normal
    Gui, Main:Add, Text, xm y+8, Anweisung:
    Gui, Main:Add, Edit, w600 r2 vFreierStil BackgroundWhite
    Gui, Main:Add, Button, x+10 yp w130 h46 gSendFreiStil, 🚀 Generieren

    Gui, Main:Add, Edit, xm y+8 w750 r5 vOutputFrei ReadOnly BackgroundWhite
    
    Gui, Main:Font, s9
    Gui, Main:Add, Button, xm y+8 w150 h28 gCopyFrei, 📋 Kopieren
    Gui, Main:Add, Button, x+10 yp w150 h28 gOpenOptionsWindow, ⚙️ Optionen
    Gui, Main:Add, Button, x+10 yp w150 h28 gMainGuiClose, ❌ Schließen

    Gui, Main:Show, AutoSize Center, KI Text-Assistent

    if (inputText != "") {
        GuiControl, Main:, OutputFreundlich, ⏳ Lädt...
        GuiControl, Main:, OutputTechnisch, ⏳ Lädt...
        GuiControl, Main:, OutputUmgangssprachlich, ⏳ Lädt...
        SetTimer, StartAllRequestsAsync, -100
    }
return

; ========== TRAY: FENSTER ÖFFNEN ==========
OpenMainWindow:
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
    
    GuiIsOpen := true
    
    Gui, Main:Destroy
    Gui, Main:Font, s9, Segoe UI
    Gui, Main:Color, F5F5F5
    Gui, Main:Margin, 15, 15

    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, cNavy, 📝 Eingabetext (editierbar)
    Gui, Main:Font, s9 Normal
    Gui, Main:Add, Edit, w600 r3 vInputTextField BackgroundWhite, %inputText%
    Gui, Main:Add, Button, x+10 yp w130 h60 gRegenerateAll, 🔄 Neu generieren

    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, xm y+15 cNavy, ⚡ Schnellvorschau
    Gui, Main:Font, s8 Normal

    Gui, Main:Add, GroupBox, xm y+8 w240 h220
    Gui, Main:Add, Text, xp+8 yp+12 w224 Center, 😊 FREUNDLICH
    Gui, Main:Add, Edit, xp yp+22 w224 r8 vOutputFreundlich ReadOnly BackgroundWhite
    Gui, Main:Add, Button, xp yp+140 w224 h28 gCopyFreundlich, 📋 Kopieren

    Gui, Main:Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Main:Add, Text, xp+8 yp+12 w224 Center, 🔧 TECHNISCH
    Gui, Main:Add, Edit, xp yp+22 w224 r8 vOutputTechnisch ReadOnly BackgroundWhite
    Gui, Main:Add, Button, xp yp+140 w224 h28 gCopyTechnisch, 📋 Kopieren

    Gui, Main:Add, GroupBox, x+15 yp-174 w240 h220
    Gui, Main:Add, Text, xp+8 yp+12 w224 Center, ⭐ UMGANGSSPRACHLICH
    Gui, Main:Add, Edit, xp yp+22 w224 r8 vOutputUmgangssprachlich ReadOnly BackgroundFFFFCC
    Gui, Main:Add, Button, xp yp+140 w224 h28 gCopyUmgangssprachlich, 📋 Kopieren

    Gui, Main:Font, s10 Bold
    Gui, Main:Add, Text, xm y+18 cNavy, 🎨 Individuell
    Gui, Main:Font, s8 Normal
    Gui, Main:Add, Text, xm y+8, Anweisung:
    Gui, Main:Add, Edit, w600 r2 vFreierStil BackgroundWhite
    Gui, Main:Add, Button, x+10 yp w130 h46 gSendFreiStil, 🚀 Generieren

    Gui, Main:Add, Edit, xm y+8 w750 r5 vOutputFrei ReadOnly BackgroundWhite
    
    Gui, Main:Font, s9
    Gui, Main:Add, Button, xm y+8 w150 h28 gCopyFrei, 📋 Kopieren
    Gui, Main:Add, Button, x+10 yp w150 h28 gOpenOptionsWindow, ⚙️ Optionen
    Gui, Main:Add, Button, x+10 yp w150 h28 gMainGuiClose, ❌ Schließen

    Gui, Main:Show, AutoSize Center, KI Text-Assistent

    if (inputText != "") {
        GuiControl, Main:, OutputFreundlich, ⏳ Lädt...
        GuiControl, Main:, OutputTechnisch, ⏳ Lädt...
        GuiControl, Main:, OutputUmgangssprachlich, ⏳ Lädt...
        SetTimer, StartAllRequestsAsync, -100
    }
return

; ========== OPTIONEN FENSTER ==========
OpenOptionsWindow:
    if (OptionsGuiOpen) {
        WinActivate, Einstellungen
        return
    }
    
    OptionsGuiOpen := true
    
    Gui, Options:Destroy
    Gui, Options:Font, s9, Segoe UI
    Gui, Options:Color, F5F5F5
    Gui, Options:Margin, 15, 15
    
    Gui, Options:Font, s10 Bold
    Gui, Options:Add, Text, cNavy, ⚙️ Einstellungen
    Gui, Options:Font, s9 Normal
    
    Gui, Options:Add, Text, xm y+15, 🔑 OpenAI API-Key:
    Gui, Options:Add, Edit, xm y+5 w700 r1 vOptAPIKey Password, %G_API_KEY%
    
    Gui, Options:Font, s10 Bold
    Gui, Options:Add, Text, xm y+15 cNavy, 📝 Prompt-Einstellungen
    Gui, Options:Font, s9 Normal
    
    Gui, Options:Add, Text, xm y+10, 😊 Freundlich:
    Gui, Options:Add, Edit, xm y+5 w700 r3 vOptPromptFreundlich, %PromptFreundlich%
    Gui, Options:Add, Text, xm y+5, 🌡️ Temperatur:
    Gui, Options:Add, DropDownList, xm y+5 w100 vOptTempFreundlich, 0.1|0.3|0.5|0.7|0.9|1.0|1.2|1.5|1.8|2.0
    
    Gui, Options:Add, Text, xm y+15, 🔧 Technisch:
    Gui, Options:Add, Edit, xm y+5 w700 r3 vOptPromptTechnisch, %PromptTechnisch%
    Gui, Options:Add, Text, xm y+5, 🌡️ Temperatur:
    Gui, Options:Add, DropDownList, xm y+5 w100 vOptTempTechnisch, 0.1|0.3|0.5|0.7|0.9|1.0|1.2|1.5|1.8|2.0
    
    Gui, Options:Add, Text, xm y+15, ⭐ Umgangssprachlich:
    Gui, Options:Add, Edit, xm y+5 w700 r3 vOptPromptUmgangssprachlich, %PromptUmgangssprachlich%
    Gui, Options:Add, Text, xm y+5, 🌡️ Temperatur:
    Gui, Options:Add, DropDownList, xm y+5 w100 vOptTempUmgangssprachlich, 0.1|0.3|0.5|0.7|0.9|1.0|1.2|1.5|1.8|2.0
    
    Gui, Options:Add, Button, xm y+20 w200 h35 gSavePromptsFromGui, 💾 Speichern
    Gui, Options:Add, Button, x+10 yp w200 h35 gResetPromptsToDefault, 🔄 Zurücksetzen
    Gui, Options:Add, Button, x+10 yp w200 h35 gOptionsGuiClose, ❌ Schließen
    
    Gui, Options:Show, AutoSize Center, Einstellungen
    
    ; Wähle die Werte NACH dem Show mit Choose
    FormattedTempFreundlich := Format("{:.1f}", TempFreundlich)
    FormattedTempTechnisch := Format("{:.1f}", TempTechnisch)
    FormattedTempUmgangssprachlich := Format("{:.1f}", TempUmgangssprachlich)
    
    GuiControl, Options:Choose, OptTempFreundlich, %FormattedTempFreundlich%
    GuiControl, Options:Choose, OptTempTechnisch, %FormattedTempTechnisch%
    GuiControl, Options:Choose, OptTempUmgangssprachlich, %FormattedTempUmgangssprachlich%
return




; ========== CONFIG AUS GUI SPEICHERN ==========
SavePromptsFromGui:
    Gui, Options:Submit, NoHide
    
    ; Temperatur-Werte konvertieren zu Zahlen (wichtig!)
    tempFreundlichValue := OptTempFreundlich + 0.0
    tempTechnischValue := OptTempTechnisch + 0.0
    tempUmgangssprachlichValue := OptTempUmgangssprachlich + 0.0
    
    SavePrompts(OptAPIKey, OptPromptFreundlich, OptPromptTechnisch, OptPromptUmgangssprachlich, tempFreundlichValue, tempTechnischValue, tempUmgangssprachlichValue)
    ToolTip, ✅ Einstellungen gespeichert!
    SetTimer, RemoveToolTip, -1000
    OptionsGuiOpen := false
    Gui, Options:Destroy
return

; ========== CONFIG AUF STANDARD ZURÜCKSETZEN ==========
ResetPromptsToDefault:
    global DEFAULT_API_KEY, DEFAULT_PROMPT_FREUNDLICH, DEFAULT_PROMPT_TECHNISCH, DEFAULT_PROMPT_UMGANGSSPRACHLICH
    global DEFAULT_TEMP_FREUNDLICH, DEFAULT_TEMP_TECHNISCH, DEFAULT_TEMP_UMGANGSSPRACHLICH
    
    SavePrompts(DEFAULT_API_KEY, DEFAULT_PROMPT_FREUNDLICH, DEFAULT_PROMPT_TECHNISCH, DEFAULT_PROMPT_UMGANGSSPRACHLICH, DEFAULT_TEMP_FREUNDLICH, DEFAULT_TEMP_TECHNISCH, DEFAULT_TEMP_UMGANGSSPRACHLICH)
    
    GuiControl, Options:, OptAPIKey, %DEFAULT_API_KEY%
    GuiControl, Options:, OptPromptFreundlich, %DEFAULT_PROMPT_FREUNDLICH%
    GuiControl, Options:, OptPromptTechnisch, %DEFAULT_PROMPT_TECHNISCH%
    GuiControl, Options:, OptPromptUmgangssprachlich, %DEFAULT_PROMPT_UMGANGSSPRACHLICH%
    GuiControl, Options:, OptTempFreundlich, %DEFAULT_TEMP_FREUNDLICH%
    GuiControl, Options:, OptTempTechnisch, %DEFAULT_TEMP_TECHNISCH%
    GuiControl, Options:, OptTempUmgangssprachlich, %DEFAULT_TEMP_UMGANGSSPRACHLICH%
    
    ToolTip, ✅ Einstellungen auf Standard zurückgesetzt!
    SetTimer, RemoveToolTip, -1000
return

; ========== GUI AKTIONEN ==========
RegenerateAll:
    Gui, Main:Submit, NoHide
    if (InputTextField = "") {
        MsgBox, 48, Hinweis, Bitte Text eingeben.
        return
    }
    
    GuiControl, Main:, OutputFreundlich, ⏳ Lädt...
    GuiControl, Main:, OutputTechnisch, ⏳ Lädt...
    GuiControl, Main:, OutputUmgangssprachlich, ⏳ Lädt...
    
    SendRequestAsync("Freundlich", PromptFreundlich, InputTextField, TempFreundlich)
    SendRequestAsync("Technisch", PromptTechnisch, InputTextField, TempTechnisch)
    SendRequestAsync("Umgangssprachlich", PromptUmgangssprachlich, InputTextField, TempUmgangssprachlich)
return

StartAllRequestsAsync:
    Gui, Main:Submit, NoHide
    
    SendRequestAsync("Freundlich", PromptFreundlich, InputTextField, TempFreundlich)
    SendRequestAsync("Technisch", PromptTechnisch, InputTextField, TempTechnisch)
    SendRequestAsync("Umgangssprachlich", PromptUmgangssprachlich, InputTextField, TempUmgangssprachlich)
return

SendFreiStil:
    Gui, Main:Submit, NoHide
    if (FreierStil = "" || InputTextField = "") {
        MsgBox, 48, Hinweis, Bitte Stil und Text eingeben.
        return
    }
    GuiControl, Main:, OutputFrei, ⏳ Lädt...
    SendRequestAsync("Frei", FreierStil, InputTextField, 0.7)
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
SendRequestAsync(styleType, tone, inputText, temperature) {
    global G_API_URL, G_MODEL, G_API_KEY, AsyncRequests, PendingCount
    
    prompt := tone . "`n`nText:`n" . inputText
    prompt := SanitizeForJson(prompt)
    body := "{""model"":""" . G_MODEL . """"
          . ",""messages"":[{""role"":""user"",""content"":""" . prompt . """}]"
          . ",""temperature"":" . temperature
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
            GuiControl, Main:, Output%styleType%, %content%
            
            if (styleType = "Umgangssprachlich") {
                Clipboard := content
                ToolTip, ✅ "Umgangssprachlich" automatisch kopiert!
                SetTimer, RemoveToolTip, -2000
            }
        } else {
            GuiControl, Main:, Output%styleType%, ⚠️ Leere Antwort
        }
    } else {
        status := req.status
        GuiControl, Main:, Output%styleType%, ⚠️ Fehler (HTTP %status%)
    }
    
    AsyncRequests.Delete(styleType)
}

; ========== QUICK REPLACE (SWAP) ==========
ReplaceFriendly:
    QuickSwapWithGPT(PromptFreundlich, TempFreundlich)
return

ReplaceTechnical:
    QuickSwapWithGPT(PromptTechnisch, TempTechnisch)
return

ReplaceShort:
    QuickSwapWithGPT(PromptUmgangssprachlich, TempUmgangssprachlich)
return

QuickSwapWithGPT(tone, temperature) {
    clipSaved := ClipboardAll
    Clipboard := ""
    Send, ^x
    ClipWait, 1
    if (ErrorLevel) {
        ToolTip, ⚠️ Keine Auswahl gefunden.
        SetTimer, RemoveToolTip, -1000
        Clipboard := clipSaved
        return
    }
    original := Clipboard

    prompt := tone . "`n`nText:`n" . original
    res := CallOpenAISync(prompt, temperature)
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
    SetTimer, RemoveToolTip, -1000
}

; ========== SYNCHRONER CALL ==========
CallOpenAISync(prompt, temperature) {
    global G_API_URL, G_MODEL, G_API_KEY

    prompt := SanitizeForJson(prompt)
    body := "{""model"":""" . G_MODEL . """"
          . ",""messages"":[{""role"":""user"",""content"":""" . prompt . """}]"
          . ",""temperature"":" . temperature
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
    GuiControlGet, OutputFreundlich, Main:
    if (OutputFreundlich = "" || InStr(OutputFreundlich, "⏳") || InStr(OutputFreundlich, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputFreundlich
    ToolTip, ✅ Freundlich kopiert!
    SetTimer, RemoveToolTip, -1000
return

CopyTechnisch:
    GuiControlGet, OutputTechnisch, Main:
    if (OutputTechnisch = "" || InStr(OutputTechnisch, "⏳") || InStr(OutputTechnisch, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputTechnisch
    ToolTip, ✅ Technisch kopiert!
    SetTimer, RemoveToolTip, -1000
return

CopyUmgangssprachlich:
    GuiControlGet, OutputUmgangssprachlich, Main:
    if (OutputUmgangssprachlich = "" || InStr(OutputUmgangssprachlich, "⏳") || InStr(OutputUmgangssprachlich, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputUmgangssprachlich
    ToolTip, ✅ Umgangssprachlich kopiert!
    SetTimer, RemoveToolTip, -1000
return

CopyFrei:
    GuiControlGet, OutputFrei, Main:
    if (OutputFrei = "" || InStr(OutputFrei, "⏳") || InStr(OutputFrei, "⚠️")) {
        MsgBox, 48, Hinweis, Noch kein Inhalt zum Kopieren.
        return
    }
    Clipboard := OutputFrei
    ToolTip, ✅ Frei kopiert!
    SetTimer, RemoveToolTip, -1000
return



; ========== SCHLIEßEN ==========
MainGuiClose:
    GuiIsOpen := false
    Gui, Main:Destroy
return

OptionsGuiClose:
    OptionsGuiOpen := false
    Gui, Options:Destroy
return

CloseApp:
    ExitApp
return

RemoveToolTip:
    ToolTip
return
