# 🎵 Termux YouTube Music Player

A **lightweight, terminal-based YouTube music player** built on top of `mpv`, designed for **Termux** but usable on **any Linux environment**.

It focuses on **low memory usage**, **keyboard-friendly controls**, **notification-based media control**, and **voice commands**.

---

## ✨ Why This Is Great

* ▶️ Play YouTube music **directly from the terminal**
* 🧠 Beginner-friendly commands: `play`, `pause`, `stop`, `fw10`, `bk30`, etc.
* 🎤 Optional **voice commands** for hands-free control
* 🔔 Android **notification & lock-screen controls**
* 🔋 Very low memory & battery usage (no browser needed)
* 🧑‍💻 Perfect for developers who don’t want Spotify/YouTube running in a browser
* 🚗 Useful while travelling (lock-screen + notification controls)

---

## 🧩 Features at a Glance

* Terminal-based music playback
* YouTube playlist support
* Resume last playlist automatically
* Forward / backward seek (any seconds)
* Notification media buttons (Prev / Play-Pause / Next)
* Swipe notification to **STOP**
* Voice control (optional)
* Background & lock-screen safe

---

## 1️⃣ Dependencies

Install required packages in **Termux**:

```bash
pkg update
pkg install mpv yt-dlp socat termux-api
```

### What each dependency does

| Package      | Purpose                         |
| ------------ | ------------------------------- |
| `mpv`        | Media player                    |
| `yt-dlp`     | Extracts YouTube audio streams  |
| `socat`      | Sends IPC commands to mpv       |
| `termux-api` | Wake-lock & Android integration |

> ⚠️ **Important**
> Install the **Termux:API app** from **F-Droid (recommended)** or Play Store.
> The package alone is not enough.

---

## 2️⃣ Enable Termux Storage Access

```bash
termux-setup-storage
```

Restart Termux after granting permission.

---

## 3️⃣ One-Time `.bashrc` Setup

Edit your bash configuration:

```bash
nano ~/.bashrc
```

Add the following block **at the bottom** (keep existing content):

```bash
alias mpv="mpv --player-operation-mode=pseudo-gui"

##### MPV YouTube Music Controller (Termux) #####

export MPV_SOCKET="$PREFIX/tmp/mpv-socket"
export MPV_STATE_FILE="$HOME/.mpv_last_playlist"

# Internal helper
_mpv_cmd() {
    if [ ! -S "$MPV_SOCKET" ]; then
        echo "mpv is not running."
        return 1
    fi
    echo "{ \"command\": $1 }" | socat - "$MPV_SOCKET" >/dev/null
}

# Start YouTube music (auto resume supported)
ytmusic() {
    termux-wake-lock 2>/dev/null

    if [ -f "$MPV_STATE_FILE" ]; then
        read -p "Resume last playlist? (y/n): " ans
        if [ "$ans" = "y" ]; then
            url=$(cat "$MPV_STATE_FILE")
        else
            read -p "Enter YouTube playlist URL: " url
        fi
    else
        read -p "Enter YouTube playlist URL: " url
    fi

    if [ -z "$url" ]; then
        echo "No URL entered."
        return 1
    fi

    echo "$url" > "$MPV_STATE_FILE"

    [ -e "$MPV_SOCKET" ] && rm -f "$MPV_SOCKET"

    mpv --no-video \
        --save-position-on-quit \
        --input-ipc-server="$MPV_SOCKET" \
        "$url" &

    ~/ytmusic-notify.sh
}

# Playback
play()    { _mpv_cmd '["set_property", "pause", false]'; }
pause()   { _mpv_cmd '["set_property", "pause", true]'; }
toggle()  { _mpv_cmd '["cycle", "pause"]'; }

next()    { _mpv_cmd '["playlist-next"]'; }
prev()    { _mpv_cmd '["playlist-prev"]'; }

stop() {
    _mpv_cmd '["quit"]'
    termux-wake-unlock 2>/dev/null
}

# Volume control
volup()   { _mpv_cmd '["add", "volume", 5]'; }
voldown() { _mpv_cmd '["add", "volume", -5]'; }

# Shuffle playlist
shuffle() { _mpv_cmd '["playlist-shuffle"]'; }

# Current song status
status() {
    if [ ! -S "$MPV_SOCKET" ]; then
        echo "mpv is not running."
        return 1
    fi
    echo '{ "command": ["get_property", "media-title"] }' \
        | socat - "$MPV_SOCKET" \
        | sed -n 's/.*"data":"\(.*\)".*/Now Playing: \1/p'
}

# Seek controls (n seconds)
command_not_found_handle() {
    if [[ "$1" =~ ^fw([0-9]+)$ ]]; then
        _mpv_cmd "[\"seek\", ${BASH_REMATCH[1]}]"
        return 0
    fi
    if [[ "$1" =~ ^bk([0-9]+)$ ]]; then
        _mpv_cmd "[\"seek\", -${BASH_REMATCH[1]}]"
        return 0
    fi
    return 127
}

##### End MPV YouTube Music Controller #####

alias ytvoice="$HOME/ytmusic-voice.sh"
```

