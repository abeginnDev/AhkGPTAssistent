; ============================================================
; KI Text-Assistent - ASYNC Version mit Multi-Model Support
; AutoHotkey v2 Version
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

; ========== GLOBALE VARIABLEN & DEFAULTS ==========
; Standardwerte (Fallback, falls INI leer)
global DEFAULT_API_URL := "https://api.openai.com/v1/chat/completions"
global DEFAULT_MODEL   := "gpt-4o-mini"
global DEFAULT_API_KEY := ""

; Globale Konfig-Variablen (werden aus INI gefüllt)
global G_API_URL := ""
global G_MODEL   := ""
global G_API_KEY := ""

; Request Management
global AsyncRequests := Map()
global PendingCount := 0
global GuiIsOpen := false
global OptionsGuiOpen := false
global PROMPTS_FILE := A_ScriptDir . "\prompts.ini"

; GUI Objekte
global MainGui := ""
global OptionsGui := ""

; GUI Controls (Main)
global cInputTextField := ""
global cOutputFreundlich := ""
global cOutputTechnisch := ""
global cOutputUmgangssprachlich := ""
global cFreierStil := ""
global cOutputFrei := ""

; GUI Controls (Options)
global cOptApiUrl := ""
global cOptModel := ""
global cOptApiKey := ""
global cOptMonitor := ""
global cOptRememberPosition := ""
global cOptPromptFreundlich := "", cOptTempFreundlich := ""
global cOptPromptTechnisch := "", cOptTempTechnisch := ""
global cOptPromptUmgangssprachlich := "", cOptTempUmgangssprachlich := ""

; Monitor & Position
global PreferredMonitor := 1
global MonitorCount := 0
global MonitorListString := ""
global RememberPosition := 1
global LastPosX := 0
global LastPosY := 0
global LastMonitor := 1

; Standard-Prompts
global DEFAULT_PROMPT_FREUNDLICH := "Formuliere den Text freundlich, respektvoll und natürlich um. Bewahre die ursprüngliche Bedeutung. Wenn keine Änderungen nötig sind, gib den Text unverändert zurück. Gib ausschließlich den angepassten Text aus, ohne jegliche Erklärung. Korrigiere:"
global DEFAULT_PROMPT_TECHNISCH := "Korrigieren Sie den folgenden Text sachlich, präzise und technisch korrekt (Ticket-Antwort an Kunden, Sie-Form). Programmier-Slang und Fachbegriffe möglichst beibehalten. Nur ändern, wenn nötig, sonst unverändert lassen. Geben Sie ausschließlich den Text aus, ohne Kommentare. Text:"
global DEFAULT_PROMPT_UMGANGSSPRACHLICH := "Korrigiere den Text mit wenig Satzbaukorrektur locker und umgangssprachlich. Bewahre den Sinn. Wenn der Text bereits passend ist, gib ihn unverändert zurück. Gib nur den angepassten Text aus, ohne weitere Kommentare. Korrigiere:"

global DEFAULT_TEMP_FREUNDLICH := "0.7"
global DEFAULT_TEMP_TECHNISCH := "0.5"
global DEFAULT_TEMP_UMGANGSSPRACHLICH := "0.7"

; Aktuelle Prompt-Werte
global PromptFreundlich := ""
global PromptTechnisch := ""
global PromptUmgangssprachlich := ""

global TempFreundlich := 0.7
global TempTechnisch := 0.5
global TempUmgangssprachlich := 0.7

; ========== INITIALISIERUNG ==========
InitializePrompts()
LoadPrompts()

; Tray Menü erstellen
SetupTrayMenu()
SetupQuickReplaceMenu()

