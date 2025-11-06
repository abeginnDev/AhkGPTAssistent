# 🤖 AI Text Assistant

An AutoHotkey tool for quick text correction and optimization using OpenAI GPT-4.


## ✨ Features

- **3 Preset Styles**: Friendly, Technical, Conversational
- **Quick Replace**: Replace selected text directly (Ctrl+Alt+X)
- **Custom Prompts**: Define your own instructions
- **Multi-Monitor Support**: Save window position and choose preferred monitor
- **Asynchronous Processing**: Generate all three styles in parallel
- **Clipboard Integration**: Automatic copying of conversational text

## 🚀 Installation

1. **Install AutoHotkey**: [Download](https://www.autohotkey.com/download/)
2. **Download Script**: `KI-Text-Assistent.ahk`
3. **Run**: Double-click the `.ahk` file

## 🔑 Creating OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com/api-keys)
2. Sign in or register
3. Click **"Create new secret key"**
4. Copy the key (starts with `sk-...`)
5. In the script: Right-click tray icon → **"Options"** → Paste API key

> ⚠️ **Important**: The key is stored locally in `prompts.ini`. Never share publicly!

## ⌨️ Hotkeys

| Hotkey | Function |
|--------|----------|
| `Ctrl+Alt+C` | Open GUI with selected text |
| `Ctrl+Alt+X` | Quick replace menu (replace text directly) |

## 📖 Usage

### Quick Replace (fastest method)
1. Select text
2. Press `Ctrl+Alt+X`
3. Choose style (Friendly/Technical/Conversational)
4. Text gets replaced automatically

<img width="372" height="116" alt="2025-11-04 18_11_25-_How are you – Notepad" src="https://github.com/user-attachments/assets/0c4e98e2-62d4-4d90-98bc-36c2696b65e7" />

### GUI Mode
1. Select text
2. Press `Ctrl+Alt+C`
3. All three styles are generated in parallel
4. Copy result or use individual prompt

<img width="391" height="321" alt="2025-11-04 18_14_35-_Main_GUI" src="https://github.com/user-attachments/assets/370adfd3-aa7f-4dd0-b464-e55351b3c217" />


### Tray Icon
Right-click the taskbar icon:
- **Open Window**: GUI with current clipboard text
- **Options**: Adjust API key, prompts and monitor settings
- **Quick Replace**: Direct access to style selection

## ⚙️ Configuration

All settings are saved in `prompts.ini`:

```ini
[Config]
APIKey=sk-...
PreferredMonitor=1
RememberPosition=1

[Prompts]
Freundlich=Correct the text in a friendly way...
Technisch=Correct the text technically...
Umgangssprachlich=Summarize the text conversationally...

[Temperatures]
Freundlich=0.7
Technisch=0.5
Umgangssprachlich=0.7
```

### Adjusting Settings
1. Right-click tray icon → **"Options"**
2. Edit API key, prompts and temperatures
3. Configure monitor preference and window position saving
4. Click **"Save"**
<img width="368" height="379" alt="2025-11-04 18_14_56-Einstellungen" src="https://github.com/user-attachments/assets/c1f0c59c-003d-46b5-b18f-f1771eb3eff2" />

## 🖥️ Multi-Monitor Support

- **Preferred Monitor**: Choose which monitor the window should appear on
- **Remember Position**: Enable this option to restore the last window position
- Automatic validation when monitors change (e.g., undocking laptop)

## 🔧 Technical Details

- **Model**: GPT-4o-mini (configurable in code)
- **Asynchronous**: Parallel API requests for faster results
- **Local Storage**: No cloud sync, all data stays local
- **UTF-8 Support**: Full Unicode support

## 📝 Files

```
KI-Text-Assistent.ahk    # Main script
prompts.ini              # Configuration (created automatically)
```

## 💡 Tips

- **Temperature**: Lower values (0.3-0.5) = more consistent, higher values (0.7-1.0) = more creative
- **Customize Prompts**: Experiment with different instructions for better results
- **Clipboard History**: After quick replace, original text remains briefly in clipboard history

## 🐛 Troubleshooting

**"⚠️ No response (HTTP 401)"**
→ Invalid API key. Create new key and paste in options.

**"⚠️ No response (HTTP 429)"**
→ Rate limit reached. Wait briefly or upgrade API plan.

**Window doesn't appear**
→ Reset monitor configuration: Delete `prompts.ini` and restart script.

**Text doesn't get replaced**
→ Make sure text is selected before pressing `Ctrl+Alt+X`.

## 📄 License

This project is Open Source. Free to use and modify.

## 🤝 Contributing

Issues and Pull Requests are welcome!

---

**Built with ❤️ and AutoHotkey**
