# Changelog

## 0.4.1

- Automatically render Rich markup found inside Markdown text, including colors, bold, underline, reverse, nested styles, and emoji codes.
- Added `--no-rich-markup` to preserve literal Rich syntax when required.
- Kept `--rich-markup` as a force mode.
- Made `textual-image` optional so the core reader is easier to install on Termux/Android.
- Added separate `requirements-images.txt` for optional image support.
- Updated the installer to prefer a local venv on Termux instead of requiring pipx.
- Preserved GFM/Markdown rendering, scrolling, search, TOC, tables, alerts, code highlighting, details, and image fallback behavior.

# Changelog

## 0.4.0

- Removed Markdown `#` / `##` source prefixes from rendered headings.
- Added six-level visual heading hierarchy with borders, rails, spacing, glyphs, and emphasis.
- Added persistent remote image download/cache for HTTP(S) Markdown images.
- Added `/home/kali/cover.png` local image test to the example document.
- Added the supplied BBC image URL as an online image test.
- Improved image auto mode: native terminal graphics are used only on known Kitty/WezTerm terminals; other terminals fall back to chafa.
- Increased chafa image resolution for clearer terminal previews.
- Added an image container border and spacing.