; ========== CONFIG INITIALISIEREN ==========
InitializePrompts() {
    global
    
    if !FileExist(PROMPTS_FILE) {
        ; Config Section mit neuen Feldern
        IniWrite(DEFAULT_API_URL, PROMPTS_FILE, "Config", "APIUrl")
        IniWrite(DEFAULT_MODEL,   PROMPTS_FILE, "Config", "Model")
        IniWrite(DEFAULT_API_KEY, PROMPTS_FILE, "Config", "APIKey")
        
        IniWrite(1, PROMPTS_FILE, "Config", "PreferredMonitor")
        IniWrite(1, PROMPTS_FILE, "Config", "RememberPosition")
        IniWrite(0, PROMPTS_FILE, "GUI", "LastPosX")
        IniWrite(0, PROMPTS_FILE, "GUI", "LastPosY")
        IniWrite(1, PROMPTS_FILE, "GUI", "LastMonitor")
        
        IniWrite(DEFAULT_PROMPT_FREUNDLICH, PROMPTS_FILE, "Prompts", "Freundlich")
        IniWrite(DEFAULT_PROMPT_TECHNISCH, PROMPTS_FILE, "Prompts", "Technisch")
        IniWrite(DEFAULT_PROMPT_UMGANGSSPRACHLICH, PROMPTS_FILE, "Prompts", "Umgangssprachlich")
        
        IniWrite(DEFAULT_TEMP_FREUNDLICH, PROMPTS_FILE, "Temperatures", "Freundlich")
        IniWrite(DEFAULT_TEMP_TECHNISCH, PROMPTS_FILE, "Temperatures", "Technisch")
        IniWrite(DEFAULT_TEMP_UMGANGSSPRACHLICH, PROMPTS_FILE, "Temperatures", "Umgangssprachlich")
        
        ShowToolTip("✅ Config-Datei erstellt!")
    }
}

; ========== CONFIG AUS DATEI LADEN ==========
LoadPrompts() {
    global
    
    ; Lade API Konfiguration
    G_API_URL := IniRead(PROMPTS_FILE, "Config", "APIUrl", DEFAULT_API_URL)
    G_MODEL   := IniRead(PROMPTS_FILE, "Config", "Model",  DEFAULT_MODEL)
    G_API_KEY := IniRead(PROMPTS_FILE, "Config", "APIKey", DEFAULT_API_KEY)
    
    PreferredMonitor := Integer(IniRead(PROMPTS_FILE, "Config", "PreferredMonitor", 1))
    RememberPosition := Integer(IniRead(PROMPTS_FILE, "Config", "RememberPosition", 1))
    LastPosX := Integer(IniRead(PROMPTS_FILE, "GUI", "LastPosX", 0))
    LastPosY := Integer(IniRead(PROMPTS_FILE, "GUI", "LastPosY", 0))
    LastMonitor := Integer(IniRead(PROMPTS_FILE, "GUI", "LastMonitor", 1))
    
    PromptFreundlich := IniRead(PROMPTS_FILE, "Prompts", "Freundlich", DEFAULT_PROMPT_FREUNDLICH)
    PromptTechnisch := IniRead(PROMPTS_FILE, "Prompts", "Technisch", DEFAULT_PROMPT_TECHNISCH)
    PromptUmgangssprachlich := IniRead(PROMPTS_FILE, "Prompts", "Umgangssprachlich", DEFAULT_PROMPT_UMGANGSSPRACHLICH)
    
    TempFreundlich := Float(IniRead(PROMPTS_FILE, "Temperatures", "Freundlich", DEFAULT_TEMP_FREUNDLICH))
    TempTechnisch := Float(IniRead(PROMPTS_FILE, "Temperatures", "Technisch", DEFAULT_TEMP_TECHNISCH))
    TempUmgangssprachlich := Float(IniRead(PROMPTS_FILE, "Temperatures", "Umgangssprachlich", DEFAULT_TEMP_UMGANGSSPRACHLICH))
}

