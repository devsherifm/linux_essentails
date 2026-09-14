#!/usr/bin/env python3
"""
GREEN MUSIC v3 - lightweight Termux music TUI

Backend:
  Python curses + mpv JSON IPC
Optional online sources:
  yt-dlp + ffmpeg

Features:
  - Local audio library
  - Radio/direct audio URLs
  - YouTube URL -> stream
  - YouTube URL -> MP3 download
  - Mouse/touch click handling when the terminal delivers mouse events
  - Click progress bar to seek
  - Click playback controls
  - Click playlist entries
  - Keyboard controls
"""

import curses
import json
import math
import os
import random
import re
import shlex
import signal
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

APP = "GREEN MUSIC"
GREEN = 1
DIM_GREEN = 2
WHITE = 3
DIM = 4
YELLOW = 5
RED = 6
BLACK_GREEN = 7

AUDIO_EXTS = {
    ".mp3", ".m4a", ".aac", ".flac", ".ogg", ".opus",
    ".wav", ".webm", ".mka", ".ape", ".wv"
}

CONFIG_DIR = Path.home() / ".config" / "green-music"
CONFIG_FILE = CONFIG_DIR / "config.json"
SOCKET_FILE = Path(tempfile.gettempdir()) / f"green-music-{os.getuid()}.sock"
YTDLP = "yt-dlp"
FFMPEG = "ffmpeg"


DEFAULT_CONFIG = {
    "music_dir": str(Path.home() / "Music"),
    "youtube_dir": str(Path.home() / "Music" / "YouTube"),
    "volume": 80,
    "shuffle": False,
    "repeat": "all",
    "autoplay": True,
    "radio": [
        {"name": "Lofi", "url": "https://streams.ilovemusic.de/iloveradio17.mp3"},
        {"name": "Synthwave", "url": "https://streams.ilovemusic.de/iloveradio6.mp3"}
    ]
}


def load_config():
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    if not CONFIG_FILE.exists():
        CONFIG_FILE.write_text(json.dumps(DEFAULT_CONFIG, indent=2), encoding="utf-8")
        return dict(DEFAULT_CONFIG)
    try:
        data = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        merged = dict(DEFAULT_CONFIG)
        merged.update(data)
        return merged
    except Exception:
        return dict(DEFAULT_CONFIG)


def save_config(cfg):
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2), encoding="utf-8")


def discover_tracks(music_dir):
    p = Path(os.path.expanduser(music_dir))
    if not p.exists():
        return []
    tracks = []
    try:
        for f in p.rglob("*"):
            if f.is_file() and f.suffix.lower() in AUDIO_EXTS:
                tracks.append(str(f))
    except OSError:
        pass
    return sorted(tracks, key=lambda x: x.lower())


def is_url(s):
    return bool(re.match(r"^https?://", s.strip(), re.I))


def is_youtube_url(s):
    s = s.lower()
    return any(x in s for x in (
        "youtube.com/", "youtu.be/", "youtube-nocookie.com/"
    ))


def command_exists(name):
    return shutil_which(name) is not None


def shutil_which(name):
    # Keep dependency footprint minimal; equivalent to shutil.which.
    for directory in os.environ.get("PATH", "").split(os.pathsep):
        p = Path(directory) / name
        if p.is_file() and os.access(p, os.X_OK):
            return str(p)
    return None


