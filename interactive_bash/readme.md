# Master Bash Scripting Tutorial - User Guide

This will help to learn bash script form beginner to advanced in an interactive way. Just clone this repository. Add execute permission and run it. Please share your suggestions and also notify me incase any errors found.
This script will work perfectly in both windows (gitbash, wsl, virtual machine running linux) and Linux. This script is tested in windows 11 gitbash and Ubuntu 24.04 LTS. 

This guide explains how to install, run, and navigate the [bash_script_enhanced.sh](file:///c:/devops/learn-bash/bash_script_enhanced.sh) interactive tutorial.

## 1. Getting Started

### 🐧 Linux / macOS
Before running the script for the first time, you must give it execution permissions.

1.  **Make Executable**:
    ```bash
    chmod +x bash_script_enhanced.sh
    ```
2.  **Run the Script**:
    ```bash
    ./bash_script_enhanced.sh
    ```

### 🪟 Windows (Git Bash)
1.  Open **Git Bash**.
2.  Navigate to the folder containing the script.
3.  **Run the Script**:
    ```bash
    ./bash_script_enhanced.sh
    ```

---

## 2. Navigation Features

The script is designed to be fully interactive. You are in control of the pace.

### 📑 Table of Contents (TOC)
At launch, you will see a numbered list of all 20 topics (e.g., "1. BASIC COMMANDS", "14. ERROR HANDLING"). You can reference these numbers for navigation.

### 🎮 Controls
At any **"Press Enter to continue..."** prompt, you have four options:

| Input | Action |
| :--- | :--- |
| **ENTER** | **Next Step**: Run the next example or proceed to the next section. |
| **Number** | **Jump**: Type a topic number (e.g., `14`) and press Enter to skip directly to that section. |
| **'q'** | **Skip Section**: Instantly skip the rest of the *current* section and move to the next one. |
| **'Q'** | **Quit**: Exit the tutorial immediately. |

---

## 3. Key Features

### ✅ Cross-Platform Compatibility
- optimization for both **Linux** and **Windows (Git Bash)**.
- Automatically handles differences in commands (e.g., `groups` vs `id -Gn`).
- **Auto-Fix**: Converted to Unix-style line endings (LF) to prevent "command not found" errors on Linux.

### 🧹 Automatic Cleanup
- The script creates sample files/folders (e.g., `demo_dir`, `task_XXXX`) to demonstrate commands.
- **Self-Cleaning**: When you exit (via 'Q' or finishing), it **automatically deletes** all these temporary files, keeping your workspace clean.

### 🚀 Advanced Demos
- **Bandit Level 0-33**: Includes a guide for the OverTheWire Bandit wargame.
- **Automation**: Simulates a real-world task (log rotation & archiving).
- **Network & System**: Shows how to inspect open ports, disk usage, and processes.

---

## 4. Troubleshooting

- **"Permission denied"**: Run `chmod +x bash_script_enhanced.sh`.
- **"Syntax error: unexpected end of file"**: Ensure you have the latest version (fixed a specific bug with curly braces `}`).
- **"No such file or directory"**: detailed error usually means Windows line endings (`\r`) got in. We ran a fix for this, but if it reappears, run `sed -i 's/\r$//' bash_script_enhanced.sh` on Linux.