; ========== CONFIG IN DATEI SPEICHERN ==========
SavePrompts(newApiUrl, newModel, newApiKey, newFreundlich, newTechnisch, newUmgangssprachlich, newTempFreundlich, newTempTechnisch, newTempUmgangssprachlich, newMonitor := "", newRememberPos := "") {
    global
    
    IniWrite(newApiUrl, PROMPTS_FILE, "Config", "APIUrl")
    IniWrite(newModel,  PROMPTS_FILE, "Config", "Model")
    IniWrite(newApiKey, PROMPTS_FILE, "Config", "APIKey")
    
    IniWrite(newFreundlich, PROMPTS_FILE, "Prompts", "Freundlich")
    IniWrite(newTechnisch, PROMPTS_FILE, "Prompts", "Technisch")
    IniWrite(newUmgangssprachlich, PROMPTS_FILE, "Prompts", "Umgangssprachlich")
    
    IniWrite(newTempFreundlich, PROMPTS_FILE, "Temperatures", "Freundlich")
    IniWrite(newTempTechnisch, PROMPTS_FILE, "Temperatures", "Technisch")
    IniWrite(newTempUmgangssprachlich, PROMPTS_FILE, "Temperatures", "Umgangssprachlich")
    
    if (newMonitor != "") {
        IniWrite(newMonitor, PROMPTS_FILE, "Config", "PreferredMonitor")
        PreferredMonitor := newMonitor
    }
    
    if (newRememberPos != "") {
        IniWrite(newRememberPos, PROMPTS_FILE, "Config", "RememberPosition")
        RememberPosition := newRememberPos
    }
    
    ; Globale Variablen sofort aktualisieren
    G_API_URL := newApiUrl
    G_MODEL   := newModel
    G_API_KEY := newApiKey
    
    PromptFreundlich := newFreundlich
    PromptTechnisch := newTechnisch
    PromptUmgangssprachlich := newUmgangssprachlich
    TempFreundlich := Float(newTempFreundlich)
    TempTechnisch := Float(newTempTechnisch)
    TempUmgangssprachlich := Float(newTempUmgangssprachlich)
}

; ========== POSITION SPEICHERN ==========
SaveGuiPosition(guiObj) {
    global
    
    if (!RememberPosition)
        return
    
    try {
        guiObj.GetPos(&x, &y)
        
        if (x == "" || y == "")
            return
        
        monitorNum := GetMonitorAtPosition(x, y)
        
        IniWrite(x, PROMPTS_FILE, "GUI", "LastPosX")
        IniWrite(y, PROMPTS_FILE, "GUI", "LastPosY")
        IniWrite(monitorNum, PROMPTS_FILE, "GUI", "LastMonitor")
        
        LastPosX := x
        LastPosY := y
        LastMonitor := monitorNum
    }
}

; ========== MONITOR HELPER ==========
GetMonitorAtPosition(x, y) {
    monCount := MonitorGetCount()
    Loop monCount {
        MonitorGet(A_Index, &MonLeft, &MonTop, &MonRight, &MonBottom)
        if (x >= MonLeft && x <= MonRight && y >= MonTop && y <= MonBottom)
            return A_Index
    }
    return 1
}

IsPositionValid(x, y, monitorNum) {
    monCount := MonitorGetCount()
    if (monitorNum < 1 || monitorNum > monCount)
        return false
    MonitorGet(monitorNum, &MonLeft, &MonTop, &MonRight, &MonBottom)
    if (x < MonLeft - 100 || x > MonRight || y < MonTop - 100 || y > MonBottom)
        return false
    return true
}

PositionGuiOnMonitor(guiObj, monitorNum) {
    global RememberPosition, LastPosX, LastPosY, LastMonitor
    realMonCount := MonitorGetCount()
    
    if (RememberPosition && LastPosX != 0 && LastPosY != 0) {
        if (IsPositionValid(LastPosX, LastPosY, LastMonitor)) {
            guiObj.Show("x" . LastPosX . " y" . LastPosY)
            return
        }
    }
    
    if (monitorNum < 1 || monitorNum > realMonCount)
        monitorNum := 1
    
    MonitorGet(monitorNum, &MonLeft, &MonTop, &MonRight, &MonBottom)
    posX := MonLeft + 20
    posY := MonTop + 20
    guiObj.Show("x" . posX . " y" . posY)
}

GetMonitorInfo() {
    global MonitorCount, MonitorListString
    MonitorCount := MonitorGetCount()
    MonitorListString := [] 
    Loop MonitorCount {
        MonitorGet(A_Index, &MonLeft, &MonTop, &MonRight, &MonBottom)
        width := MonRight - MonLeft
        height := MonBottom - MonTop
        MonitorListString.Push("Monitor " . A_Index . " (" . width . "x" . height . ")")
    }
    return MonitorCount
}

; ========== TRAY & MENÜ ==========
SetupTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Fenster öffnen", OpenMainWindow)
    A_TrayMenu.Add("Optionen / Einstellungen", OpenOptionsWindow)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Freundlich ersetzen", ReplaceFriendly)
    A_TrayMenu.Add("Technisch ersetzen", ReplaceTechnical)
    A_TrayMenu.Add("Umgangssprachlich ersetzen", ReplaceShort)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Beenden", CloseApp)
}

