# 🎵 Green Music TUI

A lightweight, terminal-native music player for **Termux and Ubuntu Linux**.

Green Music is designed to look and behave like a real terminal application: no GUI framework, no Docker, and no browser-based frontend. It uses a Python `curses` interface with `mpv` for playback and `yt-dlp` for YouTube extraction/downloads.

---

## ✨ Features

- 🎵 Local music playback
- 📻 Internet radio / direct audio streams
- ▶️ Play / pause
- ⏭️ Next track
- ⏮️ Previous track / restart current track
- 🔀 Shuffle
- 🔁 Repeat
- 🔇 Mute
- 🔊 Volume control
- ⏩ Seek forward/backward
- 📊 Live progress bar
- 📈 Terminal visualizer
- 🖱️ Mouse/touch interaction where the terminal supports mouse events
- 🎯 Tap/click the progress bar to seek
- 🎯 Tap/click Previous, Play/Pause, Next and volume controls
- 🎯 Tap a playlist item to play it
- ▶️ Paste a YouTube URL and stream it immediately
- 💾 Paste a YouTube URL and download it as MP3
- 📁 Downloads YouTube MP3 files into `~/Music/YouTube`
- 🖥️ Works on Termux and Ubuntu
- ⚙️ Automatically checks and installs required dependencies
- 🚀 One-command installation/startup
- 🧹 Built-in rollback/uninstall
- 🪶 Lightweight compared with browser-based music interfaces

---

# 🖥️ Supported Platforms

## Termux

Designed for Android devices running Termux.

## Ubuntu

Designed for Ubuntu Linux, including **Ubuntu 24.04 LTS**.

The universal launcher automatically detects the environment, so users normally do not need to select a platform manually.

---

# 🚀 Quick Start

Clone the project:

```bash
git clone <YOUR-GITHUB-REPOSITORY-URL>.git
cd <YOUR-REPOSITORY-DIRECTORY>
```

Make the scripts executable if necessary:

```bash
chmod +x *.sh
```

Run:

```bash
./green_music.sh
```

That's it.

The universal script detects whether it is running under Termux or Ubuntu and performs the appropriate setup.

---

# 📦 Automatic Dependency Setup

The installer checks for the required software and installs what is missing.

Main components:

| Component | Purpose |
|---|---|
| Python 3 | TUI application |
| Python curses | Terminal interface |
| mpv | Audio playback |
| ffmpeg | Audio conversion / MP3 extraction |
| yt-dlp | YouTube/media extraction |
| curl | Downloading required upstream tools |
| ca-certificates | HTTPS certificate support |

You should not need to manually install these before running the installer.

The Ubuntu setup uses the current upstream `yt-dlp` release instead of depending on an older Ubuntu repository version.

---

# 🎮 Controls

| Key | Action |
|---|---|
| `SPACE` | Play / Pause |
| `←` | Seek backward |
| `→` | Seek forward |
| `↑` | Increase volume |
| `↓` | Decrease volume |
| `N` | Next track |
| `P` | Previous track / restart |
| `S` | Shuffle |
| `R` | Repeat |
| `M` | Mute |
| `Y` | YouTube/direct URL → stream |
| `D` | YouTube URL → MP3 |
| `A` | Add/source menu |
| `L` | Reload playlist/config |
| `H` | Help |
| `Q` | Quit |

---

# 🖱️ Mouse / Touch Controls

If your terminal emulator forwards mouse events, you can interact directly with the TUI.

### Progress bar

Tap/click anywhere on the progress bar to seek to that position.

For example:

```text
00:42 ━━━━━━━━━●━━━━━━━━━━━━ 03:25
              ↑
           tap here
```

The player converts the horizontal position into the corresponding playback time.

### Playback controls

The following controls can be clicked/tapped:

- Previous
- Play/Pause
- Next
- Volume slider
- Playlist entries

Keyboard controls remain available if mouse events are not supported by the terminal.

---

# ▶️ YouTube Streaming

Press:

```text
Y
```

The player asks for a URL.

Paste a YouTube URL such as:

```text
https://www.youtube.com/watch?v=XXXXXXXXXXX
```

The player uses `yt-dlp` to resolve the best available audio stream and passes it to `mpv`.

The audio starts streaming without first creating an MP3 file.

---

# 💾 YouTube → MP3

Press:

```text
D
```

Paste the YouTube URL.

The player uses:

```text
yt-dlp
+
ffmpeg
```

to extract the audio and save it as MP3.

Default destination:

```text
~/Music/YouTube/
```

Metadata is embedded when available.

---

# 📁 Local Music

Place music files in your music directory:

```text
~/Music/
```

For example:

```text
~/Music/
├── song1.mp3
├── song2.flac
├── album/
│   ├── track01.mp3
│   └── track02.mp3
└── YouTube/
```

The player can use the configured music/source paths and playlist entries.

Supported formats ultimately depend on what `mpv`/FFmpeg can decode.

---

# 📻 Internet Radio

Radio stations are configured in:

```text
config.json
```

The configuration can contain direct audio stream URLs.

Example:

```json
{
  "stations": [
    {
      "name": "Lofi",
      "url": "https://example.com/stream.mp3"
    }
  ]
}
```

