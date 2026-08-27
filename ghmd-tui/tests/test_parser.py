from pathlib import Path

from ghmd.parser import GFMParser


def test_headings_and_tables():
    doc = GFMParser().parse(
        "# One\n\n## Two\n\n| A | B |\n| --- | ---: |\n| x | 2 |\n"
    )
    assert [h.level for h in doc.headings] == [1, 2]
    assert any(t.type == "table_open" for t in doc.tokens)


def test_gfm_tasklist_and_alert():
    doc = GFMParser().parse(
        "- [x] Done\n- [ ] Todo\n\n> [!WARNING]\n> Be careful.\n"
    )
    task_items = [t for t in doc.tokens if t.type == "list_item_open" and t.meta]
    assert task_items
    assert task_items[0].meta.get("checked") is True
    assert task_items[1].meta.get("checked") is False
    assert any(t.type == "blockquote_open" for t in doc.tokens)


def test_footnote():
    doc = GFMParser().parse("Note[^1]\n\n[^1]: Footnote")
    assert any(t.type == "footnote_ref" for t in doc.tokens)


def test_heading_anchors_are_unique():
    doc = GFMParser().parse("# Same\n\n# Same\n")
    assert [h.anchor for h in doc.headings] == ["same", "same-1"]


def test_rich_markup_is_auto_detected():
    from ghmd.parser import GFMParser
    from ghmd.renderer import inline_rich
    from ghmd.theme import THEMES

    doc = GFMParser().parse("[bold red]ERROR[/bold red] and [bold green]:white_check_mark: OK[/bold green]")
    inline = next(t for t in doc.tokens if t.type == "inline")
    rendered = inline_rich(inline, THEMES["dark"])
    assert rendered.plain == "ERROR and ✅ OK"
    assert any(span.style == "bold red" for span in rendered.spans)
    assert any(span.style == "bold green" for span in rendered.spans)


def test_markdown_link_is_not_treated_as_rich_markup():
    from ghmd.parser import GFMParser
    from ghmd.renderer import inline_rich
    from ghmd.theme import THEMES

    doc = GFMParser().parse("[GitHub](https://github.com)")
    inline = next(t for t in doc.tokens if t.type == "inline")
    rendered = inline_rich(inline, THEMES["dark"])
    assert rendered.plain == "GitHub"
    assert any(span.style and "link" in span.style for span in rendered.spans)


def test_extended_math_fallback_is_readable():
    from ghmd.renderer import _unicode_math

    value = _unicode_math(r"E = mc^2 + \alpha + \frac{a}{b} + \int_0^\infty e^{-x} dx")
    assert "α" in value
    assert "∞" in value
    assert "∫" in value
    assert "a" in value and "b" in value


def test_mermaid_simple_flowchart_is_renderable():
    from ghmd.renderer import render_mermaid
    from ghmd.theme import THEMES

    panel = render_mermaid("graph TD\nA[Start] --> B[Finish]", THEMES["dark"])
    assert "Mermaid" in str(panel.title)


def test_mermaid_sequence_diagram_is_renderable():
    from ghmd.renderer import render_mermaid
    from ghmd.theme import THEMES

    panel = render_mermaid(
        """sequenceDiagram
participant Client
participant Server
Client->>Server: SYN
Server-->>Client: SYN-ACK
""",
        THEMES["dark"],
    )
    assert "sequenceDiagram" in str(panel.title)


def test_advanced_math_preserves_symbols_and_fraction():
    from ghmd.renderer import _unicode_math

    value = _unicode_math(r"\\int_{0}^{\\infty} e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}")
    assert "∫" in value
    assert "∞" in value
    assert "√" in value
    assert "FRAC" in value