SetupQuickReplaceMenu() {
    global QuickReplaceMenu := Menu()
    QuickReplaceMenu.Add("😊 Freundlich", ReplaceFriendly)
    QuickReplaceMenu.Add("🔧 Technisch", ReplaceTechnical)
    QuickReplaceMenu.Add("⭐ Umgangssprachlich", ReplaceShort)
    QuickReplaceMenu.Add()
    QuickReplaceMenu.Add("📝 GUI öffnen", OpenMainWindow)
    QuickReplaceMenu.Default := "📝 GUI öffnen"
}

; ========== HOTKEYS ==========
^!x:: {
    if (GuiIsOpen) {
        ShowToolTip("⚠️ GUI ist bereits geöffnet!")
        return
    }
    clipSaved := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(0.3) {
        A_Clipboard := clipSaved
        ShowToolTip("⚠️ Kein Text markiert!")
        return
    }
    A_Clipboard := clipSaved
    QuickReplaceMenu.Show()
}

^!c:: {
    if (GuiIsOpen) {
        if (MainGui)
            MainGui.Activate()
        return
    }
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(0.3) {
        inputText := ""
    } else {
        inputText := A_Clipboard
    }
    CreateMainGui(inputText)
}

; ========== HAUPTFENSTER ==========
CreateMainGui(inputText := "") {
    global
    GuiIsOpen := true
    MainGui := Gui("+Resize", "KI Text-Assistent")
    MainGui.SetFont("s9", "Segoe UI")
    MainGui.BackColor := "F5F5F5"
    MainGui.MarginX := 15
    MainGui.MarginY := 15
    MainGui.OnEvent("Close", MainGuiClose)
    
    MainGui.SetFont("s10 Bold")
    MainGui.Add("Text", "cNavy", "📝 Eingabetext")
    MainGui.SetFont("s9 Norm")
    
    cInputTextField := MainGui.Add("Edit", "w600 r3 BackgroundWhite", inputText)
    MainGui.Add("Button", "x+10 yp w130 h60", "🔄 Neu generieren").OnEvent("Click", RegenerateAll)
    
    MainGui.SetFont("s10 Bold")
    MainGui.Add("Text", "xm y+15 cNavy", "⚡ Schnellvorschau")
    MainGui.SetFont("s8 Norm")
    
    ; Freundlich
    MainGui.Add("GroupBox", "xm y+8 w240 h220")
    MainGui.Add("Text", "xp+8 yp+12 w224 Center", "😊 FREUNDLICH")
    cOutputFreundlich := MainGui.Add("Edit", "xp yp+22 w224 r8 ReadOnly BackgroundWhite")
    MainGui.Add("Button", "xp yp+140 w224 h28", "📋 Kopieren").OnEvent("Click", CopyFreundlich)
    
    ; Technisch
    MainGui.Add("GroupBox", "x+15 yp-174 w240 h220")
    MainGui.Add("Text", "xp+8 yp+12 w224 Center", "🔧 TECHNISCH")
    cOutputTechnisch := MainGui.Add("Edit", "xp yp+22 w224 r8 ReadOnly BackgroundWhite")
    MainGui.Add("Button", "xp yp+140 w224 h28", "📋 Kopieren").OnEvent("Click", CopyTechnisch)
    
    ; Umgangssprachlich
    MainGui.Add("GroupBox", "x+15 yp-174 w240 h220")
    MainGui.Add("Text", "xp+8 yp+12 w224 Center", "⭐ UMGANGSSPRACHLICH")
    cOutputUmgangssprachlich := MainGui.Add("Edit", "xp yp+22 w224 r8 ReadOnly BackgroundFFFFCC")
    MainGui.Add("Button", "xp yp+140 w224 h28", "📋 Kopieren").OnEvent("Click", CopyUmgangssprachlich)
    
    ; Individuell
    MainGui.SetFont("s10 Bold")
    MainGui.Add("Text", "xm y+18 cNavy", "🎨 Individuell")
    MainGui.SetFont("s8 Norm")
    
    MainGui.Add("Text", "xm y+8", "Anweisung:")
    cFreierStil := MainGui.Add("Edit", "w600 r2 BackgroundWhite")
    MainGui.Add("Button", "x+10 yp w130 h46", "🚀 Generieren").OnEvent("Click", SendFreiStil)
    
    cOutputFrei := MainGui.Add("Edit", "xm y+8 w750 r5 ReadOnly BackgroundWhite")
    
    MainGui.SetFont("s9")
    MainGui.Add("Button", "xm y+8 w150 h28", "📋 Kopieren").OnEvent("Click", CopyFrei)
    MainGui.Add("Button", "x+10 yp w150 h28", "⚙️ Optionen").OnEvent("Click", OpenOptionsWindow)
    MainGui.Add("Button", "x+10 yp w150 h28", "❌ Schließen").OnEvent("Click", MainGuiClose)
    
    PositionGuiOnMonitor(MainGui, PreferredMonitor)
    
    if (inputText != "") {
        cOutputFreundlich.Value := "⏳ Lädt..."
        cOutputTechnisch.Value := "⏳ Lädt..."
        cOutputUmgangssprachlich.Value := "⏳ Lädt..."
        SetTimer(StartAllRequestsAsync, -100)
    }
}

