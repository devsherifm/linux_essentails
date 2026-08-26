# ghmd

**ghmd** is a terminal-first, GitHub-style Markdown TUI browser for Linux. It is designed for long technical Markdown documents: README files, network-engineering notes, DevOps documentation, runbooks, cheat sheets, and project documentation.

The renderer uses `markdown-it-py` with its GFM-oriented preset and Rich/Textual for terminal rendering and interaction.

> **0.4.0 is a stability-focused release.** The document itself is now the scroll container instead of a scroll container containing an expanding `Vertical` document. This fixes the main cause of the previous versions appearing frozen and prevents navigation from operating on the wrong scroll layer.

## Highlights

- GitHub/GFM-oriented Markdown parsing
- Responsive terminal layout
- Real Markdown tables with alignment
- H1-H6 visual hierarchy
- Bold, italic, strikethrough, inline code
- Fenced code blocks with syntax highlighting
- Clickable OSC-8 hyperlinks where the terminal supports them
- Local Markdown images
- Native terminal image rendering when `textual-image` works in the current terminal
- `chafa` fallback for terminals without native image graphics
- Task lists
- GitHub-style alerts
- Nested ordered and unordered lists
- Blockquotes
- Footnotes
- `<details>` / `<summary>` using Textual's native `Collapsible`
- Table of Contents navigation
- Full-document search
- Next / previous search match
- Home / End / Page Up / Page Down navigation
- `g`, `G`, `j`, `k`, Space, and `b` navigation
- Mouse wheel scrolling through Textual's `VerticalScroll`
- Live reload
- Dark and light themes
- Optional Rich CLI markup compatibility with `--rich-markup`
- `--diagnose` command for troubleshooting terminal capabilities
- Works on Ubuntu/Kali; Termux is supported when its Python/Textual dependencies are available

## Why 0.4.0 changed the architecture

Earlier versions used:

```text
VerticalScroll
    └── MarkdownDocument (Vertical)
            ├── heading
            ├── paragraph
            ├── table
            └── ...
```

Textual's `Vertical` is an expanding container, so the outer `VerticalScroll` could see the Markdown document as a viewport-sized child rather than as the full document height. That is why long files could render but appear impossible to scroll.

0.4.0 uses:

```text
MarkdownDocument (VerticalScroll)
    ├── heading
    ├── paragraph
    ├── table
    ├── code
    ├── image
    ├── details
    └── ...
```

Textual documents `VerticalScroll` as a vertical scrolling container, while `Vertical` is an expanding non-scrolling container. This release uses the former as the actual document viewport.

## Installation on Ubuntu / Kali

### 1. Extract the project

```bash
cd ~
unzip ~/Downloads/ghmd-tui-0.4.0.zip
cd ~/ghmd
```

If `~/ghmd` already exists and you want a clean installation:

```bash
cd ~
rm -rf ghmd
unzip ~/Downloads/ghmd-tui-0.4.0.zip
cd ~/ghmd
```

### 2. Verify the project root

You **must** be in the directory containing `pyproject.toml`.

```bash
pwd
ls
```

Expected structure:

```text
~/ghmd/
├── pyproject.toml
├── install.sh
├── README.md
├── requirements.txt
├── ghmd/
├── examples/
└── tests/
```

Do **not** run `pipx install .` from `~/ghmd/ghmd`. That directory contains Python source files, not `pyproject.toml`.

### 3. Install

```bash
chmod +x install.sh
./install.sh
```

The installer removes stale setuptools output and installs the project root with `pipx` when `pipx` is available. Otherwise it creates `.venv`.

### 4. Verify

```bash
ghmd --version
ghmd --diagnose
```

Expected version:

```text
ghmd 0.4.0
```

### 5. Run the feature test

```bash
ghmd examples/github-features.md
```

### 6. Open your own Markdown

```bash
ghmd README.md
ghmd /path/to/document.md
```

## Image support

The example file contains:

```markdown
![Example image](../../cover.png)
```

If the repository is:

```text
/home/kali/ghmd
```

and your image is:

```text
/home/kali/cover.png
```

then the example resolves the image correctly.

### Install chafa on Ubuntu

```bash
sudo apt update
sudo apt install -y chafa
```

### Image modes

Automatic mode is the default:

```bash
ghmd examples/github-features.md --image-mode auto
```

Prefer native terminal image support:

```bash
ghmd examples/github-features.md --image-mode native
```

Force chafa:

```bash
ghmd examples/github-features.md --image-mode chafa
```

Disable images:

```bash
ghmd examples/github-features.md --image-mode off
```

or:

```bash
ghmd examples/github-features.md --no-images
```

`textual-image` is used when installed and usable by the terminal. It can provide native terminal graphics on supported terminals and fall back when possible. `chafa` is the portable fallback for terminals that do not provide the required graphics protocol.

## Keyboard controls

### Document navigation

| Key | Action |
|---|---|
| `↑` / `↓` | Scroll one line |
| `j` / `k` | Scroll down / up |
| `Space` | Page down |
| `b` | Page up |
| `g` | Go to top |
| `G` | Go to bottom |
| `Home` | Go to top |
| `End` | Go to bottom |
| `PageDown` | Page down |
| `PageUp` | Page up |
| Mouse wheel | Scroll document |

### Browser features

| Key | Action |
|---|---|
| `t` | Toggle Table of Contents |
| `/` | Search |
| `Enter` | Submit search / select TOC item / toggle focused collapsible |
| `n` | Next search match |
| `N` | Previous search match |
| `r` | Reload |
| `w` | Toggle live reload |
| `Esc` | Close search / TOC, or quit when no overlay is open |
| `q` | Quit |

The navigation commands are handled at the application level, so they continue to work when the document is focused on a normal Markdown block. The document itself is the `VerticalScroll`, so mouse-wheel and arrow-key scrolling operate on the same viewport.

## Search

Press:

```text
/
```

Enter a search term and press `Enter`.

The search indexes rendered document blocks including:

- headings
- paragraphs
- tables
- code blocks
- lists
- task lists
- blockquotes
- alerts
- details content

Then use:

```text
n   next match
N   previous match
```

The match is scrolled into view and highlighted. Search status is displayed in the bottom status line rather than creating a stack of notifications.

## Table of Contents

Press:

```text
t
```

The TOC opens as a navigable list. Use the arrow keys or mouse and press `Enter` to jump to a heading.

The TOC is generated from H1-H6 headings and preserves heading hierarchy through indentation.

## `<details>` support

GitHub-style Markdown commonly uses:

```html
<details>
<summary>Click to expand</summary>

Hidden documentation.

</details>
```

`ghmd` maps this to Textual's native `Collapsible` widget. Textual documents that `Collapsible` can be expanded/collapsed by clicking its title or by focusing it and pressing `Enter`.

## GitHub-style alerts

Supported alert forms include:

```markdown
> [!NOTE]
> Useful information.

> [!TIP]
> A useful tip.

> [!IMPORTANT]
> Something important.

> [!WARNING]
> A warning.

> [!CAUTION]
> A caution.
```

## GFM parser

The parser uses the `gfm-like2` preset from `markdown-it-py`, with footnotes added through `mdit-py-plugins`.

The intent is to parse Markdown according to GitHub/GFM semantics first, then render that structure for the terminal. This is deliberately different from trying to make Rich's own Markdown parser behave like GitHub.

## Rich CLI Markdown files

A Rich CLI demo file may contain Rich markup such as:

```text
[red]RED[/red]
[bold cyan]TEXT[/bold cyan]
```

Those tags are **not GitHub Markdown**. By default `ghmd` correctly treats them as ordinary Markdown text.

If you also want to view Rich CLI demonstration files, use:

```bash
ghmd rich-complete-demo.md --rich-markup
```

This is an optional compatibility mode and is not part of GFM.

## Live reload

Open a file with:

```bash
ghmd README.md --watch
```

or toggle watching inside the browser with:

```text
w
```

The same `MarkdownDocument` widget is retained during reload. Its children are replaced asynchronously instead of replacing the document widget itself. This avoids the duplicate-ID reload failure seen in early versions.

## Troubleshooting

### `ghmd: command not found`

If using pipx:

```bash
pipx ensurepath
```

Then restart the shell.

Check:

```bash
which ghmd
readlink -f "$(which ghmd)"
```

### You accidentally entered `~/ghmd/ghmd`

Go back to the project root:

```bash
cd ~/ghmd
```

Then:

```bash
pipx install --force .
```

### Clean reinstall

```bash
cd ~
pipx uninstall ghmd 2>/dev/null || true
rm -rf ghmd
unzip ~/Downloads/ghmd-tui-0.4.0.zip
cd ~/ghmd
./install.sh
```

### Image is not visible

Run:

```bash
ghmd --diagnose
```

Then try:

```bash
sudo apt install -y chafa
ghmd examples/github-features.md --image-mode chafa
```

If `chafa` works but native images do not, keep `--image-mode chafa`. Native terminal image protocols depend on the terminal emulator.

### A Rich CLI demo shows `[red]` literally

That file is using Rich markup rather than GitHub Markdown. Use:

```bash
ghmd file.md --rich-markup
```

### Reload reports a duplicate `document` ID

That indicates an old installed package is still being executed. Perform a clean reinstall:

```bash
pipx uninstall ghmd 2>/dev/null || true
cd ~/ghmd
./install.sh
```

Then verify:

```bash
ghmd --version
```

It must report `0.4.0`.

## Termux

Termux is not the primary target, but the application is intentionally Python-based and avoids Linux-specific filesystem APIs for normal Markdown rendering.

Try:

```bash
pkg update
pkg install python
python -m pip install --upgrade pip
```

Then install the project with the same source archive:

```bash
cd ~/ghmd
python -m pip install -e .
```

For image support, use the image mode supported by the terminal and packages available in your Termux setup. If native image dependencies are unavailable:

```bash
ghmd README.md --image-mode off
```

The core Markdown reader, TOC, search, scrolling, tables, code, alerts, and live reload do not require native image graphics.

## Development

From the project root:

```bash
python3 -m compileall ghmd
python3 -m pytest
```

The test suite focuses on parser behavior. Interactive Textual behavior should be tested with the application running in a real terminal because terminal capabilities and graphics protocols are environment-dependent.

## Project structure

```text
ghmd/
├── ghmd/
│   ├── app.py
│   ├── cli.py
│   ├── parser.py
│   ├── renderer.py
│   └── theme.py
├── examples/
│   └── github-features.md
├── tests/
│   └── test_parser.py
├── install.sh
├── pyproject.toml
├── requirements.txt
├── CHANGELOG.md
└── README.md
```

## Design goals

The project is intentionally built as:

```text
Markdown source
      │
      ▼
GitHub/GFM-oriented parser
      │
      ▼
Structured Markdown tokens
      │
      ▼
Terminal renderer
      │
      ├── headings
      ├── tables
      ├── code
      ├── links
      ├── alerts
      ├── lists
      ├── images
      └── details
      │
      ▼
Textual TUI
      │
      ├── scrolling
      ├── TOC
      ├── search
      ├── live reload
      └── keyboard / mouse interaction
```

The goal is not to copy GitHub's HTML/CSS pixel-for-pixel. The goal is to reproduce the **document semantics and reading experience** in a terminal while taking advantage of terminal-native features.

## License

MIT


## Image rendering

`ghmd` supports local and remote Markdown images. Remote images are downloaded to `~/.cache/ghmd/images/` and reused.

```bash
ghmd README.md
```

Image modes:

```bash
ghmd README.md --image-mode auto
ghmd README.md --image-mode native
ghmd README.md --image-mode chafa
ghmd README.md --image-mode off
```

In `auto` mode, native terminal graphics are used only for terminals known to support them (currently Kitty/WezTerm); other terminals use `chafa` when available. This avoids the common situation where a native image widget technically mounts but produces an unreadable or invisible image.

Install the fallback on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y chafa
```

## Heading rendering

Markdown heading markers (`#`, `##`, etc.) are not printed as source text. ghmd uses terminal-native visual hierarchy instead: H1 gets a double border, H2 a rounded border, H3/H4 colored left rails, H5 a panel treatment, and H6 a muted italic treatment. Terminal fonts do not provide a portable per-widget font-size API, so hierarchy is expressed through borders, spacing, weight, color, and glyphs.


## 0.4.1 — Rich markup + Termux compatibility

Rich markup inside Markdown is now automatically detected. For example:

```markdown
[bold red]ERROR[/bold red]
[bold green]:white_check_mark: SUCCESS[/bold green]
[cyan]INFO[/cyan]
```

These render as styled terminal text instead of showing the `[bold red]...[/bold red]` source. Ordinary Markdown links such as `[GitHub](https://github.com)` are not treated as Rich markup.

Force Rich markup parsing with `--rich-markup`, or disable automatic detection with `--no-rich-markup`.

### Termux / Android

The core package does not require `textual-image`, so the reader can run on Termux with the normal Python/Textual stack. Image rendering remains optional. On Termux, run `./install.sh`; the installer uses a local virtual environment. If optional image dependencies work on your device, install them with `pip install -e './[images]'`.
