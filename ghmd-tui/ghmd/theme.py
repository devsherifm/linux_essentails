from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Theme:
    name: str
    base: str
    heading: tuple[str, str, str, str, str, str]
    link: str
    code: str
    quote: str
    table_header: str
    table_border: str
    muted: str
    alert_note: str
    alert_tip: str
    alert_important: str
    alert_warning: str
    alert_caution: str


THEMES = {
    "dark": Theme(
        name="dark",
        base="white",
        heading=(
            "bold bright_white",
            "bold cyan",
            "bold bright_cyan",
            "bold green",
            "bold yellow",
            "dim bold",
        ),
        link="bold bright_blue underline",
        code="on #20252b #e6edf3",
        quote="#8b949e",
        table_header="bold #e6edf3",
        table_border="#30363d",
        muted="dim #8b949e",
        alert_note="#1f6feb",
        alert_tip="#238636",
        alert_important="#8957e5",
        alert_warning="#9e6a03",
        alert_caution="#da3633",
    ),
    "light": Theme(
        name="light",
        base="black",
        heading=("bold black", "bold blue", "bold cyan", "bold green", "bold dark_orange", "dim bold"),
        link="blue underline",
        code="on #f0f0f0 #24292f",
        quote="#57606a",
        table_header="bold #24292f",
        table_border="#8c959f",
        muted="dim #57606a",
        alert_note="#0969da",
        alert_tip="#1a7f37",
        alert_important="#8250df",
        alert_warning="#9a6700",
        alert_caution="#cf222e",
    ),
}