OpenMainWindow(*) {
    if (GuiIsOpen) {
        MainGui.Activate()
        return
    }
    tempClip := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(0.5)
        inputText := ""
    else
        inputText := A_Clipboard
    A_Clipboard := tempClip
    CreateMainGui(inputText)
}

; ========== OPTIONEN FENSTER (NEU: API FIELDS) ==========
OpenOptionsWindow(*) {
    global OptionsGui, OptionsGuiOpen
    global cOptApiUrl, cOptModel, cOptApiKey, cOptMonitor, cOptRememberPosition
    global cOptPromptFreundlich, cOptTempFreundlich
    global cOptPromptTechnisch, cOptTempTechnisch
    global cOptPromptUmgangssprachlich, cOptTempUmgangssprachlich
    
    if (OptionsGuiOpen) {
        OptionsGui.Activate()
        return
    }
    
    OptionsGuiOpen := true
    GetMonitorInfo()
    
    OptionsGui := Gui(, "Einstellungen")
    OptionsGui.SetFont("s9", "Segoe UI")
    OptionsGui.BackColor := "F5F5F5"
    OptionsGui.MarginX := 15
    OptionsGui.MarginY := 15
    OptionsGui.OnEvent("Close", OptionsGuiClose)
    
    ; --- API CONFIG SECTION ---
    OptionsGui.SetFont("s10 Bold")
    OptionsGui.Add("Text", "cNavy", "🔌 API Konfiguration")
    OptionsGui.SetFont("s9 Norm")
    
    OptionsGui.Add("Text", "xm y+10 w120", "Endpunkt URL:")
    cOptApiUrl := OptionsGui.Add("Edit", "x+5 yp-3 w570 r1", G_API_URL)
    
    OptionsGui.Add("Text", "xm y+10 w120", "Model ID:")
    cOptModel := OptionsGui.Add("Edit", "x+5 yp-3 w570 r1", G_MODEL)
    
    OptionsGui.Add("Text", "xm y+10 w120", "API Key:")
    cOptApiKey := OptionsGui.Add("Edit", "x+5 yp-3 w570 r1 Password", G_API_KEY)
    
    ; --- GUI EINSTELLUNGEN ---
    OptionsGui.SetFont("s10 Bold")
    OptionsGui.Add("Text", "xm y+20 cNavy", "🖥️ Darstellung")
    OptionsGui.SetFont("s9 Norm")
    
    OptionsGui.Add("Text", "xm y+10", "GUI-Anzeige auf Monitor:")
    cOptMonitor := OptionsGui.Add("DropDownList", "xm y+5 w300", MonitorListString)
    try cOptMonitor.Choose(PreferredMonitor) 
    catch
        cOptMonitor.Choose(1)
    
    OptionsGui.Add("Checkbox", "xm y+10 vRememberPos", "Letzte Position beim Öffnen wiederherstellen")
    cOptRememberPosition := OptionsGui["RememberPos"]
    cOptRememberPosition.Value := RememberPosition
    
    ; --- PROMPT EINSTELLUNGEN ---
    OptionsGui.SetFont("s10 Bold")
    OptionsGui.Add("Text", "xm y+20 cNavy", "📝 Prompts & Temperaturen")
    OptionsGui.SetFont("s9 Norm")
    
    tempList := ["0.1","0.3","0.5","0.7","0.9","1.0","1.2","1.5","1.8","2.0"]
    
    ; Freundlich
    OptionsGui.Add("Text", "xm y+10", "😊 Freundlich:")
    cOptPromptFreundlich := OptionsGui.Add("Edit", "xm y+5 w700 r3", PromptFreundlich)
    OptionsGui.Add("Text", "xm y+5", "🌡️ Temperatur:")
    cOptTempFreundlich := OptionsGui.Add("DropDownList", "xm y+5 w100", tempList)
    cOptTempFreundlich.Text := Format("{:.1f}", TempFreundlich)
    
    ; Technisch
    OptionsGui.Add("Text", "xm y+15", "🔧 Technisch:")
    cOptPromptTechnisch := OptionsGui.Add("Edit", "xm y+5 w700 r3", PromptTechnisch)
    OptionsGui.Add("Text", "xm y+5", "🌡️ Temperatur:")
    cOptTempTechnisch := OptionsGui.Add("DropDownList", "xm y+5 w100", tempList)
    cOptTempTechnisch.Text := Format("{:.1f}", TempTechnisch)
    
    ; Umgangssprachlich
    OptionsGui.Add("Text", "xm y+15", "⭐ Umgangssprachlich:")
    cOptPromptUmgangssprachlich := OptionsGui.Add("Edit", "xm y+5 w700 r3", PromptUmgangssprachlich)
    OptionsGui.Add("Text", "xm y+5", "🌡️ Temperatur:")
    cOptTempUmgangssprachlich := OptionsGui.Add("DropDownList", "xm y+5 w100", tempList)
    cOptTempUmgangssprachlich.Text := Format("{:.1f}", TempUmgangssprachlich)
    
    ; Footer Buttons
    OptionsGui.Add("Button", "xm y+20 w200 h35", "💾 Speichern").OnEvent("Click", SavePromptsFromGui)
    OptionsGui.Add("Button", "x+10 yp w200 h35", "🔄 Zurücksetzen").OnEvent("Click", ResetPromptsToDefault)
    OptionsGui.Add("Button", "x+10 yp w200 h35", "❌ Schließen").OnEvent("Click", OptionsGuiClose)
    
    OptionsGui.Show("AutoSize Center")
}

