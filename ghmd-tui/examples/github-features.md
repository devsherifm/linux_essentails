# ghmd GitHub / Markdown Feature Showcase

This is the fast smoke-test document. For the complete feature reference run:

```bash
ghmd examples/markdown-a2z.md
```

## Core Markdown

**Bold**, *italic*, ***bold italic***, ~~strike~~, `inline code`, ==highlight==, ++insert++.

## Links

[GitHub](https://github.com) and <https://example.com>.

## Task list

- [x] Markdown parsed
- [x] GFM rendered
- [ ] Try the full A-Z showcase

## Alert

> [!TIP]
> Press `t` for TOC, `/` for search, `g` / `G` for top / bottom.

## Table

| Feature | Status | Notes |
| :--- | :---: | ---: |
| GFM | ✅ | Core |
| Math | ✅ | Terminal fallback |
| Mermaid | ✅ | Flowchart renderer |
| Images | ✅ | Native / chafa |

## Mermaid

```mermaid
graph LR
    Markdown --> Parser
    Parser --> Renderer
    Renderer --> TUI
```

## Math

Inline $E = mc^2$.

$$
\\int_0^\\infty e^{-x} dx = 1
$$

## Details

<details>
<summary>Click to expand</summary>

This is rendered with Textual's native collapsible widget.

</details>

## Code

```python
print("ghmd is running")
```
