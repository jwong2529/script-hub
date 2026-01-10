# Script Hub

<img src="script-hub/Assets.xcassets/AppIcon.appiconset/icon-mac-512x512.png" alt="App Icon" width="50">

A native macOS application that wraps interactive Python (CLI) scripts into an Apple-style "Command Center."

It allows you to run scripts in a clean GUI without needing to open the Terminal.

## Features

* **Universal Wrapper:** Runs *any* interactive Python script that uses standard `input()` and `print()`.
* **Sidebar Profiles:** Switch between different tools (Notion, GCal, ToDo) instantly.
* **ANSI Color Support:** Translates terminal color codes (Red, Green, Blue, Dim) into native SwiftUI colors.
* **Interactive Input:** Type commands just like in a terminal.
* **Other:** 
    - Favorite/pin tools.
    - Supports (Stop) signal handling via button or `Cmd + .`.
    - Configure Python paths and script locations via the UI.
    - Adjust font sizing.
    - Use keyboard shortcuts.

---

## Prerequisites

**Python Environment:** Your scripts should already be working in a standard Terminal environment (e.g., inside a virtual environment).

---

## Setup Instructions

1.  Click the **+ (Plus)** button in the top toolbar.
2.  **Name:** Give your tool a name (e.g., "Notion Manager").
3.  **Python Path:**
    * Open your Terminal.
    * Activate your virtual environment: `source venv/bin/activate`
    * Run: `which python`
    * Copy that path (e.g., `/Users/yourname/project/venv/bin/python3`) and paste it into the app.
4.  **Script Path:** Browse and select your `.py` script file.
5.  Click **Add Tool**.

---

## Script Compatibility
Your Python scripts generally do not need modification, but for the best experience:

* **Colors:** The app supports standard ANSI colors (e.g., `\033[92m` for green).
* **Input:** Use standard `input("Prompt: ")`.
* **Output:** The app automatically handles `print()` flushing..

---