; ========== SPEICHERN (ERWEITERT) ==========
SavePromptsFromGui(*) {
    global OptionsGuiOpen
    
    monitorSelection := cOptMonitor.Text
    if RegExMatch(monitorSelection, "Monitor (\d+)", &mon)
        selectedMonitor := Integer(mon[1])
    else
        selectedMonitor := 1
        
    SavePrompts(
        cOptApiUrl.Value,     ; NEU
        cOptModel.Value,      ; NEU
        cOptApiKey.Value,     ; NEU
        cOptPromptFreundlich.Value,
        cOptPromptTechnisch.Value,
        cOptPromptUmgangssprachlich.Value,
        cOptTempFreundlich.Text,
        cOptTempTechnisch.Text,
        cOptTempUmgangssprachlich.Text,
        selectedMonitor,
        cOptRememberPosition.Value
    )
    
    ShowToolTip("✅ Einstellungen gespeichert!")
    OptionsGuiOpen := false
    OptionsGui.Destroy()
}

; ========== RESET (ERWEITERT) ==========
ResetPromptsToDefault(*) {
    SavePrompts(DEFAULT_API_URL, DEFAULT_MODEL, DEFAULT_API_KEY, DEFAULT_PROMPT_FREUNDLICH, DEFAULT_PROMPT_TECHNISCH, DEFAULT_PROMPT_UMGANGSSPRACHLICH, DEFAULT_TEMP_FREUNDLICH, DEFAULT_TEMP_TECHNISCH, DEFAULT_TEMP_UMGANGSSPRACHLICH, 1, 1)
    
    cOptApiUrl.Value := DEFAULT_API_URL
    cOptModel.Value  := DEFAULT_MODEL
    cOptApiKey.Value := DEFAULT_API_KEY
    cOptPromptFreundlich.Value := DEFAULT_PROMPT_FREUNDLICH
    cOptPromptTechnisch.Value := DEFAULT_PROMPT_TECHNISCH
    cOptPromptUmgangssprachlich.Value := DEFAULT_PROMPT_UMGANGSSPRACHLICH
    cOptTempFreundlich.Text := DEFAULT_TEMP_FREUNDLICH
    cOptTempTechnisch.Text := DEFAULT_TEMP_TECHNISCH
    cOptTempUmgangssprachlich.Text := DEFAULT_TEMP_UMGANGSSPRACHLICH
    cOptMonitor.Choose(1)
    cOptRememberPosition.Value := 1
    
    ShowToolTip("✅ Einstellungen auf Standard zurückgesetzt!")
}