Save and exit:

* `CTRL + O` → Enter
* `CTRL + X`

Reload config:

```bash
source ~/.bashrc
```

---

## 🎵 Usage

### ▶️ Start Music

```bash
ytmusic
```

* Prompts for playlist URL
* Automatically resumes last playlist

---

### 🎮 Terminal Controls

| Command   | Action              |
| --------- | ------------------- |
| `play`    | Play                |
| `pause`   | Pause               |
| `toggle`  | Play / Pause        |
| `next`    | Next track          |
| `prev`    | Previous track      |
| `stop`    | Stop playback       |
| `volup`   | Volume +5           |
| `voldown` | Volume −5           |
| `shuffle` | Shuffle playlist    |
| `status`  | Show current song   |
| `fw10`    | Forward 10 seconds  |
| `bk30`    | Backward 30 seconds |

---

## 🔔 Notification & Lock-Screen Controls

* ⏮ Previous
* ⏯ Play / Pause (single smart toggle)
* ⏭ Next
* ⬜ **Swipe notification to STOP**

Music continues when:

* Screen is off
* App is backgrounded

---

## 🎤 Voice Commands (Optional)

```bash
ytvoice
```

Say:

* “pause music”
* “play music”
* “next song”
* “stop music”

---

## 🧱 Architecture

```
ytmusic (bash function)
 ├─ mpv (audio only)
 │   └─ IPC socket ($PREFIX/tmp/mpv-socket)
 └─ socat
     └─ sends JSON commands
```

---

## 📁 Files Created

| File                     | Purpose             |
| ------------------------ | ------------------- |
| `$PREFIX/tmp/mpv-socket` | mpv IPC socket      |
| `~/.mpv_last_playlist`   | Last playlist URL   |
| `~/.bashrc`              | Command definitions |
| `ytmusic-control.sh`     | Playback controller |
| `ytmusic-notify.sh`      | Media notification  |
| `ytmusic-voice.sh`       | Voice commands      |

---

## ✅ Verification Checklist

```bash
mpv --version
yt-dlp --version
socat -V
termux-wake-lock
```

Test playback:

```bash
ytmusic
status
fw10
bk15
pause
play
```

---

## 🛠 Common Issues

### `/tmp/mpv-socket not found`

Use:

```
$PREFIX/tmp
```

### “mpv is not running”

Start playback first:

```bash
ytmusic
```

### Music stops on lock screen

* Install **Termux:API app**
* Use `ytmusic` (wake-lock enabled)

---

## 🏁 Summary

Now we have:

* 🎧 Terminal-based YouTube music player
* 🔔 Android-native media controls
* 🎤 Optional voice commands
* 🔋 Low memory & battery usage
* 🧑‍💻 Developer-friendly workflow

This is a **clean, powerful, and practical Termux music solution**