class MPV:
    def __init__(self):
        self.proc = None
        self.sock = None
        self.request_id = 0

    def start(self):
        try:
            if SOCKET_FILE.exists():
                SOCKET_FILE.unlink()
        except OSError:
            pass

        self.proc = subprocess.Popen(
            [
                "mpv",
                "--no-video",
                "--idle=yes",
                "--really-quiet",
                "--terminal=no",
                "--input-ipc-server=" + str(SOCKET_FILE),
                "--keep-open=yes",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        deadline = time.time() + 5
        while time.time() < deadline:
            if SOCKET_FILE.exists():
                try:
                    self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.sock.settimeout(0.20)
                    self.sock.connect(str(SOCKET_FILE))
                    return True
                except OSError:
                    try:
                        self.sock.close()
                    except Exception:
                        pass
                    self.sock = None
            time.sleep(0.05)
        return False

    def command(self, *args, timeout=0.5):
        if not self.sock:
            return None
        self.request_id += 1
        rid = self.request_id
        obj = {"command": list(args), "request_id": rid}
        try:
            self.sock.sendall((json.dumps(obj) + "\n").encode())
            end = time.time() + timeout
            data = b""
            while time.time() < end:
                try:
                    chunk = self.sock.recv(16384)
                    if chunk:
                        data += chunk
                        if b"\n" in data:
                            break
                except socket.timeout:
                    break
            for line in data.splitlines():
                try:
                    msg = json.loads(line)
                    if msg.get("request_id") == rid:
                        return msg
                except Exception:
                    continue
        except OSError:
            return None
        return None

    def get(self, prop, default=None):
        r = self.command("get_property", prop)
        if r and r.get("error") == "success":
            return r.get("data", default)
        return default

    def load(self, target):
        # mpv's ytdl hook is available when yt-dlp is installed. For YouTube
        # we normally resolve with yt-dlp ourselves before calling this.
        return self.command("loadfile", target, "replace", timeout=1.0)

    def pause(self):
        return self.command("cycle", "pause")

    def seek_relative(self, seconds):
        return self.command("seek", seconds, "relative")

    def seek_absolute(self, seconds):
        return self.command("seek", seconds, "absolute")

    def set(self, prop, value):
        return self.command("set_property", prop, value)

    def quit(self):
        try:
            self.command("quit", timeout=0.2)
        except Exception:
            pass
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass
        try:
            if self.proc and self.proc.poll() is None:
                self.proc.terminate()
                try:
                    self.proc.wait(timeout=0.7)
                except subprocess.TimeoutExpired:
                    self.proc.kill()
        except Exception:
            pass
        try:
            if SOCKET_FILE.exists():
                SOCKET_FILE.unlink()
        except OSError:
            pass


class Track:
    def __init__(self, name, target, source="Local", duration=None, is_url=False):
        self.name = name
        self.target = target
        self.source = source
        self.duration = duration
        self.is_url = is_url


class App:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        self.cfg = load_config()
        self.mpv = MPV()
        self.tracks = []
        self.index = 0
        self.status = "READY"
        self.message = ""
        self.running = True
        self.bars = [random.random() for _ in range(64)]
        self.show_help = False
        self.show_add = False
        self.last_mouse = None
        self.input_mode = False
        self.progress_click_y = None
        self.rebuild_playlist()

    # ---------- setup / lifecycle ----------

    def setup_colors(self):
        curses.start_color()
        curses.use_default_colors()
        curses.init_pair(GREEN, curses.COLOR_GREEN, -1)
        curses.init_pair(DIM_GREEN, curses.COLOR_GREEN, -1)
        curses.init_pair(WHITE, curses.COLOR_WHITE, -1)
        curses.init_pair(DIM, curses.COLOR_CYAN, -1)
        curses.init_pair(YELLOW, curses.COLOR_YELLOW, -1)
        curses.init_pair(RED, curses.COLOR_RED, -1)
        curses.init_pair(BLACK_GREEN, curses.COLOR_BLACK, curses.COLOR_GREEN)
        try:
            curses.curs_set(0)
        except curses.error:
            pass

        # Touches on a touchscreen are commonly delivered by terminal apps
        # as mouse button events if mouse reporting is enabled.
        try:
            curses.mousemask(
                curses.BUTTON1_CLICKED |
                curses.BUTTON1_PRESSED |
                curses.BUTTON1_RELEASED
            )
            curses.mouseinterval(0)
        except curses.error:
            pass

    def start(self):
        if not self.mpv.start():
            self.status = "ERROR"
            self.message = "mpv IPC could not start. Run: pkg install mpv"
            return
        self.mpv.set("volume", self.cfg.get("volume", 80))
        if self.cfg.get("autoplay", True) and self.tracks:
            self.play_index(0)

    def run(self):
        self.setup_colors()
        self.stdscr.nodelay(True)
        self.stdscr.timeout(80)
        self.start()
        while self.running:
            try:
                key = self.stdscr.getch()
                self.handle_key(key)
                self.check_end()
                try:
                    self.draw()
                except (curses.error, OverflowError):
                    pass
            except KeyboardInterrupt:
                self.running = False
        self.mpv.quit()

    # ---------- playlist ----------

    def rebuild_playlist(self):
        self.tracks = []
        for path in discover_tracks(self.cfg["music_dir"]):
            self.tracks.append(Track(Path(path).stem, path, "FILE", is_url=False))
        for r in self.cfg.get("radio", []):
            self.tracks.append(Track(r["name"], r["url"], "RADIO", is_url=True))
        if self.index >= len(self.tracks):
            self.index = max(0, len(self.tracks) - 1)

    def current(self):
        return self.tracks[self.index] if self.tracks else None

    def play_index(self, i):
        if not self.tracks:
            self.status = "EMPTY"
            self.message = f"No audio files found in {self.cfg['music_dir']}"
            return
        self.index = i % len(self.tracks)
        t = self.current()

        if t.is_url and is_youtube_url(t.target):
            self.status = "RESOLVING"
            self.message = "Resolving YouTube..."
            self.draw()
            resolved = self.resolve_youtube_stream(t.target)
            if not resolved:
                self.status = "ERROR"
                return
            self.mpv.load(resolved)
        else:
            self.mpv.load(t.target)

        self.mpv.set("volume", self.cfg.get("volume", 80))
        self.status = "PLAYING"
        self.message = f"Playing: {t.name}"

    def next(self):
        if not self.tracks:
            return
        if self.cfg.get("shuffle"):
            candidates = list(range(len(self.tracks)))
            candidates.remove(self.index)
            self.index = random.choice(candidates) if candidates else self.index
        else:
            self.index = (self.index + 1) % len(self.tracks)
        self.play_index(self.index)

    def previous(self):
        if not self.tracks:
            return
        pos = float(self.mpv.get("time-pos", 0) or 0)
        if pos > 5:
            self.mpv.seek_absolute(0)
            self.message = "Restarted current track"
            return
        self.index = (self.index - 1) % len(self.tracks)
        self.play_index(self.index)

    def check_end(self):
        eof = self.mpv.get("eof-reached", False)
        if eof:
            if self.cfg.get("repeat") == "one":
                self.play_index(self.index)
            elif self.cfg.get("repeat") == "off" and self.index >= len(self.tracks) - 1:
                self.status = "STOPPED"
            else:
                self.next()

    # ---------- playback ----------

    def toggle_play(self):
        if not self.current():
            return
        self.mpv.pause()
        paused = bool(self.mpv.get("pause", False))
        self.status = "PAUSED" if paused else "PLAYING"

    def seek(self, amount):
        self.mpv.seek_relative(amount)
        self.message = f"Seek {'+' if amount >= 0 else ''}{amount}s"

    def seek_absolute_from_x(self, x, bar_x, bar_w):
        if bar_w <= 0:
            return
        dur = self.mpv.get("duration", None)
        if not isinstance(dur, (int, float)) or not math.isfinite(float(dur)) or dur <= 0:
            self.message = "Seek unavailable for this stream"
            return
        ratio = max(0.0, min(1.0, (x - bar_x) / float(bar_w)))
        target = float(dur) * ratio
        self.mpv.seek_absolute(target)
        self.message = f"Seek {self.format_time(target)}"

    def volume(self, amount):
        v = float(self.mpv.get("volume", self.cfg.get("volume", 80)) or 0)
        v = max(0, min(100, v + amount))
        self.cfg["volume"] = int(v)
        self.mpv.set("volume", v)
        save_config(self.cfg)
        self.message = f"Volume {int(v)}%"

    def set_volume_from_x(self, x, slider_x, slider_w):
        if slider_w <= 0:
            return
        ratio = max(0.0, min(1.0, (x - slider_x) / float(slider_w)))
        v = int(round(ratio * 100))
        self.cfg["volume"] = v
        self.mpv.set("volume", v)
        save_config(self.cfg)
        self.message = f"Volume {v}%"

    def mute(self):
        self.mpv.command("cycle", "mute")
        muted = bool(self.mpv.get("mute", False))
        self.message = "Muted" if muted else "Unmuted"

    def toggle_shuffle(self):
        self.cfg["shuffle"] = not self.cfg.get("shuffle", False)
        save_config(self.cfg)
        self.message = "Shuffle ON" if self.cfg["shuffle"] else "Shuffle OFF"

    def toggle_repeat(self):
        mode = self.cfg.get("repeat", "all")
        mode = {"all": "one", "one": "off", "off": "all"}[mode]
        self.cfg["repeat"] = mode
        save_config(self.cfg)
        self.message = f"Repeat {mode.upper()}"

    # ---------- yt-dlp ----------

    def yt_ready(self):
        if not command_exists(YTDLP):
            self.status = "ERROR"
            self.message = "yt-dlp not installed. Run: pkg install yt-dlp"
            return False
        return True

    def resolve_youtube_stream(self, url):
        if not self.yt_ready():
            return None
        try:
            p = subprocess.run(
                [YTDLP, "--no-playlist", "-f", "bestaudio/best", "-g", url],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=30
            )
            urls = [x.strip() for x in p.stdout.splitlines() if x.strip()]
            if p.returncode != 0 or not urls:
                err = p.stderr.strip().splitlines()
                self.message = (err[-1] if err else "Could not resolve YouTube URL")[:max(20, self.stdscr.getmaxyx()[1] - 8)]
                return None
            return urls[-1]
        except subprocess.TimeoutExpired:
            self.message = "YouTube resolve timed out"
            return None
        except Exception as e:
            self.message = f"YouTube error: {str(e)[:80]}"
            return None

    def get_youtube_title(self, url):
        if not self.yt_ready():
            return "YouTube audio"
        try:
            p = subprocess.run(
                [YTDLP, "--no-playlist", "--print", "%(title)s", "--skip-download", url],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, timeout=25
            )
            title = p.stdout.strip().splitlines()
            return title[-1] if title else "YouTube audio"
        except Exception:
            return "YouTube audio"

    def play_youtube_url(self, url):
        if not is_url(url):
            self.message = "Enter a complete http(s) URL"
            return
        if not self.yt_ready():
            return

        if is_youtube_url(url):
            self.status = "RESOLVING"
            self.message = "Resolving YouTube stream..."
            self.draw()
            title = self.get_youtube_title(url)
            stream = self.resolve_youtube_stream(url)
            if stream:
                self.tracks.append(Track(title, stream, "YT-STREAM", is_url=True))
                self.index = len(self.tracks) - 1
                self.mpv.load(stream)
                self.status = "PLAYING"
                self.message = f"YouTube: {title}"
        else:
            # Direct audio/stream URL.
            name = url.split("?")[0].rstrip("/").split("/")[-1] or "Web stream"
            self.tracks.append(Track(name, url, "URL", is_url=True))
            self.index = len(self.tracks) - 1
            self.mpv.load(url)
            self.status = "PLAYING"
            self.message = f"Streaming: {name}"

    def download_youtube_mp3(self, url):
        if not is_youtube_url(url):
            self.message = "MP3 download expects a YouTube URL"
            return
        if not self.yt_ready():
            return
        if not command_exists(FFMPEG):
            self.status = "ERROR"
            self.message = "ffmpeg not installed. Run: pkg install ffmpeg"
            return

        out_dir = Path(os.path.expanduser(self.cfg.get("youtube_dir", "~/Music/YouTube")))
        out_dir.mkdir(parents=True, exist_ok=True)

        self.status = "DOWNLOADING"
        self.message = "Downloading + converting to MP3..."
        self.draw()

        template = str(out_dir / "%(title)s.%(ext)s")
        try:
            p = subprocess.run(
                [
                    YTDLP, "--no-playlist",
                    "-x", "--audio-format", "mp3", "--audio-quality", "0",
                    "--embed-metadata",
                    "-o", template,
                    url
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=900
            )
            if p.returncode != 0:
                err = p.stderr.strip().splitlines()
                self.status = "ERROR"
                self.message = (err[-1] if err else "YouTube MP3 download failed")[:100]
                return

            # Find the newest mp3 created in the target folder.
            candidates = sorted(out_dir.glob("*.mp3"), key=lambda x: x.stat().st_mtime, reverse=True)
            if not candidates:
                self.status = "ERROR"
                self.message = "Download completed but MP3 was not found"
                return

            newest = candidates[0]
            self.rebuild_playlist()
            matches = [i for i, t in enumerate(self.tracks) if os.path.abspath(t.target) == os.path.abspath(str(newest))]
            if matches:
                self.index = matches[0]
            else:
                self.tracks.append(Track(newest.stem, str(newest), "YT-MP3", is_url=False))
                self.index = len(self.tracks) - 1
            self.mpv.load(self.current().target)
            self.status = "PLAYING"
            self.message = f"Added MP3: {newest.stem}"
        except subprocess.TimeoutExpired:
            self.status = "ERROR"
            self.message = "Download timed out"
        except Exception as e:
            self.status = "ERROR"
            self.message = f"Download error: {str(e)[:80]}"

    # ---------- UI helpers ----------

    def format_time(self, seconds):
        try:
            if seconds is None or not math.isfinite(float(seconds)):
                return "--:--"
        except Exception:
            return "--:--"
        seconds = max(0, int(float(seconds)))
        return f"{seconds // 60:02d}:{seconds % 60:02d}"

    def safe_add(self, y, x, text, attr=0):
        h, w = self.stdscr.getmaxyx()
        if y < 0 or y >= h or x >= w:
            return
        text = str(text)
        try:
            self.stdscr.addnstr(y, max(0, x), text, max(0, w - x - 1), attr)
        except curses.error:
            pass

    def box(self, y, x, h, w, title=None):
        if h < 2 or w < 8:
            return
        try:
            self.stdscr.addch(y, x, "+", curses.color_pair(GREEN))
            self.stdscr.hline(y, x + 1, "-", w - 2)
            self.stdscr.addch(y, x + w - 1, "+", curses.color_pair(GREEN))
            for yy in range(y + 1, y + h - 1):
                self.stdscr.addch(yy, x, "|", curses.color_pair(GREEN))
                self.stdscr.addch(yy, x + w - 1, "|", curses.color_pair(GREEN))
            self.stdscr.addch(y + h - 1, x, "+", curses.color_pair(GREEN))
            self.stdscr.hline(y + h - 1, x + 1, "-", w - 2)
            self.stdscr.addch(y + h - 1, x + w - 1, "+", curses.color_pair(GREEN))
            if title:
                self.safe_add(y, x + 2, f" {title} ", curses.color_pair(GREEN) | curses.A_BOLD)
        except (curses.error, OverflowError):
            pass

    def draw_header(self, width):
        self.safe_add(1, 2, "o o o", curses.color_pair(DIM))
        self.safe_add(1, 10, "tty1", curses.color_pair(WHITE) | curses.A_BOLD)
        logo = "G R E E N   M U S I C"
        self.safe_add(1, max(2, width - len(logo) - 2), logo, curses.color_pair(GREEN) | curses.A_BOLD)

    def draw_visualizer(self, y, x, w, h):
        now = time.monotonic()
        if w <= 0 or h <= 0:
            return
        for i in range(min(w, 80)):
            wave = (math.sin(now * 3.2 + i * 0.42) + 1) / 2
            wave2 = (math.sin(now * 1.7 + i * 0.18) + 1) / 2
            self.bars[i % len(self.bars)] = max(0.08, 0.68 * wave + 0.32 * wave2)
        for col in range(w):
            v = self.bars[col % len(self.bars)]
            bar_h = max(1, int(v * h))
            for row in range(h):
                ch = " " if row < h - bar_h else "#"
                attr = curses.color_pair(GREEN)
                if row == h - bar_h:
                    attr |= curses.A_BOLD
                self.safe_add(y + row, x + col, ch, attr)

    def draw_progress(self, y, x, w, pos, dur):
        if w <= 0:
            return
        ratio = 0 if not dur or not math.isfinite(float(dur)) else max(0, min(1, pos / dur))
        fill = int(ratio * w)
        fill = min(w - 1, max(0, fill))
        self.safe_add(y, x, "-" * fill, curses.color_pair(GREEN) | curses.A_BOLD)
        self.safe_add(y, x + fill, "O", curses.color_pair(GREEN) | curses.A_BOLD)
        self.safe_add(y, x + fill + 1, "-" * max(0, w - fill - 1), curses.color_pair(DIM))

    def draw_button(self, y, x, label, active=False):
        text = f"[ {label} ]"
        attr = curses.color_pair(BLACK_GREEN if active else GREEN) | curses.A_BOLD
        self.safe_add(y, x, text, attr)

    def draw_compact(self, h, w):
        self.safe_add(0, 1, "GREEN MUSIC", curses.color_pair(GREEN) | curses.A_BOLD)
        self.safe_add(1, 1, "-" * max(1, w - 2), curses.color_pair(DIM))
        t = self.current()
        paused = bool(self.mpv.get("pause", False))
        pos = float(self.mpv.get("time-pos", 0) or 0)
        d = self.mpv.get("duration", None)
        dur = float(d) if isinstance(d, (int, float)) else None
        vol = int(float(self.mpv.get("volume", self.cfg.get("volume", 80)) or 0))

        if t:
            name = t.name
            if len(name) > w - 4:
                name = name[:max(1, w - 7)] + "..."
            self.safe_add(3, 1, name, curses.color_pair(WHITE) | curses.A_BOLD)
            self.safe_add(4, 1, f"{'PAUSED' if paused else self.status}  VOL {vol}%  {t.source}",
                          curses.color_pair(GREEN))

        if h >= 9:
            self.draw_visualizer(6, 1, max(1, w - 2), min(3, max(1, h - 15)))

        py = max(8, h - 7)
        if py < h:
            self.safe_add(py, 1, self.format_time(pos), curses.color_pair(GREEN))
            if w > 20:
                self.draw_progress(py, 9, max(5, w - 19), pos, dur)
                self.safe_add(py, max(1, w - 8), self.format_time(dur), curses.color_pair(GREEN))

        if h >= 4:
            self.safe_add(h - 4, 1, "[P]REV [SPACE]PLAY [N]EXT  [Y]T URL  [D]L MP3", curses.color_pair(WHITE))
        if h >= 3:
            self.safe_add(h - 3, 1, "[UP/DN]VOL [S]HUFFLE [R]EPEAT [M]UTE", curses.color_pair(DIM))
        if h >= 2:
            self.safe_add(h - 2, 1, "[H]ELP  [L]OAD  [Q]UIT  TAP=CLICK", curses.color_pair(GREEN) | curses.A_BOLD)

    def draw(self):
        self.stdscr.erase()
        h, w = self.stdscr.getmaxyx()

        if h < 25 or w < 80:
            self.draw_compact(h, w)
            self.draw_add_overlay() if self.show_add else None
            self.draw_help() if self.show_help else None
            self.stdscr.refresh()
            return

        self.draw_header(w)
        self.safe_add(3, 2, "[ MUSIC ]  Lofi / Terminal Player", curses.color_pair(WHITE) | curses.A_BOLD)
        self.safe_add(4, 2, "local audio + radio + URL + YouTube", curses.color_pair(DIM))

        t = self.current()
        listeners = t.source if t else "LOCAL"
        self.safe_add(6, 2, self.status, curses.color_pair(GREEN) | curses.A_BOLD)
        self.safe_add(6, w - len(listeners) - 3, listeners, curses.color_pair(GREEN) | curses.A_BOLD)

        pos = float(self.mpv.get("time-pos", 0) or 0)
        d = self.mpv.get("duration", None)
        dur = float(d) if isinstance(d, (int, float)) else None
        paused = bool(self.mpv.get("pause", False))
        if paused:
            self.status = "PAUSED"
        elif t and self.status not in ("STOPPED", "ERROR", "DOWNLOADING"):
            self.status = "PLAYING"

        self.draw_visualizer(8, 2, w - 4, 7)

        self.safe_add(16, 2, "EQ  [Rock]", curses.color_pair(YELLOW) | curses.A_BOLD)
        for i in range(10):
            level = 1 + int((math.sin(time.monotonic() * 3 + i * .8) + 1) * 2)
            self.safe_add(16 + (4 - level), 15 + i * 2, "|", curses.color_pair(GREEN) | curses.A_BOLD)

        vol = int(float(self.mpv.get("volume", self.cfg.get("volume", 80)) or 0))
        self.safe_add(16, 38, "VOL", curses.color_pair(DIM) | curses.A_BOLD)
        slider_w = min(24, max(10, w // 5))
        slider_fill = int(slider_w * vol / 100)
        self.safe_add(16, 44, "-" * slider_fill, curses.color_pair(GREEN) | curses.A_BOLD)
        self.safe_add(16, 44 + slider_fill, "O", curses.color_pair(GREEN))
        self.safe_add(16, 45 + slider_w, f"{vol:3d}", curses.color_pair(WHITE))

        if t:
            name = t.name
            if len(name) > w - 24:
                name = name[:w - 27] + "..."
            self.safe_add(18, 2, name, curses.color_pair(WHITE) | curses.A_BOLD)
            self.safe_add(19, 2, t.source, curses.color_pair(DIM))

        self.draw_button(18, 27, "PREV")
        self.draw_button(18, 41, "PLAY" if paused else "PAUSE", active=True)
        self.draw_button(18, 57, "NEXT")

        self.safe_add(21, 2, self.format_time(pos), curses.color_pair(GREEN))
        progress_x = 10
        progress_w = max(20, w - 24)
        self.draw_progress(21, progress_x, progress_w, pos, dur)
        self.safe_add(21, w - 11, self.format_time(dur), curses.color_pair(GREEN))

        playlist_y = 23
        playlist_h = max(3, h - 27)
        self.box(playlist_y, 2, playlist_h, max(8, w - 4), "PLAYLIST")
        mode = f"Shuffle: {'ON' if self.cfg.get('shuffle') else 'OFF'}   Repeat: {self.cfg.get('repeat', 'all').upper()}"
        self.safe_add(24, 4, mode, curses.color_pair(DIM))
        list_y = 26
        visible = max(1, h - list_y - 2)
        start = max(0, min(self.index - visible + 1, self.index))
        for row, idx in enumerate(range(start, min(len(self.tracks), start + visible))):
            tr = self.tracks[idx]
            marker = ">" if idx == self.index else " "
            line = f"{marker} {idx + 1:02d}. {tr.name}"
            if len(line) > w - 20:
                line = line[:w - 23] + "..."
            self.safe_add(list_y + row, 4, line,
                          curses.color_pair(WHITE if idx == self.index else DIM) |
                          (curses.A_BOLD if idx == self.index else 0))
            self.safe_add(list_y + row, w - 12, tr.source[:7], curses.color_pair(GREEN))

        footer_y = h - 1
        self.safe_add(
            footer_y, 2,
            "SPACE Play/Pause  <-/-> Seek  Up/Down Vol  N/P Track  S Shuffle  R Repeat  M Mute  Y YouTube  Q Quit",
            curses.color_pair(DIM)
        )

        if self.message:
            self.safe_add(6, max(2, w // 2), self.message[:max(10, w // 2 - 4)], curses.color_pair(YELLOW))

        if self.show_help:
            self.draw_help()
        if self.show_add:
            self.draw_add_overlay()

        self.stdscr.refresh()

    def draw_help(self):
        h, w = self.stdscr.getmaxyx()
        hh = min(18, max(8, h - 4))
        ww = min(68, max(30, w - 6))
        y = max(2, (h - hh) // 2)
        x = max(3, (w - ww) // 2)
        self.box(y, x, hh, ww, "KEYBOARD / TOUCH")
        lines = [
            "SPACE     play / pause",
            "LEFT/RIGHT seek -10 / +10 seconds",
            "UP/DOWN   volume +5 / -5",
            "N / P     next / previous (P restarts if >5 sec)",
            "S         shuffle",
            "R         repeat all / one / off",
            "M         mute",
            "Y         YouTube/direct URL -> stream",
            "D         YouTube URL -> MP3",
            "L         reload local playlist",
            "A         add URL / source menu",
            "Mouse     tap progress / buttons / playlist",
            "H         close help     Q quit",
        ]
        for i, line in enumerate(lines[:hh - 2]):
            self.safe_add(y + 1 + i, x + 3, line, curses.color_pair(WHITE if i < 12 else DIM))

    def draw_add_overlay(self):
        h, w = self.stdscr.getmaxyx()
        hh = min(11, max(8, h - 4))
        ww = min(70, max(34, w - 6))
        y = max(2, (h - hh) // 2)
        x = max(3, (w - ww) // 2)
        self.box(y, x, hh, ww, "ADD / ONLINE")
        lines = [
            "Y  YouTube/direct URL -> stream",
            "D  YouTube URL -> download MP3",
            "R  Radio/direct stream URL",
            "",
            "Paste URL when prompted. ESC cancels.",
        ]
        for i, line in enumerate(lines):
            self.safe_add(y + 2 + i, x + 3, line, curses.color_pair(WHITE if i < 3 else DIM))

    # ---------- input ----------

    def prompt(self, title):
        """Small curses line editor. Android Termux paste works through terminal input."""
        h, w = self.stdscr.getmaxyx()
        self.input_mode = True
        try:
            curses.echo()
            try:
                curses.curs_set(1)
            except curses.error:
                pass

            self.stdscr.nodelay(False)
            self.stdscr.timeout(-1)

            ph = 5
            pw = min(max(40, len(title) + 12), max(20, w - 4))
            y = max(1, (h - ph) // 2)
            x = max(1, (w - pw) // 2)
            self.stdscr.erase()
            self.box(y, x, ph, pw, "INPUT")
            self.safe_add(y + 1, x + 2, title, curses.color_pair(WHITE) | curses.A_BOLD)
            self.safe_add(y + 3, x + 2, "> ", curses.color_pair(GREEN) | curses.A_BOLD)
            self.stdscr.refresh()

            raw = self.stdscr.getstr(y + 3, x + 4, max(1, pw - 7))
            return raw.decode("utf-8", errors="ignore").strip()
        finally:
            curses.noecho()
            try:
                curses.curs_set(0)
            except curses.error:
                pass
            self.stdscr.nodelay(True)
            self.stdscr.timeout(80)
            self.input_mode = False

    def open_online_stream(self):
        self.show_add = False
        url = self.prompt("Paste YouTube or direct audio URL")
        if url:
            self.play_youtube_url(url)

    def open_youtube_mp3(self):
        self.show_add = False
        url = self.prompt("Paste YouTube URL for MP3 download")
        if url:
            self.download_youtube_mp3(url)

    def handle_mouse(self):
        try:
            event = curses.getmouse()
        except curses.error:
            return
        _, mx, my, _, bstate = event

        # Ignore releases unless the terminal doesn't report clicks.
        clicked = bool(
            bstate & (curses.BUTTON1_CLICKED | curses.BUTTON1_RELEASED | curses.BUTTON1_PRESSED)
        )
        if not clicked:
            return

        h, w = self.stdscr.getmaxyx()

        # Compact UI.
        if h < 25 or w < 80:
            # Bottom button zones.
            if my >= h - 4:
                if mx < w // 3:
                    self.previous()
                elif mx < (2 * w) // 3:
                    self.toggle_play()
                else:
                    self.next()
                return
            return

        # Progress bar.
        if my == 21:
            progress_x = 10
            progress_w = max(20, w - 24)
            if progress_x <= mx < progress_x + progress_w:
                self.seek_absolute_from_x(mx, progress_x, progress_w)
                return

        # Main controls.
        if 17 <= my <= 19:
            if 24 <= mx < 39:
                self.previous()
                return
            if 39 <= mx < 56:
                self.toggle_play()
                return
            if 56 <= mx < 72:
                self.next()
                return

        # Volume slider.
        if my == 16:
            slider_x = 44
            slider_w = min(24, max(10, w // 5))
            if slider_x <= mx <= slider_x + slider_w:
                self.set_volume_from_x(mx, slider_x, slider_w)
                return

        # Playlist.
        list_y = 26
        visible = max(1, h - list_y - 2)
        start = max(0, min(self.index - visible + 1, self.index))
        if list_y <= my < list_y + visible:
            idx = start + (my - list_y)
            if 0 <= idx < len(self.tracks):
                self.play_index(idx)

    def handle_key(self, key):
        if key == -1:
            return

        if key == curses.KEY_MOUSE:
            self.handle_mouse()
            return

        if self.show_help:
            if key in (ord("h"), ord("H"), 27):
                self.show_help = False
            return

        if self.show_add:
            if key in (27, ord("a"), ord("A")):
                self.show_add = False
                return
            if key in (ord("y"), ord("Y")):
                self.open_online_stream()
                return
            if key in (ord("d"), ord("D")):
                self.open_youtube_mp3()
                return
            return

        if key in (ord("q"), ord("Q")):
            self.running = False
        elif key == curses.KEY_RESIZE:
            pass
        elif key == ord(" "):
            self.toggle_play()
        elif key in (curses.KEY_RIGHT, ord("l")):
            self.seek(10)
        elif key in (curses.KEY_LEFT, ord("j")):
            self.seek(-10)
        elif key == curses.KEY_UP:
            self.volume(5)
        elif key == curses.KEY_DOWN:
            self.volume(-5)
        elif key in (ord("n"), ord("N")):
            self.next()
        elif key in (ord("p"), ord("P")):
            self.previous()
        elif key in (ord("s"), ord("S")):
            self.toggle_shuffle()
        elif key in (ord("r"), ord("R")):
            self.toggle_repeat()
        elif key in (ord("m"), ord("M")):
            self.mute()
        elif key in (ord("l"), ord("L")):
            self.rebuild_playlist()
            self.message = f"Playlist reloaded: {len(self.tracks)} tracks"
        elif key in (ord("h"), ord("H")):
            self.show_help = True
        elif key in (ord("y"), ord("Y")):
            self.open_online_stream()
        elif key in (ord("d"), ord("D")):
            self.open_youtube_mp3()
        elif key in (ord("a"), ord("A")):
            self.show_add = True


def main():
    if os.name != "posix":
        print("This player is designed for Termux/Linux.")
        sys.exit(1)
    try:
        curses.wrapper(lambda stdscr: App(stdscr).run())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