Direct streams are played by `mpv`.

Because internet radio endpoints can change or block certain clients, an individual station may occasionally become unavailable. This does not mean the TUI itself is broken.

---

# ⚙️ Configuration

The application configuration is installed under:

```text
~/.config/green-music/
```

Typical files include:

```text
~/.config/green-music/
├── player.py
└── config.json
```

The configuration can be edited if you want to add or change stations or other playlist settings.

---

# 🧩 Architecture

Green Music intentionally keeps the architecture simple:

```text
                 ┌──────────────────┐
                 │  Green Music TUI │
                 │     Python       │
                 │     curses       │
                 └────────┬─────────┘
                          │
                    JSON IPC / CLI
                          │
                 ┌────────▼─────────┐
                 │       mpv        │
                 │  Audio Playback  │
                 └────────┬─────────┘
                          │
             ┌────────────┴────────────┐
             │                         │
       Local Music                Internet Audio
             │                         │
             │                  ┌──────▼──────┐
             │                  │   yt-dlp    │
             │                  │  YouTube    │
             │                  └─────────────┘
             │
             └───────────────┐
                             │
                         ┌───▼───┐
                         │ ffmpeg│
                         └───────┘
```

There is no Docker requirement and no web server requirement.

---

# 📱 Termux

Run:

```bash
./green_music.sh
```

The script detects Termux and installs the appropriate packages using Termux's package manager.

After installation, Green Music can be started again with:

```bash
green-music
```

If the command is not found in the current shell, restart Termux or ensure:

```bash
$HOME/.local/bin
```

is in your `PATH`.

---

# 🐧 Ubuntu

Run:

```bash
./green_music.sh
```

The script detects Ubuntu/Linux and installs the required system dependencies.

After installation:

```bash
green-music
```

You can also run the installed player directly:

```bash
python3 ~/.config/green-music/player.py
```

---

# 🔄 Re-running the Installer

It is safe to run:

```bash
./green_music.sh
```

again.

The script checks the environment and dependencies instead of requiring a completely manual setup.

---

# 🧹 Rollback / Uninstall

To remove the Green Music installation:

```bash
./green_music.sh rollback
```

The rollback removes the application's own configuration, launcher and application-managed files.

It intentionally does **not** blindly remove your entire music directory or unrelated system packages.

Your personal music under:

```text
~/Music
```

is therefore not treated as something that should be deleted by the application rollback.

---

# 🛠️ Troubleshooting

## Player exits immediately

Run the Python application directly with unbuffered output:

```bash
python3 -u ~/.config/green-music/player.py
```

Any traceback or error shown there will usually identify the problem.

---

## Check mpv

```bash
mpv --version
```

---

## Check yt-dlp

```bash
yt-dlp --version
```

---

## Check ffmpeg

```bash
ffmpeg -version
```

---

## YouTube returns HTTP 403

YouTube extraction can change over time and may occasionally require a newer `yt-dlp`, additional YouTube support components, cookies, or other extraction requirements.

First check the installed version:

```bash
yt-dlp --version
```

Then update/reinstall the upstream version through the project's installer if necessary.

A `403 Forbidden` from YouTube is generally an extraction/service-side issue rather than a `curses` or `mpv` TUI rendering problem.

Not every YouTube URL is guaranteed to be playable because YouTube can impose restrictions on particular videos, accounts, regions, formats or clients.

---

## Radio station does not play

Test the stream outside the TUI:

```bash
mpv "STREAM_URL"
```

If `mpv` cannot open the stream directly, the station may have changed its URL, gone offline, or blocked the connection.

---

## Mouse/touch does not work

Mouse support depends on the terminal emulator forwarding mouse events.

The application remains fully usable from the keyboard.

On Android, terminal/touch behavior can also vary between terminal applications and versions.

---

# 🔐 Responsible Use

Green Music is a playback tool.

When using `yt-dlp` with online services, users are responsible for complying with the applicable service terms, copyright laws and permissions for the content they access or download.

Only download or convert content that you are legally permitted to use.

---

# 📜 License

See the project's `LICENSE` file for the applicable license.

---

# 🤝 Contributing

Contributions are welcome.

Useful areas include:

- New radio stations
- Better terminal compatibility
- UI improvements
- Additional playback controls
- Playlist management
- Better error handling
- More Linux distribution support
- Termux improvements
- Performance improvements

Before submitting changes, test on both:

```text
Termux
Ubuntu 24.04 LTS
```

where possible.

---

# ⭐ Project Goal

Green Music aims to provide a simple experience:

```text
Clone
  ↓
Run one command
  ↓
Automatic platform detection
  ↓
Automatic dependency setup
  ↓
Terminal music player
```

No Docker.

No browser.

No GUI framework.

Just a lightweight terminal music player powered by Python, curses, mpv, FFmpeg and yt-dlp.

---

## Quick Reference

```bash
# Clone
git clone <YOUR-GITHUB-REPOSITORY-URL>.git

# Enter project
cd <YOUR-REPOSITORY-DIRECTORY>

# Make scripts executable
chmod +x *.sh

# Install + start
./green_music.sh

# Start later
green-music

# Rollback
./green_music.sh rollback
```

**Green Music — lightweight music playback directly in your terminal. 🎵**
