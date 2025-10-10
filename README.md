# 🤖 AHK_Ki_Assistent_GPT: AI Text Assistant (AutoHotkey, async)

A lightweight **AutoHotkey v1** tool that rewrites selected text via parallel, non-blocking API calls and shows instant previews in three predefined styles: **Friendly**, **Technical**, and **Short**. It also includes a fully customizable prompt field. Designed for speed, minimal clicks, and seamless clipboard handling.

---

## ✨ Features

* **Parallel Requests:** Three asynchronous calls render independently without freezing the UI.
* **Quick Preview GUI:** Read-only panels for Friendly, Technical, and Short outputs with one-click copy, plus a custom "**Free Style**" generator.
* **Editor-friendly Swaps:** Dedicated hotkeys replace selected text in place and safely restore the original clipboard content.

---

## ⌨️ Hotkeys and Tray

| Hotkey | Action | Description |
| :--- | :--- | :--- |
| $\text{Ctrl}+\text{Alt}+\text{X}$ | Quick Style Menu | Shows a small menu for in-place replacement using the predefined styles when text is selected. |
| $\text{Ctrl}+\text{Alt}+\text{C}$ | Open Main Window | Captures the selection, opens the main window, and auto-runs the parallel previews. |
| Tray Menu | Window/Actions/Exit | Offers options to open the main window, quick replace actions, and exit the script. |

---

## 🛠️ Implementation Details

* **True Async:** Achieved via **COM HTTP** with `onreadystatechange` for robust status and error handling.
* **Sync Fallback:** Utilizes **WinHttp** for instant, reliable swap operations.
* **Response Handling:** Includes minimal JSON sanitization and reliable response parsing.

---

## 📥 Requirements

* **Windows** with **AutoHotkey v1.x** installed.
* **MSXML2** available (standard on most Windows installations).
* A valid API access and a chat-capable model (default: **$\text{gpt}-4\text{o}-\text{mini}$**).

---

## 🚀 Setup

1.  **Save** the script locally.
2.  **Set an environment variable** `OPENAI_API_KEY` (recommended) or use a local encrypted secret for your API key.
3.  **Start** the script and use the tray icon or the hotkeys on selected text to begin.

---

## 🔒 Security Best Practices

* **Do not hardcode API keys.** Keep secrets out of source control and logs.
* Add backoff for rate limits and handle **429/5xx** HTTP status codes gracefully.

---

## 🎯 Use Cases

* **Tone Shifting:** Quickly change the tone (e.g., friendly to technical) for emails, support tickets, and documentation.
* **Summarization:** Generate one-line summaries for commit messages, status updates, and notes.
