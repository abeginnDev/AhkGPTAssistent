# 🤖 AI Text Assistant (AHK v1 & v2)

An AutoHotkey tool for quick text correction, optimization, and generation using OpenAI GPT-4 (or compatible APIs).

> **Now updated with AutoHotkey v2 support!** Choose the version that matches your installation.

## ✨ Features

| Feature | v1 (Legacy) | v2 (Recommended) |
| :--- | :---: | :---: |
| **Engine** | AutoHotkey v1.1 | **AutoHotkey v2.0+** |
| **Styles** | 3 Presets (Friendly, Tech, Chat) | 3 Presets + **Free Style** |
| **API Config** | OpenAI Only | **Custom URL & Model ID** |
| **Local LLM** | No | **Yes (Ollama/LM Studio support)** |
| **Async Gen** | Yes | **Yes (Optimized)** |

### Core Functionality
- **Quick Replace**: Replace selected text directly in any app (`Ctrl+Alt+X`)
- **Parallel Processing**: Generate Friendly, Technical, and Conversational styles simultaneously.
- **Custom Prompts**: Fully customizable instructions via GUI.
- **Multi-Monitor Support**: Smart window positioning and monitor selection.
- **Clipboard History**: Safely restores clipboard after text replacement.

## 📂 Folder Structure

This repository contains two versions of the script:

- **`/v1/`**: For users running legacy AutoHotkey v1.1.
- **`/v2/`**: For users running modern AutoHotkey v2.0 (Includes generic API support).

## 🚀 Installation

### Option A: AutoHotkey v2 (New & Better)
1. **Install AutoHotkey v2**: [Download v2.0](https://www.autohotkey.com/)
2. Navigate to the `v2` folder in this repo.
3. Run `KI-Text-Assistent.ahk` (Double-click).

### Option B: AutoHotkey v1 (Legacy)
1. **Install AutoHotkey v1.1**: [Download v1.1](https://www.autohotkey.com/download/1.1/)
2. Navigate to the `v1` folder.
3. Run `KI-Text-Assistent.ahk`.

## 🔑 Configuration & API Key

### 1. Get an API Key
You can use OpenAI or any local/compatible provider.
1. **OpenAI**: Go to [platform.openai.com](https://platform.openai.com/api-keys) -> Create new secret key.
2. **Local LLM**: Start your server (e.g., LM Studio/Ollama) and get your local URL (usually `http://localhost:1234/v1/chat/completions`).

### 2. Setup in Script
1. Right-click the tray icon 🤖 in your taskbar.
2. Select **"Options" (Einstellungen)**.
3. Enter your details:
   - **API Endpoint**: Default is `https://api.openai.com/v1/chat/completions` (Change this for Local LLMs).
   - **Model ID**: Default is `gpt-4o-mini` (Change to `gpt-4`, `llama-3`, etc.).
   - **API Key**: Paste your `sk-...` key.

> ⚠️ **Security**: The key is stored locally in `prompts.ini`. Never share this file!

## ⌨️ Hotkeys

| Hotkey | Function |
|--------|----------|
| `Ctrl+Alt+C` | **Open GUI**: Opens the main window with the selected text copied. |
| `Ctrl+Alt+X` | **Quick Replace**: Opens a small menu to replace text instantly. |

## 📖 Usage

### GUI Mode (`Ctrl+Alt+C`)
Best for comparing different tones or writing custom instructions.
1. Select text -> Press Hotkey.
2. Wait for parallel generation.
3. **v2 Only**: Use the "Individuell" field to type a custom instruction (e.g., "Translate to Spanish") and click "Generieren".

<img width="391" height="321" alt="Main GUI Interface" src="https://github.com/user-attachments/assets/370adfd3-aa7f-4dd0-b464-e55351b3c217" />

### Quick Replace (`Ctrl+Alt+X`)
Best for fast corrections while typing emails or tickets.
1. Select text -> Press Hotkey.
2. Select style from menu.
3. Text is replaced automatically.

<img width="372" height="116" alt="Quick Replace Menu" src="https://github.com/user-attachments/assets/0c4e98e2-62d4-4d90-98bc-36c2696b65e7" />

## ⚙️ Advanced Configuration (ini)

Settings are saved in `prompts.ini` next to the script. 

**v2 Example `prompts.ini`:**
```ini
[Config]
APIUrl=[https://api.openai.com/v1/chat/completions](https://api.openai.com/v1/chat/completions)
Model=gpt-4o-mini
APIKey=sk-your-key-here
PreferredMonitor=1
RememberPosition=1

[Prompts]
Freundlich=Correct the text in a friendly way...
Technisch=Correct the text technically...
...