; ========== LOGIC ==========
RegenerateAll(*) {
    inputText := cInputTextField.Value
    if (inputText == "") {
        MsgBox("Bitte Text eingeben.", "Hinweis", 48)
        return
    }
    cOutputFreundlich.Value := "⏳ Lädt..."
    cOutputTechnisch.Value := "⏳ Lädt..."
    cOutputUmgangssprachlich.Value := "⏳ Lädt..."
    
    SendRequestAsync("Freundlich", PromptFreundlich, inputText, TempFreundlich)
    SendRequestAsync("Technisch", PromptTechnisch, inputText, TempTechnisch)
    SendRequestAsync("Umgangssprachlich", PromptUmgangssprachlich, inputText, TempUmgangssprachlich)
}

StartAllRequestsAsync() {
    inputText := cInputTextField.Value
    SendRequestAsync("Freundlich", PromptFreundlich, inputText, TempFreundlich)
    SendRequestAsync("Technisch", PromptTechnisch, inputText, TempTechnisch)
    SendRequestAsync("Umgangssprachlich", PromptUmgangssprachlich, inputText, TempUmgangssprachlich)
}

SendFreiStil(*) {
    freiStil := cFreierStil.Value
    inputText := cInputTextField.Value
    if (freiStil == "" || inputText == "") {
        MsgBox("Bitte Stil und Text eingeben.", "Hinweis", 48)
        return
    }
    cOutputFrei.Value := "⏳ Lädt..."
    SendRequestAsync("Frei", freiStil, inputText, 0.7)
}

SanitizeForJson(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`t", "\t")
    return str
}

GetAssistantContent(jsonStr) {
    if RegExMatch(jsonStr, 's)"choices".*?"content"\s*:\s*"((?:[^"\\]|\\.)*)"', &match) {
        content := match[1]
        content := StrReplace(content, '\\', '\') 
        content := StrReplace(content, '\"', '"')
        content := StrReplace(content, '\/', '/')
        content := StrReplace(content, '\n', "`n")
        content := StrReplace(content, '\r', "`r")
        content := StrReplace(content, '\t', "`t")
        while RegExMatch(content, "i)\\u([0-9a-f]{4})", &uMatch) {
            hexVal := "0x" . uMatch[1]
            char := Chr(Integer(hexVal))
            content := StrReplace(content, uMatch[0], char)
        }
        return content
    }
    return ""
}

; ========== ASYNC REQUEST (Verwendet nun G_API_URL/G_MODEL) ==========
SendRequestAsync(styleType, tone, inputText, temperature) {
    global AsyncRequests, PendingCount
    
    prompt := tone . "`n`nText:`n" . inputText
    prompt := SanitizeForJson(prompt)
    
    ; Verwendung der dynamischen Variablen G_MODEL
    body := '{"model":"' . G_MODEL . '"'
          . ',"messages":[{"role":"user","content":"' . prompt . '"}]'
          . ',"temperature":' . temperature
          . '}'
    
    try {
        req := ComObject("Msxml2.XMLHTTP")
        ; Verwendung der dynamischen URL G_API_URL
        req.Open("POST", G_API_URL, true)
        req.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        req.SetRequestHeader("Authorization", "Bearer " . G_API_KEY)
        req.onreadystatechange := OnRequestComplete.Bind(styleType, req)
        
        AsyncRequests[styleType] := req
        PendingCount++
        req.Send(body)
    } catch as e {
        SetOutput(styleType, "⚠️ Fehler: " . e.Message)
    }
}

OnRequestComplete(styleType, req) {
    global AsyncRequests, PendingCount
    if (req.readyState != 4)
        return
    PendingCount--
    
    if (req.status == 200) {
        content := GetAssistantContent(req.responseText)
        if (content != "") {
            SetOutput(styleType, content)
            if (styleType == "Umgangssprachlich") {
                A_Clipboard := content
                ShowToolTip('✅ "Umgangssprachlich" automatisch kopiert!')
            }
        } else {
            SetOutput(styleType, "⚠️ Leere Antwort")
        }
    } else {
        SetOutput(styleType, "⚠️ HTTP " . req.status)
    }
    if AsyncRequests.Has(styleType)
        AsyncRequests.Delete(styleType)
}

