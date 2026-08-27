## 0.5.4 — Mermaid runtime crash fix

- Fixed a runtime crash in Mermaid sequence-diagram rendering caused by calling `splitlines()` on a Rich `Text` object.
- Mermaid note boxes now remain a single Rich renderable and work with current Rich/Textual versions.
- No existing Markdown, image, math, Mermaid, code, list, color, or TUI features were removed.

## 0.5.2 — Final terminal rendering fixes

- Native terminal rendering for Mermaid `sequenceDiagram` with participants, messages and notes.
- Improved Mermaid flowchart rendering with labelled edges and safe source fallback.
- Improved terminal math rendering for Greek letters, operators, scripts, roots, integrals, sums, products, limits, matrices and stacked display fractions.
- Unsupported math/diagram syntax now falls back to readable source instead of breaking the document.
- Fixed indented code blocks using the same readable syntax palette as fenced blocks.
- Added automatic shebang language detection for indented Bash/Python blocks.
- Expanded syntax aliases for Python, Bash, JavaScript, TypeScript, Java, C/C++, C#, Go, Rust, Kotlin, Ruby, PHP, PowerShell, YAML, JSON, SQL, XML/HTML, Dockerfile and more.
- Preserved local and remote image loading, persistent remote image cache, native terminal image support and chafa fallback.
- Preserved search, scrolling, TOC, watch/reload, Rich markup, alerts, tables, task lists, footnotes, definition lists, details and copy actions.
- Expanded `examples/ghmd-demo.md` with sequence diagrams, advanced math, matrices and fallback tests.

## 0.5.3

- Improved terminal math layout for fractions, roots, integrals, limits, sums, products, binomials and matrices.
- Added optional Matplotlib math rendering for GitHub-like graphical terminal output when a compatible image backend is available.
- Improved Mermaid sequence-diagram parsing and layout, including correct `Server-->>Client` handling, participant boxes, lifelines, notes and groups.
- Added safe fallback for unsupported Mermaid syntax.
- Fixed Rich markup handling for ANSI/named colors, RGB/hex colors, backgrounds, combined styles and emoji codes.
- Preserved nested-list indentation and existing GFM/image/code features.
- Added comprehensive regression sections to `examples/ghmd-demo.md`.