SetOutput(styleType, text) {
    global
    if (styleType == "Freundlich")
        cOutputFreundlich.Value := text
    else if (styleType == "Technisch")
        cOutputTechnisch.Value := text
    else if (styleType == "Umgangssprachlich")
        cOutputUmgangssprachlich.Value := text
    else if (styleType == "Frei")
        cOutputFrei.Value := text
}

; ========== SWAP LOGIC (Verwendet nun G_API_URL/G_MODEL) ==========
ReplaceFriendly(*) {
    QuickSwapWithGPT(PromptFreundlich, TempFreundlich)
}
ReplaceTechnical(*) {
    QuickSwapWithGPT(PromptTechnisch, TempTechnisch)
}
ReplaceShort(*) {
    QuickSwapWithGPT(PromptUmgangssprachlich, TempUmgangssprachlich)
}

QuickSwapWithGPT(tone, temperature) {
    clipSaved := ClipboardAll()
    A_Clipboard := ""
    Send("^x")
    if !ClipWait(1) {
        ShowToolTip("⚠️ Keine Auswahl.")
        A_Clipboard := clipSaved
        return
    }
    original := A_Clipboard
    prompt := tone . "`n`nText:`n" . original
    res := CallOpenAISync(prompt, temperature)
    
    if (!res.ok || res.content == "") {
        A_Clipboard := original
        Send("^v")
        Sleep(80)
        A_Clipboard := clipSaved
        ShowToolTip("⚠️ Fehler HTTP " . res.status)
        return
    }
    A_Clipboard := res.content
    Send("^v")
    Sleep(120)
    A_Clipboard := original
    Sleep(80)
    A_Clipboard := clipSaved
    ShowToolTip("✅ Ersetzt!")
}

CallOpenAISync(prompt, temperature) {
    prompt := SanitizeForJson(prompt)
    body := '{"model":"' . G_MODEL . '"'
          . ',"messages":[{"role":"user","content":"' . prompt . '"}]'
          . ',"temperature":' . temperature
          . '}'
    
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", G_API_URL, false)
        http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
        http.SetRequestHeader("Authorization", "Bearer " . G_API_KEY)
        http.Send(body)
        
        if (http.Status != 200)
            return {ok: false, status: http.Status, content: ""}
            
        stream := ComObject("ADODB.Stream")
        stream.Type := 1
        stream.Open()
        stream.Write(http.ResponseBody)
        stream.Position := 0
        stream.Type := 2
        stream.Charset := "UTF-8"
        response := stream.ReadText()
        stream.Close()
        
        content := GetAssistantContent(response)
        if (content == "")
            return {ok: false, status: http.Status, content: ""}
        return {ok: true, status: http.Status, content: content}
    } catch {
        return {ok: false, status: 0, content: ""}
    }
}

; ========== COPY HELPER ==========
CopyFreundlich(*) {
    CopyTextFromControl(cOutputFreundlich, "Freundlich")
}
CopyTechnisch(*) {
    CopyTextFromControl(cOutputTechnisch, "Technisch")
}
CopyUmgangssprachlich(*) {
    CopyTextFromControl(cOutputUmgangssprachlich, "Umgangssprachlich")
}
CopyFrei(*) {
    CopyTextFromControl(cOutputFrei, "Frei")
}

CopyTextFromControl(ctrl, name) {
    val := ctrl.Value
    if (val == "" || InStr(val, "⏳") || InStr(val, "⚠️")) {
        MsgBox("Kein Inhalt.", "Hinweis", 48)
        return
    }
    A_Clipboard := val
    ShowToolTip("✅ " . name . " kopiert!")
}

MainGuiClose(*) {
    global GuiIsOpen, MainGui
    SaveGuiPosition(MainGui)
    GuiIsOpen := false
    MainGui.Destroy()
    MainGui := ""
}

OptionsGuiClose(*) {
    global OptionsGuiOpen, OptionsGui
    OptionsGuiOpen := false
    OptionsGui.Destroy()
    OptionsGui := ""
}

CloseApp(*) {
    ExitApp
}

ShowToolTip(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2000)
}