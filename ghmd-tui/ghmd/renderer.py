from __future__ import annotations

import html
import re
import hashlib
import mimetypes
import os
import shutil
import subprocess
import tempfile
import urllib.error
import urllib.request
import urllib.parse
from pathlib import Path
from typing import Iterable

from rich.console import Group
from rich.style import Style
from rich.emoji import Emoji
from rich.panel import Panel
from rich.markup import render as render_markup
from rich.syntax import Syntax
from rich.table import Table
from rich.text import Text
from textual.app import ComposeResult
from textual.widget import Widget
from textual.containers import VerticalScroll
from textual.widgets import Collapsible, Static

# Import before the Textual app starts. textual-image probes the terminal when
# its image renderables are imported, which is why this import intentionally
# lives at module scope.
try:  # Optional but recommended for real terminal graphics.
    from textual_image.widget import Image as TerminalImage
except Exception:  # pragma: no cover - optional dependency / old Termux install
    TerminalImage = None

from .parser import Document, Heading
from .theme import Theme


ALERTS = {
    "NOTE": ("💡", "alert_note"),
    "TIP": ("💡", "alert_tip"),
    "IMPORTANT": ("❗", "alert_important"),
    "WARNING": ("⚠", "alert_warning"),
    "CAUTION": ("🛑", "alert_caution"),
}


def _link_style(style: str | None, href: str | None) -> str | None:
    if href:
        return f"{style} link {href}" if style else f"link {href}"
    return style


def _append(out: Text, content: str, style: str | None = None, href: str | None = None) -> None:
    if content:
        out.append(content, style=_link_style(style, href))


RICH_TAG_RE = re.compile(r"\[(?:/?(?:bold|dim|italic|underline|strike|reverse|blink|link|not|on|[a-z][a-z0-9_ -]*))[^\]]*\]", re.I)
RICH_EMOJI_RE = re.compile(r"(?<!\w):(?:[a-z0-9_+\-]+):")


def _looks_like_rich_markup(content: str) -> bool:
    if not content:
        return False
    if re.search(r"\[(?:/?)(?:bold|dim|italic|underline|strike|reverse|blink|link|on|[a-z][a-z0-9_ -]*)(?:\s+[^\]]+)?\]", content, re.I):
        return True
    return bool(RICH_EMOJI_RE.search(content))


def _manual_rich_markup(content: str) -> Text | None:
    """Parse common Rich markup while preserving arbitrary Rich color names/hex."""
    if not _looks_like_rich_markup(content):
        return None
    out = Text()
    stack: list[Style] = []
    pos = 0
    tag_re = re.compile(r"\[(/?)([^\]]+)\]")
    try:
        for m in tag_re.finditer(content):
            if m.start() > pos:
                chunk = content[pos:m.start()]
                if stack:
                    out.append(Emoji.replace(chunk), style=stack[-1])
                else:
                    out.append(Emoji.replace(chunk))
            closing, spec = m.group(1), m.group(2).strip()
            if closing:
                if stack:
                    stack.pop()
            else:
                # Do not steal Markdown links, task markers or bracketed prose.
                if spec.startswith(("http://", "https://")) or ")" in spec and "(" in spec:
                    out.append(m.group(0))
                else:
                    stack.append(Style.parse(spec))
            pos = m.end()
        if pos < len(content):
            chunk = Emoji.replace(content[pos:])
            out.append(chunk, style=stack[-1] if stack else None)
        return out
    except Exception:
        return None


def _render_rich_markup(content: str, force: bool = False) -> Text | None:
    if not (force or _looks_like_rich_markup(content)):
        return None
    try:
        rendered = render_markup(content)
        if isinstance(rendered, Text):
            return rendered
    except Exception:
        pass
    return _manual_rich_markup(content)


_SUPERS = str.maketrans(
    "0123456789+-=()nABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
    "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿᴬᴮᶜᴰᴱᶠᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᑫᴿˢᵀᵁⱽᵂˣʸᶻᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖᑫʳˢᵗᵘᵛʷˣʸᶻ",
)
_SUBS = str.maketrans(
    "0123456789+-=()aeoxhABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
    "₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎ₐₑₒₓₕABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
)

# One-backslash LaTeX commands. The old implementation used two literal
# backslashes, so commands such as ``\\alpha`` and ``\\int`` were left as raw
# text by the terminal renderer.
_MATH_REPLACEMENTS = {
    r"\infty": "∞", r"\sum": "∑", r"\prod": "∏", r"\int": "∫",
    r"\oint": "∮", r"\partial": "∂", r"\nabla": "∇", r"\sqrt": "√",
    r"\le": "≤", r"\leq": "≤", r"\ge": "≥", r"\geq": "≥", r"\ne": "≠",
    r"\neq": "≠", r"\approx": "≈", r"\sim": "∼", r"\equiv": "≡",
    r"\times": "×", r"\cdot": "·", r"\pm": "±", r"\mp": "∓", r"\div": "÷",
    r"\ast": "∗", r"\star": "⋆", r"\circ": "∘", r"\bullet": "•",
    r"\rightarrow": "→", r"\to": "→", r"\longrightarrow": "⟶",
    r"\leftarrow": "←", r"\gets": "←", r"\leftrightarrow": "↔",
    r"\Rightarrow": "⇒", r"\Longrightarrow": "⟹", r"\Leftrightarrow": "⇔",
    r"\longleftrightarrow": "⟷", r"\Longleftrightarrow": "⟺",
    r"\mapsto": "↦", r"\hookrightarrow": "↪", r"\hookleftarrow": "↩",
    r"\to": "→", r"\iff": "⇔", r"\implies": "⇒",
    r"\uparrow": "↑", r"\downarrow": "↓", r"\updownarrow": "↕",
    r"\in": "∈", r"\notin": "∉", r"\subset": "⊂", r"\subseteq": "⊆",
    r"\supset": "⊃", r"\supseteq": "⊇", r"\cup": "∪", r"\cap": "∩",
    r"\emptyset": "∅", r"\forall": "∀", r"\exists": "∃", r"\neg": "¬",
    r"\land": "∧", r"\lor": "∨", r"\therefore": "∴", r"\because": "∵",
    r"\ldots": "…", r"\cdots": "⋯", r"\vdots": "⋮", r"\ddots": "⋱",
    r"\ell": "ℓ", r"\hbar": "ℏ", r"\Re": "ℜ", r"\Im": "ℑ",
    r"\alpha": "α", r"\beta": "β", r"\gamma": "γ", r"\delta": "δ",
    r"\epsilon": "ε", r"\varepsilon": "ϵ", r"\zeta": "ζ", r"\eta": "η",
    r"\theta": "θ", r"\vartheta": "ϑ", r"\iota": "ι", r"\kappa": "κ",
    r"\lambda": "λ", r"\mu": "μ", r"\nu": "ν", r"\xi": "ξ", r"\pi": "π",
    r"\varpi": "ϖ", r"\rho": "ρ", r"\sigma": "σ", r"\tau": "τ", r"\upsilon": "υ",
    r"\phi": "φ", r"\varphi": "ϕ", r"\chi": "χ", r"\psi": "ψ", r"\omega": "ω",
    r"\Gamma": "Γ", r"\Delta": "Δ", r"\Theta": "Θ", r"\Lambda": "Λ", r"\Xi": "Ξ",
    r"\aleph": "ℵ", r"\wp": "℘", r"\Re": "ℜ", r"\Im": "ℑ",
    r"\Pi": "Π", r"\Sigma": "Σ", r"\Upsilon": "Υ", r"\Phi": "Φ", r"\Psi": "Ψ", r"\Omega": "Ω",
    r"\left": "", r"\right": "", r"\middle": "",
    r"\,": " ", r"\;": " ", r"\!": "", r"\quad": "  ", r"\qquad": "    ",
    r"\%": "%", r"\#": "#", r"\_": "_", r"\&": "&", r"\$": "$",
}


def _balanced_brace(text: str, start: int) -> tuple[str, int] | None:
    if start >= len(text) or text[start] != "{":
        return None
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start + 1:i], i + 1
    return None


def _latex_group(value: str, start: int) -> tuple[str, int] | None:
    return _balanced_brace(value, start)


def _scriptify(value: str, table: dict[int, int], fallback: str) -> str:
    if not value:
        return ""
    # Keep Greek/math glyphs readable. Unicode has only a partial set of
    # superscript/subscript letters, so mixed expressions become ^(...) / (...)
    # rather than silently turning into broken-looking characters.
    if "^" in value or "_" in value:
        value = _math_normalize(value)
    translated = value.translate(table)
    if any(ch.isalpha() and table.get(ord(ch), ord(ch)) == ord(ch) for ch in value):
        return fallback + "(" + value + ")"
    return translated


def _replace_latex_structures(value: str) -> str:
    """Convert common TeX structures to terminal-safe Unicode.

    The terminal has no universal TeX layout protocol, so ghmd deliberately
    uses Unicode math symbols plus real stacked fractions for display math.
    Unknown commands are preserved by the final fallback path.
    """
    # Fractions are temporarily represented with a private marker so that the
    # block renderer can later lay them out vertically.
    pattern = re.compile(r"\\(?:dfrac|tfrac|frac)\s*")
    while True:
        m = pattern.search(value)
        if not m:
            break
        a = _latex_group(value, m.end())
        if not a:
            break
        b = _latex_group(value, a[1])
        if not b:
            break
        numerator, _ = a
        denominator, end = b
        marker = f"⟦FRAC:{numerator}¦{denominator}⟧"
        value = value[:m.start()] + marker + value[end:]

    # Binomial coefficients are readable in one line in a terminal.
    pattern = re.compile(r"\\binom\s*")
    while True:
        m = pattern.search(value)
        if not m:
            break
        a = _latex_group(value, m.end())
        if not a:
            break
        b = _latex_group(value, a[1])
        if not b:
            break
        value = value[:m.start()] + f"C({a[0]},{b[0]})" + value[b[1]:]

    # Roots. Support optional index: \sqrt[3]{x}.
    pattern = re.compile(r"\\sqrt\s*")
    while True:
        m = pattern.search(value)
        if not m:
            break
        pos = m.end()
        index = None
        if pos < len(value) and value[pos] == "[":
            close = value.find("]", pos + 1)
            if close != -1:
                index = value[pos + 1:close]
                pos = close + 1
        a = _latex_group(value, pos)
        if not a:
            break
        root, end = a
        rendered = (f"√{root}" if re.fullmatch(r"[A-Za-z0-9π∞]+", root.strip()) else f"√({root})") if not index else f"{index}√({root})"
        value = value[:m.start()] + rendered + value[end:]

    # Replace symbols before converting scripts so bounds such as _{\infty}
    # become the proper ∞ glyph rather than superscript letters.
    for key, replacement in sorted(_MATH_REPLACEMENTS.items(), key=lambda item: -len(item[0])):
        value = value.replace(key, replacement)

    # Superscript/subscript groups, including common TeX bounds.
    value = re.sub(r"\^\{([^{}]+)\}", lambda m: _scriptify(m.group(1), _SUPERS, "^"), value)
    value = re.sub(r"_\{([^{}]+)\}", lambda m: _scriptify(m.group(1), _SUBS, "_"), value)
    value = re.sub(r"\^([0-9A-Za-z+\-=])", lambda m: _scriptify(m.group(1), _SUPERS, "^"), value)
    value = re.sub(r"_([0-9A-Za-z+\-=])", lambda m: _scriptify(m.group(1), _SUBS, "_"), value)
    return value


def _math_normalize(expr: str) -> str:
    """Normalize common TeX/Markdown math into terminal-safe Unicode.

    This intentionally keeps layout markers for fractions and large operators;
    ``render_math`` turns those markers into real multi-line terminal layout.
    Unknown TeX commands are preserved instead of being silently corrupted.
    """
    value = expr.strip()
    value = re.sub(r"\\\\(?=[A-Za-z])", r"\\", value)
    value = value.replace("\\\n", " ")

    # Matrix environments first, because they contain TeX row separators.
    def matrix_repl(match: re.Match[str]) -> str:
        env, body = match.group(1), match.group(2).strip()
        rows = []
        for row in re.split(r"\\\\", body):
            row = re.sub(r"\s*&\s*", "   ", row.strip())
            if row:
                rows.append(row)
        left, right = {
            "pmatrix": ("(", ")"), "bmatrix": ("[", "]"),
            "Bmatrix": ("{", "}"), "vmatrix": ("|", "|"),
            "Vmatrix": ("‖", "‖"), "matrix": ("[", "]"),
        }.get(env, ("[", "]"))
        return f"⟦MATRIX:{'¦'.join(rows)}⟧" if rows else f"{left}{right}"

    value = re.sub(
        r"\\begin\{(pmatrix|bmatrix|Bmatrix|vmatrix|Vmatrix|matrix)\}(.*?)\\end\{\1\}",
        matrix_repl, value, flags=re.S,
    )

    # Fractions and binomials are retained as structural markers.
    frac = re.compile(r"\\(?:dfrac|tfrac|frac)\s*")
    while True:
        m = frac.search(value)
        if not m:
            break
        a = _latex_group(value, m.end())
        if not a:
            break
        b = _latex_group(value, a[1])
        if not b:
            break
        value = value[:m.start()] + f"⟦FRAC:{a[0]}¦{b[0]}⟧" + value[b[1]:]

    binom = re.compile(r"\\binom\s*")
    while True:
        m = binom.search(value)
        if not m:
            break
        a = _latex_group(value, m.end())
        if not a:
            break
        b = _latex_group(value, a[1])
        if not b:
            break
        value = value[:m.start()] + f"⟦BINOM:{a[0]}¦{b[0]}⟧" + value[b[1]:]

    # Roots, including optional nth-root indices.
    root = re.compile(r"\\sqrt\s*")
    while True:
        m = root.search(value)
        if not m:
            break
        pos = m.end()
        index = ""
        if pos < len(value) and value[pos] == "[":
            close = value.find("]", pos + 1)
            if close != -1:
                index = value[pos + 1:close]
                pos = close + 1
        a = _latex_group(value, pos)
        if not a:
            break
        rendered = f"{index}√({a[0]})" if index else f"√({a[0]})"
        value = value[:m.start()] + rendered + value[a[1]:]

    for key, replacement in sorted(_MATH_REPLACEMENTS.items(), key=lambda item: -len(item[0])):
        value = value.replace(key, replacement)

    # Common functions/operators that are better displayed than raw commands.
    value = re.sub(r"\\(sin|cos|tan|cot|sec|csc|log|ln|exp|max|min|lim)\b", r"\1", value)
    value = re.sub(r"\\text\s*\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\mathrm\s*\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\mathbf\s*\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\mathit\s*\{([^{}]*)\}", r"\1", value)
    value = re.sub(r"\\operatorname\s*\{([^{}]*)\}", r"\1", value)

    # Scripts. Keep unknown letters readable rather than producing bogus glyphs.
    value = re.sub(r"\^\{([^{}]+)\}", lambda m: _scriptify(m.group(1), _SUPERS, "^"), value)
    value = re.sub(r"_\{([^{}]+)\}", lambda m: _scriptify(m.group(1), _SUBS, "_"), value)
    value = re.sub(r"\^([0-9A-Za-z+\-=])", lambda m: _scriptify(m.group(1), _SUPERS, "^"), value)
    value = re.sub(r"_([0-9A-Za-z+\-=])", lambda m: _scriptify(m.group(1), _SUBS, "_"), value)
    value = value.replace("{", "").replace("}", "")
    value = re.sub(r"\s+", " ", value).strip()
    return value


def _unicode_math(expr: str) -> str:
    return _math_normalize(expr)


def _fraction_markers(value: str) -> list[tuple[str, str]]:
    return [(m.group(1), m.group(2)) for m in re.finditer(r"⟦FRAC:(.*?)¦(.*?)⟧", value)]


def _format_fraction(num: str, den: str, width: int = 0) -> list[str]:
    n = _math_normalize(num)
    d = _math_normalize(den)
    w = max(len(n), len(d), width, 1)
    return [n.center(w), "─" * w, d.center(w)]


def _format_matrix(rows: str) -> list[str]:
    parsed = [_math_normalize(r) for r in rows.split("¦") if r.strip()]
    if not parsed:
        return ["[]"]
    width = max(len(r) for r in parsed)
    return ["⎛ " + parsed[0].ljust(width) + " ⎞"] + [
        ("⎜ " + r.ljust(width) + " ⎟") for r in parsed[1:-1]
    ] + (["⎝ " + parsed[-1].ljust(width) + " ⎠"] if len(parsed) > 1 else [])


def _layout_large_operator(expr: str) -> list[str] | None:
    """Create a three-line terminal layout for integrals/sums/products/limits."""
    s = expr.strip()
    # Integral: \int_{a}^{b} f(x) dx
    m = re.match(r"^(?:∫|\\int)\s*(?:_\{([^{}]+)\}|_([^\s^]+))?\s*(?:\^\{([^{}]+)\}|\^([^\s]+))?\s*(.*)$", s)
    if m and (m.group(1) or m.group(2) or m.group(3) or m.group(4)):
        lo = _math_normalize(m.group(1) or m.group(2) or "")
        hi = _math_normalize(m.group(3) or m.group(4) or "")
        rest = _math_normalize(m.group(5))
        return [f"  {hi}", f"∫ {rest}", f"  {lo}"]

    for symbol, command in (("∑", "sum"), ("∏", "prod")):
        m = re.match(rf"^{re.escape(symbol)}\s*(?:_\{{([^{{}}]+)\}}|_([^\s^]+))?\s*(?:\^\{{([^{{}}]+)\}}|\^([^\s]+))?\s*(.*)$", s)
        if m and (m.group(1) or m.group(2) or m.group(3) or m.group(4)):
            lo = _math_normalize(m.group(1) or m.group(2) or "")
            hi = _math_normalize(m.group(3) or m.group(4) or "")
            rest = _math_normalize(m.group(5))
            return [f"  {hi}", f"{symbol} {rest}", f"  {lo}"]

    # Limit with a subscript: \lim_{x\to\infty} f(x)
    m = re.match(r"^(?:lim|\\lim)\s*(?:_\{([^{}]+)\}|_([^\s]+))\s*(.*)$", s)
    if m:
        condition = _math_normalize(m.group(1) or m.group(2) or "")
        rest = _math_normalize(m.group(3))
        return ["lim", f"  {rest}", f"  {condition}"]
    return None


def _replace_structural_math_line(value: str) -> list[str]:
    """Render fractions/matrices inside an equation without debug placeholders."""
    if "⟦MATRIX:" in value:
        m = re.search(r"⟦MATRIX:(.*?)⟧", value)
        if m:
            before, after = value[:m.start()].rstrip(), value[m.end():].lstrip()
            mat = _format_matrix(m.group(1))
            if before:
                mat = [before + " " + mat[0]] + [" " * (len(before) + 1) + x for x in mat[1:]]
            if after:
                mat[-1] += " " + after
            return mat

    m = re.search(r"⟦(?:FRAC|BINOM):(.*?)¦(.*?)⟧", value)
    if m:
        kind = "BINOM" if m.group(0).startswith("⟦BINOM:") else "FRAC"
        if kind == "BINOM":
            num, den = m.group(1), m.group(2)
            replacement = f"({num} over {den})"
            return [_math_normalize(value[:m.start()] + replacement + value[m.end():])]
        frac = _format_fraction(m.group(1), m.group(2))
        before = _math_normalize(value[:m.start()].rstrip())
        after = _math_normalize(value[m.end():].lstrip())
        if before:
            pad = " " * (len(before) + 1)
            lines = [before + " " + frac[0], pad + frac[1], pad + frac[2]]
        else:
            lines = frac
        if after:
            lines[-1] += " " + after
        return lines
    return [_math_normalize(value)]


def _math_image_path(expr: str, block: bool, theme: Theme) -> Path | None:
    """Optionally render math with Matplotlib's TeX mathtext engine.

    This is intentionally optional. When matplotlib is unavailable (common on
    Termux), ghmd uses the Unicode terminal typesetter instead of failing.
    """
    if not shutil.which("python3") and not shutil.which("python"):
        return None
    try:
        import matplotlib
        matplotlib.use("Agg")
        from matplotlib.mathtext import math_to_image
    except Exception:
        return None
    cache = Path(os.environ.get("GHMD_MATH_CACHE", Path.home() / ".cache" / "ghmd" / "math"))
    try:
        cache.mkdir(parents=True, exist_ok=True)
        key = hashlib.sha256((expr + "|" + str(block) + "|" + theme.name).encode()).hexdigest()[:24]
        target = cache / f"{key}.png"
        if target.exists() and target.stat().st_size > 0:
            return target
        latex = expr.strip()
        if not latex:
            return None
        # Matplotlib mathtext expects one math expression. It handles the
        # fractions, roots, integrals, sums, products, Greek letters and matrix
        # constructs used by the demo without requiring a system TeX install.
        wrapped = latex if latex.startswith("$") else f"${latex}$"
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            temp_name = tmp.name
        try:
            math_to_image(wrapped, temp_name, dpi=180, format="png",
                          color="#67e8f9" if theme.name == "dark" else "#0969da")
            Path(temp_name).replace(target)
        finally:
            Path(temp_name).unlink(missing_ok=True)
        return target if target.exists() else None
    except Exception:
        try:
            Path(temp_name).unlink(missing_ok=True)
        except Exception:
            pass
        return None


def _can_show_math_image(image_mode: str) -> bool:
    if image_mode == "off":
        return False
    if image_mode in {"native", "chafa"}:
        return True
    return _native_image_terminal() or shutil.which("chafa") is not None


def render_math(expr: str, block: bool, theme: Theme) -> Text:
    """Render math as readable terminal typesetting, with safe fallback."""
    raw = expr.strip()
    if not raw:
        return Text("", style=theme.muted)
    normalized = _math_normalize(raw)
    if block:
        # Detect bounds before normalization converts TeX scripts to Unicode.
        op = _layout_large_operator(raw)
        if op:
            expanded = _replace_structural_math_line(op[1])
            if len(expanded) == 1:
                lines = op
            else:
                lines = [op[0]] + expanded + [op[-1]]
            return Text("\n".join(lines), style="bold bright_cyan")
        lines = _replace_structural_math_line(normalized)
        return Text("\n".join(lines), style="bold bright_cyan")
    # Inline math should stay compact; structural fractions use a Unicode slash
    # fallback rather than injecting a three-line block into prose.
    normalized = re.sub(r"⟦FRAC:(.*?)¦(.*?)⟧", r"(\1)/(\2)", normalized)
    normalized = re.sub(r"⟦BINOM:(.*?)¦(.*?)⟧", r"C(\1,\2)", normalized)
    normalized = re.sub(r"⟦MATRIX:(.*?)⟧", lambda m: "[" + "; ".join(m.group(1).split("¦")) + "]", normalized)
    return Text(normalized, style="bold bright_cyan")

def _mermaid_node(raw: str, labels: dict[str, str]) -> str:
    raw = raw.strip().strip(";")
    m = re.match(r"^([A-Za-z0-9_:-]+)(.*)$", raw)
    if not m:
        key = raw
        labels.setdefault(key, key)
        return key
    key, suffix = m.groups()
    label = None
    for opener, closer in (("[[", "]]"), ("((", "))"), ("{{", "}}"),
                           ("[", "]"), ("(", ")"), ("{", "}"),
                           ("[/", "/]"), ("[\\", "\\]")):
        if suffix.startswith(opener) and suffix.endswith(closer):
            label = suffix[len(opener):-len(closer)]
            break
    labels[key] = (label or key).strip('"\' ')
    return key


def _mermaid_image_path(source: str, theme: Theme) -> Path | None:
    """Use Mermaid CLI when installed for a true SVG/PNG-style diagram.

    Native parsing remains the default fallback, so ghmd never requires Node.js.
    """
    command = shutil.which("mmdc") or shutil.which("mmdc.cmd")
    if not command:
        return None
    cache = Path(os.environ.get("GHMD_MERMAID_CACHE", Path.home() / ".cache" / "ghmd" / "mermaid"))
    try:
        cache.mkdir(parents=True, exist_ok=True)
        key = hashlib.sha256((source + "|" + theme.name).encode()).hexdigest()[:24]
        target = cache / f"{key}.png"
        if target.exists() and target.stat().st_size > 0:
            return target
        source_path = cache / f"{key}.mmd"
        source_path.write_text(source, encoding="utf-8")
        result = subprocess.run(
            [command, "-i", str(source_path), "-o", str(target), "-b", "transparent", "-t", theme.name],
            capture_output=True, text=True, timeout=45,
        )
        if result.returncode == 0 and target.exists() and target.stat().st_size > 0:
            return target
    except (OSError, subprocess.SubprocessError):
        pass
    return None


def _mermaid_sequence(source: str, theme: Theme) -> Panel:
    """Render Mermaid sequence diagrams as a terminal-native sequence chart."""
    lines = [x.strip() for x in source.splitlines() if x.strip() and not x.strip().startswith("%%")]
    participants: list[str] = []
    labels: dict[str, str] = {}
    events: list[tuple] = []

    if not lines or not lines[0].lower().startswith("sequencediagram"):
        return Panel(Text(source.rstrip(), style=theme.muted), title="Mermaid • source fallback", border_style="cyan")

    def add_participant(key: str, label: str | None = None) -> None:
        key = key.strip().strip(";")
        if key.endswith("-"):
            key = key.rstrip("-")
        if key and key not in participants:
            participants.append(key)
        if key:
            labels[key] = (label or labels.get(key) or key).strip().strip('"\'')

    for line in lines[1:]:
        m = re.match(r"^(?:participant|actor)\s+([^\s]+)(?:\s+as\s+(.+))?$", line, re.I)
        if m:
            add_participant(m.group(1), m.group(2)); continue

        m = re.match(r"^Note\s+(over|left of|right of)\s+([^:]+):\s*(.*)$", line, re.I)
        if m:
            target, note = m.group(2).strip(), m.group(3).strip()
            targets = [x.strip().rstrip("-") for x in target.split(",")]
            for t in targets:
                add_participant(t)
            events.append(("note", m.group(1).lower(), targets, note))
            continue

        # Important: match the complete Mermaid arrow token first. This avoids
        # turning ``Server-->>Client`` into the accidental participants
        # ``Server-`` and ``Client-`` seen in earlier versions.
        m = re.match(r"^([^\s:]+?)\s*(-->>|->>|--x|->x|-->|->|--)\s*([^\s:]+?)\s*:\s*(.*)$", line)
        if m:
            src, arrow, dst, msg = m.groups()
            src, dst = src.rstrip("-"), dst.rstrip("-")
            add_participant(src); add_participant(dst)
            events.append(("msg", src, dst, arrow, msg.strip()))
            continue

        # Mermaid control/group syntax: render as a labelled separator rather
        # than dropping it.
        m = re.match(r"^(loop|alt|else|opt|par|and|critical|break|rect)\b\s*(.*)$", line, re.I)
        if m:
            events.append(("group", m.group(1), m.group(2).strip())); continue
        if line.lower() == "end":
            events.append(("end",)); continue

    if not participants:
        return Panel(Text(source.rstrip(), style=theme.muted), title="Mermaid • sequenceDiagram • source fallback", border_style="cyan")

    # A two-party diagram gets enough horizontal space to look like the GitHub
    # rendering while still fitting normal laptop/Termux terminals.
    col_width = max(14, min(28, max(len(labels.get(p, p)) for p in participants) + 6))
    gap = 8
    total = len(participants) * col_width + max(0, len(participants) - 1) * gap
    centers = [i * (col_width + gap) + col_width // 2 for i in range(len(participants))]
    index = {p: i for i, p in enumerate(participants)}
    out: list[Text] = []

    def boxed(label: str) -> list[str]:
        label = label[:col_width - 2]
        return ["┌" + "─" * (col_width - 2) + "┐", "│" + label.center(col_width - 2) + "│", "└" + "─" * (col_width - 2) + "┘"]

    # Participant header boxes.
    for row in range(3):
        chars = [" "] * total
        for i, p in enumerate(participants):
            b = boxed(labels.get(p, p))[row]
            left = i * (col_width + gap)
            chars[left:left + col_width] = list(b)
        out.append(Text("".join(chars), style="bold bright_cyan"))
    out.append(Text(" ".join("│".center(col_width) for _ in participants), style="cyan"))

    def lifelines() -> str:
        chars = [" "] * total
        for c in centers:
            if c < total:
                chars[c] = "│"
        return "".join(chars)

    def message(src: str, dst: str, arrow: str, msg: str) -> str:
        if src not in index or dst not in index:
            return msg
        a, b = centers[index[src]], centers[index[dst]]
        chars = list(lifelines())
        if a == b:
            chars[a] = "↻"
            return "".join(chars) + f"  {msg}"
        lo, hi = sorted((a, b))
        for x in range(lo + 1, hi):
            chars[x] = "-" if arrow.startswith("--") else "─"
        if b > a:
            chars[hi] = "◀" if arrow.endswith("x") else "▶"
        else:
            chars[lo] = "▶" if arrow.endswith("x") else "◀"
        # Put the message above the line, matching the visual rhythm of Mermaid.
        label = f" {msg} "
        mid = (lo + hi) // 2
        start = max(lo + 1, min(mid - len(label) // 2, hi - len(label)))
        for j, ch in enumerate(label):
            if start + j < hi:
                chars[start + j] = ch
        return "".join(chars)

    for event in events:
        kind = event[0]
        if kind == "msg":
            _, src, dst, arrow, msg = event
            out.append(Text(message(src, dst, arrow, msg), style="bright_white"))
            out.append(Text(lifelines(), style="cyan"))
        elif kind == "note":
            _, placement, targets, note = event
            if placement == "over" and targets:
                first = index.get(targets[0], 0)
                last = index.get(targets[-1], first)
                left = first * (col_width + gap)
                right = last * (col_width + gap) + col_width
                width = max(12, right - left)
                label = note[:max(1, width - 4)]
                box = "┌" + "─" * max(1, width - 2) + "┐\n│" + label.center(max(1, width - 2)) + "│\n└" + "─" * max(1, width - 2) + "┘"
                out.append(Text(box, style="yellow"))
            else:
                out.append(Text(f"▸ {note}", style="yellow"))
            out.append(Text(lifelines(), style="cyan"))
        elif kind == "group":
            title = (event[1] + (f" {event[2]}" if event[2] else "")).strip()
            out.append(Text(f"╞═ {title} " + "═" * max(0, total - len(title) - 4), style="yellow"))
        elif kind == "end":
            out.append(Text("╰" + "─" * max(0, total - 2) + "╯", style="dim"))
            out.append(Text(lifelines(), style="cyan"))

    # Bottom participant boxes.
    out.append(Text("".join("│".center(col_width) + (" " * gap if i < len(participants)-1 else "") for i in range(len(participants))), style="cyan"))
    for row in range(3):
        chars = [" "] * total
        for i, p in enumerate(participants):
            b = boxed(labels.get(p, p))[row]
            left = i * (col_width + gap)
            chars[left:left + col_width] = list(b)
        out.append(Text("".join(chars), style="bold bright_cyan"))

    return Panel(Group(*out), title="Mermaid • sequenceDiagram", border_style="cyan", padding=(0, 1))

def render_mermaid(source: str, theme: Theme) -> Panel:
    """Render common Mermaid diagrams with native terminal fallbacks."""
    raw_lines = [line.strip() for line in source.splitlines()
                 if line.strip() and not line.strip().startswith("%%")]
    if not raw_lines:
        return Panel(Text("(empty Mermaid diagram)", style=theme.muted), title="Mermaid", border_style="cyan")
    if raw_lines[0].lower().startswith("sequencediagram"):
        return _mermaid_sequence(source, theme)

    header = raw_lines[0]
    direction = "TB"
    m = re.match(r"^(?:graph|flowchart)\s+([A-Za-z]+)", header, re.I)
    if m:
        direction = m.group(1).upper()
        raw_lines = raw_lines[1:]
    direction = {"TD": "TB", "TDIR": "TB", "BT": "BT", "RL": "RL"}.get(direction, direction)

    labels: dict[str, str] = {}
    edges: list[tuple[str, str, str]] = []
    unsupported: list[str] = []

    # Mermaid edges may carry labels: A -->|HTTPS| B or A -- HTTPS --> B.
    edge_re = re.compile(r"^(.+?)\s*(?:-->|---|==>|-\.->)\s*(?:\|([^|]+)\|\s*)?(.+)$")
    edge_text_re = re.compile(r"^(.+?)\s+--\s+(.+?)\s+-->\s+(.+)$")
    for line in raw_lines:
        low = line.lower()
        if low.startswith(("subgraph ", "end", "classdef ", "class ", "style ", "click ", "link ", "pie ", "gitgraph")):
            unsupported.append(line); continue
        m2 = edge_text_re.match(line)
        if m2:
            left, label, right = m2.groups()
        else:
            m2 = edge_re.match(line)
            if not m2:
                if re.match(r"^[A-Za-z0-9_:-]+(?:\[.*\]|\(.*\)|\{.*\}|\(\(.*\)\))$", line):
                    _mermaid_node(line, labels); continue
                unsupported.append(line); continue
            left, label, right = m2.groups()
        a = _mermaid_node(left, labels); b = _mermaid_node(right, labels)
        edges.append((a, b, label or ""))

    if not edges:
        return Panel(Text(source.rstrip(), style=theme.muted), title=f"Mermaid • {direction} • source fallback", border_style="cyan")

    adjacency: dict[str, list[tuple[str, str]]] = {}
    indegree: dict[str, int] = {}
    order: list[str] = []
    for a, b, label in edges:
        if a not in order: order.append(a)
        if b not in order: order.append(b)
        adjacency.setdefault(a, []).append((b, label))
        indegree.setdefault(a, 0); indegree[b] = indegree.get(b, 0) + 1

    def node_text(key: str) -> str:
        return f"[ {labels.get(key, key)} ]"

    lines: list[Text] = []
    if direction in {"LR", "RL"}:
        sep = " ◀── " if direction == "RL" else " ──▶ "
        starts = [n for n in order if indegree.get(n, 0) == 0] or order[:1]
        seen: set[str] = set()
        for start in starts:
            chain = [start]; cur = start
            while len(adjacency.get(cur, [])) == 1 and adjacency[cur][0][0] not in chain:
                cur = adjacency[cur][0][0]; chain.append(cur)
            seen.update(chain)
            lines.append(Text(sep.join(node_text(n) for n in chain), style="bold bright_white"))
        for node in order:
            if node not in seen: lines.append(Text(node_text(node), style="bold bright_white"))
    else:
        starts = [n for n in order if indegree.get(n, 0) == 0] or order[:1]
        seen: set[str] = set()
        for start in starts:
            current = start
            while current and current not in seen:
                seen.add(current); children = adjacency.get(current, [])
                lines.append(Text(node_text(current), style="bold bright_white"))
                if len(children) == 1:
                    label = children[0][1]
                    lines.append(Text(f"       │{(' ' + label + ' ') if label else ''}", style="cyan"))
                    lines.append(Text("       ▼", style="bold cyan")); current = children[0][0]
                elif children:
                    lines.append(Text("    ┌──┴──┐", style="bold cyan"))
                    lines.append(Text("    ▼     ▼", style="bold cyan"))
                    lines.append(Text("  " + "   ".join(node_text(c) for c, _ in children), style="bold bright_white"))
                    seen.update(c for c, _ in children); current = ""
                else: current = ""

    body = Group(*lines)
    if unsupported:
        body = Group(body, Text("\nUnsupported Mermaid syntax — source fallback:", style="bold yellow"),
                     Text("\n".join(unsupported), style=theme.muted))
    return Panel(body, title=f"Mermaid • {direction}", border_style="cyan")

def render_definition_list(tokens, start: int, theme: Theme, rich_markup: bool | None = None):
    end = find_matching(tokens, start, "dl_open", "dl_close")
    groups: list[Text] = []
    searchable: list[str] = []
    term = ""
    for i in range(start + 1, end):
        tok = tokens[i]
        if tok.type == "dt_open":
            continue
        if tok.type == "dd_open":
            continue
        if tok.type == "inline":
            rendered = inline_rich(tok, theme, rich_markup)
            # A dt inline is followed by dd_open; use token map from immediate
            # preceding opening token when available.
            prev = tokens[i - 1].type if i else ""
            if prev == "dt_open":
                term = tok.content
                groups.append(Text("◆ " + term, style="bold bright_cyan"))
            else:
                groups.append(Text("   ↳ ") + rendered)
            searchable.append(tok.content)
    return Group(*groups), end, " ".join(searchable)

def render_extended_text(content: str, base_style: str | None = None) -> Text | None:
    """Render small inline extensions that are intentionally not parser plugins."""
    if not re.search(r"==.+?==|\+\+.+?\+\+", content):
        return None
    out = Text()
    pos = 0
    pattern = re.compile(r"(==(.+?)==|\+\+(.+?)\+\+)")
    for match in pattern.finditer(content):
        if match.start() > pos:
            out.append(content[pos:match.start()], style=base_style)
        if match.group(2) is not None:
            out.append(match.group(2), style="black on yellow")
        else:
            out.append(match.group(3), style="underline green")
        pos = match.end()
    if pos < len(content):
        out.append(content[pos:], style=base_style)
    return out


def inline_rich(token, theme: Theme, rich_markup: bool | None = None) -> Text:
    out = Text()
    if token is None:
        return out

    children = token.children or []
    style_stack: list[str] = []
    link_stack: list[str] = []
    html_style_stack: list[str] = []

    for child in children:
        typ = child.type

        if typ.endswith("_open"):
            if typ == "link_open":
                link_stack.append(child.attrGet("href") or "")
            elif typ in {"strong_open", "em_open", "s_open", "sub_open", "sup_open", "mark_open", "ins_open", "del_open"}:
                style_stack.append(typ[:-5])
            continue

        if typ.endswith("_close"):
            if typ == "link_close":
                if link_stack:
                    link_stack.pop()
            elif typ in {"strong_close", "em_close", "s_close", "sub_close", "sup_close", "mark_close", "ins_close", "del_close"}:
                kind = typ[:-6]
                if kind in style_stack:
                    style_stack.remove(kind)
            continue

        style_parts: list[str] = []
        if "strong" in style_stack:
            style_parts.append("bold")
        if "em" in style_stack:
            style_parts.append("italic")
        if "s" in style_stack or "del" in style_stack:
            style_parts.append("strike")
        if "mark" in style_stack:
            style_parts.append("black on yellow")
        if "ins" in style_stack:
            style_parts.append("underline green")
        if "kbd" in html_style_stack:
            style_parts.append("bold on #30363d")
        if "b" in html_style_stack or "strong" in html_style_stack:
            style_parts.append("bold")
        if "i" in html_style_stack or "em" in html_style_stack:
            style_parts.append("italic")
        if "del" in html_style_stack or "s" in html_style_stack:
            style_parts.append("strike")
        if "mark" in html_style_stack:
            style_parts.append("black on yellow")
        if "u" in html_style_stack:
            style_parts.append("underline")
        if "sub" in html_style_stack:
            style_parts.append("cyan")
        if "sup" in html_style_stack:
            style_parts.append("cyan")

        href = link_stack[-1] if link_stack else None
        style = " ".join(style_parts) if style_parts else None

        if typ == "code_inline":
            _append(out, child.content, theme.code, href)
        elif typ == "text":
            content = child.content
            if "sub" in style_stack or "sub" in html_style_stack:
                content = content.translate(_SUBS)
            elif "sup" in style_stack or "sup" in html_style_stack:
                content = content.translate(_SUPERS)
            # Rich markup is opt-in by flag, but also auto-detected for Rich
            # documentation/demo files. Markdown links such as [text](url)
            # are not mistaken for Rich markup because they have no closing
            # Rich tag.
            if not href and not style:
                force_markup = rich_markup is True
                rendered = _render_rich_markup(content, force=force_markup)
                if rendered is not None:
                    out.append(rendered)
                    continue
                extended = render_extended_text(content, style)
                if extended is not None:
                    out.append(extended)
                    continue
            _append(out, content, style, href)
        elif typ == "softbreak":
            _append(out, " ")
        elif typ == "hardbreak":
            _append(out, "\n")
        elif typ == "html_inline":
            raw = child.content
            tag = re.match(r"<\s*(/?)\s*([A-Za-z0-9]+)", raw)
            if tag:
                name = tag.group(2).lower()
                if name in {"br", "hr"}:
                    _append(out, "\n")
                elif name in {"mark", "u", "ins", "del", "s", "sub", "sup", "kbd", "b", "strong", "i", "em"}:
                    if tag.group(1):
                        if name in html_style_stack:
                            html_style_stack.remove(name)
                    else:
                        html_style_stack.append(name)
                else:
                    _append(out, strip_html(raw), style, href)
            else:
                _append(out, strip_html(raw), style, href)
        elif typ == "autolink":
            auto_href = child.attrGet("href") or child.content
            _append(out, child.content, theme.link, auto_href)
        elif typ == "image":
            alt = child.content or child.attrGet("alt") or "image"
            src = child.attrGet("src") or ""
            _append(out, f"🖼 {alt}", theme.link, src or None)
        elif typ in {"sub", "sup"}:
            value = child.content.translate(_SUBS if typ == "sub" else _SUPERS)
            _append(out, value, "cyan")
        elif typ in {"mark", "ins", "del"}:
            style_map = {"mark": "black on yellow", "ins": "underline green", "del": "strike red"}
            _append(out, child.content, style_map[typ], href)
        elif typ in {"math_inline", "math"}:
            out.append(render_math(child.content, False, theme))
        elif typ == "abbr":
            title = child.attrGet("title") or (child.meta or {}).get("title") or ""
            _append(out, child.content, "underline cyan", href)
        elif typ == "footnote_ref":
            meta = child.meta or {}
            _append(out, f"[{meta.get('id', '')}]", "bold cyan")
        else:
            _append(out, child.content, style, href)

    return out


def strip_html(value: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", value))


def _cell_alignment(open_token) -> str:
    style = open_token.attrGet("style") or ""
    match = re.search(r"text-align\s*:\s*(left|center|right)", style, re.I)
    return match.group(1).lower() if match else "left"


def render_table(tokens, start: int, theme: Theme, rich_markup: bool | None = None) -> tuple[Table, int, str]:
    table = Table(
        show_header=True,
        box=None,
        padding=(0, 1),
        expand=True,
        border_style=theme.table_border,
    )

    rows: list[tuple[bool, list[Text], list[str]]] = []
    searchable: list[str] = []
    i = start + 1
    current_section = ""

    while i < len(tokens):
        tok = tokens[i]
        if tok.type == "table_close":
            break
        if tok.type == "thead_open":
            current_section = "head"
        elif tok.type == "tbody_open":
            current_section = "body"
        elif tok.type == "tr_open":
            cells: list[Text] = []
            aligns: list[str] = []
            j = i + 1
            while j < len(tokens) and tokens[j].type != "tr_close":
                if tokens[j].type in {"th_open", "td_open"}:
                    open_token = tokens[j]
                    inline = tokens[j + 1] if j + 1 < len(tokens) else None
                    cell = inline_rich(inline, theme, rich_markup)
                    cells.append(cell)
                    searchable.append(cell.plain)
                    aligns.append(_cell_alignment(open_token))
                j += 1
            rows.append((current_section == "head", cells, aligns))
            i = j
        i += 1

    if rows:
        header_row = next((row for row in rows if row[0]), rows[0])
        headers = header_row[1]
        header_aligns = header_row[2]

        for idx, header in enumerate(headers):
            align = header_aligns[idx] if idx < len(header_aligns) else "left"
            table.add_column(
                header,
                header_style=theme.table_header,
                justify=align,
                overflow="fold",
            )

        for is_header, cells, _aligns in rows:
            if is_header:
                continue
            vals = list(cells[: len(headers)])
            vals += [Text()] * (len(headers) - len(vals))
            table.add_row(*vals)

    return table, i, " ".join(searchable)


def render_code(token, width: int | None = None, theme: Theme | None = None):
    """Render fenced code with safe language detection and a dark background.

    Rich's Syntax parser can raise for an unknown fence language. A Markdown
    reader should never crash because a document says `````some-new-language`````.
    Unknown languages therefore fall back to plain readable terminal text.
    """
    raw_info = token.info.strip()
    content = token.content.rstrip("\n")
    lexer = raw_info.split()[0].lower() if raw_info else ""
    if not lexer:
        first = content.splitlines()[0].strip() if content.splitlines() else ""
        if first.startswith("#!") and "python" in first:
            lexer = "python"
        elif first.startswith("#!") and any(x in first for x in ("bash", "sh", "zsh")):
            lexer = "bash"
        else:
            lexer = "text"
    aliases = {
        "sh": "bash", "shell": "bash", "zsh": "bash", "console": "console",
        "cmd": "batch", "bat": "batch", "ps": "powershell", "ps1": "powershell",
        "yml": "yaml", "md": "markdown", "mdown": "markdown", "mkdown": "markdown",
        "py": "python", "py3": "python", "python3": "python",
        "js": "javascript", "jsx": "javascript", "ts": "typescript", "tsx": "typescript",
        "c++": "cpp", "cc": "cpp", "h++": "cpp", "hpp": "cpp",
        "c#": "csharp", "cs": "csharp", "golang": "go", "rs": "rust",
        "kt": "kotlin", "kts": "kotlin", "rb": "ruby", "php3": "php",
        "psql": "postgresql", "postgres": "postgresql",
        "docker": "dockerfile", "dockerfile": "dockerfile",
        "nginx": "nginx", "toml": "toml", "ini": "ini", "conf": "ini",
        "jsonc": "json", "http": "http", "xml": "xml", "html": "html",
        "mermaid": "text", "mmd": "text",
    }
    lexer = aliases.get(lexer, lexer)
    try:
        syntax_theme = "github-dark" if theme is None or theme.name == "dark" else "github-light"
        bg = "#161b22" if theme is None or theme.name == "dark" else "#f6f8fa"
        return Syntax(
            content, lexer, theme=syntax_theme, line_numbers=False,
            word_wrap=False, code_width=width, background_color=bg, padding=0,
        )
    except Exception:
        # Plain Text is the final safety net for unknown/unsupported languages.
        return Text(content, style=("#e6edf3 on #161b22" if theme is None or theme.name == "dark" else "#24292f on #f6f8fa"))


def _is_remote_url(src: str) -> bool:
    return bool(re.match(r"^https?://", src, re.I))


def resolve_image(src: str, base_dir: Path | None) -> Path | None:
    """Resolve a local Markdown image path."""
    if not src or _is_remote_url(src):
        return None
    clean = src.split("#", 1)[0].split("?", 1)[0]
    p = Path(clean).expanduser()
    if not p.is_absolute() and base_dir:
        p = base_dir / p
    try:
        p = p.resolve()
    except OSError:
        return None
    return p if p.exists() and p.is_file() else None


def _remote_cache_dir() -> Path:
    root = os.environ.get("GHMD_IMAGE_CACHE")
    path = Path(root).expanduser() if root else Path.home() / ".cache" / "ghmd" / "images"
    path.mkdir(parents=True, exist_ok=True)
    return path


def download_remote_image(src: str) -> Path | None:
    """Download an http(s) Markdown image into a small persistent cache."""
    if not _is_remote_url(src):
        return None
    clean = src.split("#", 1)[0]
    digest = hashlib.sha256(clean.encode("utf-8")).hexdigest()[:24]
    suffix = Path(urllib.parse.urlparse(clean).path).suffix.lower()
    if suffix not in {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tiff", ".avif"}:
        suffix = ".img"
    target = _remote_cache_dir() / f"{digest}{suffix}"
    if target.exists() and target.stat().st_size > 0:
        return target
    try:
        request = urllib.request.Request(
            clean,
            headers={
                "User-Agent": "ghmd/0.5.1 (+https://github.com/)",
                "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
            },
        )
        with urllib.request.urlopen(request, timeout=15) as response:
            content_type = response.headers.get_content_type()
            data = response.read(20 * 1024 * 1024 + 1)
        if len(data) > 20 * 1024 * 1024 or not content_type.startswith("image/"):
            return None
        if suffix == ".img":
            guessed = mimetypes.guess_extension(content_type) or ".img"
            target = target.with_suffix(guessed)
        target.write_bytes(data)
        return target
    except (OSError, urllib.error.URLError, ValueError):
        return None


def resolve_image_source(src: str, base_dir: Path | None, allow_remote: bool = True) -> Path | None:
    local = resolve_image(src, base_dir)
    if local:
        return local
    if allow_remote:
        return download_remote_image(src)
    return None


def _native_image_terminal() -> bool:
    """Only use terminal graphics when the terminal is known to support them."""
    if os.environ.get("KITTY_WINDOW_ID") or os.environ.get("WEZTERM_PANE"):
        return True
    term = os.environ.get("TERM", "").lower()
    program = os.environ.get("TERM_PROGRAM", "").lower()
    return "kitty" in term or program in {"kitty", "wezterm"}


def chafa_image(path: Path, max_width: int = 120, max_height: int = 40) -> Text:
    """High-quality terminal fallback for Ubuntu/GNOME/Windows Terminal/Termux."""
    if shutil.which("chafa"):
        try:
            result = subprocess.run(
                [
                    "chafa",
                    "--format", "symbols",
                    "--colors", "full",
                    "--size", f"{max_width}x{max_height}",
                    str(path),
                ],
                capture_output=True,
                text=True,
                timeout=15,
                check=True,
            )
            return Text.from_ansi(result.stdout.rstrip("\n"))
        except Exception:
            pass
    return Text(
        f"🖼 {path.name}\nInstall chafa for terminal image rendering.",
        style="bold",
    )


def image_widget(path: Path, alt: str = "", mode: str = "auto"):
    return SafeTerminalImage(path, alt, mode=mode)

def render_gfm_alert(tokens, start: int, theme: Theme, rich_markup: bool | None = None) -> tuple[Group, int, str]:
    """Render markdown-it-py's native GFM alert token sequence."""
    end = find_matching(tokens, start, "alert_open", "alert_close")
    kind = ((tokens[start].meta or {}).get("kind") or "NOTE").upper()
    icon, color_attr = ALERTS.get(kind, ("ℹ", "alert_note"))
    title_text = kind.title()
    body_lines: list[Text] = []
    searchable: list[str] = []
    for j in range(start + 1, end):
        tok = tokens[j]
        if tok.type == "inline":
            if j > start and tokens[j - 1].type == "alert_title_open":
                title_text = tok.content.strip() or title_text
            else:
                body_lines.append(inline_rich(tok, theme, rich_markup))
                searchable.append(tok.content)
    title = Text(f"{icon} {title_text}", style=f"bold {getattr(theme, color_attr)}")
    if body_lines:
        group = Group(title, Text("\n").join(body_lines))
    else:
        group = Group(title)
    return group, end, " ".join(searchable + [title_text])


def alert_from_tokens(tokens, i: int):
    if tokens[i].type != "blockquote_open":
        return None
    for j in range(i + 1, min(i + 10, len(tokens))):
        if tokens[j].type == "inline":
            content = tokens[j].content.strip()
            m = re.match(r"^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*", content, re.I)
            return m.group(1).upper() if m else None
    return None


def find_matching(tokens, start: int, open_type: str, close_type: str) -> int:
    depth = 0
    for i in range(start, len(tokens)):
        if tokens[i].type == open_type:
            depth += 1
        elif tokens[i].type == close_type:
            depth -= 1
            if depth == 0:
                return i
    return len(tokens) - 1


def render_list(tokens, theme: Theme, rich_markup: bool | None = None) -> tuple[Group, str]:
    lines: list[Text] = []
    searchable: list[str] = []
    depth = 0
    ordered_next: list[int] = []
    pending_task: bool | None = None

    for tok in tokens:
        if tok.type in {"bullet_list_open", "ordered_list_open"}:
            depth += 1
            if tok.type == "ordered_list_open":
                start = tok.attrGet("start")
                ordered_next.append(int(start) if start else 1)
            continue

        if tok.type in {"bullet_list_close", "ordered_list_close"}:
            depth = max(0, depth - 1)
            if tok.type == "ordered_list_close" and ordered_next:
                ordered_next.pop()
            continue

        if tok.type == "list_item_open":
            meta = tok.meta or {}
            pending_task = bool(meta["checked"]) if "checked" in meta else None
            continue

        if tok.type == "inline":
            indent = "  " * max(depth - 1, 0)
            if pending_task is not None:
                prefix = "☑ " if pending_task else "☐ "
                content = re.sub(r"^\[[ xX]\]\s+", "", tok.content)
                rendered = inline_rich(tok, theme, rich_markup)
                # Remove literal task marker from the rendered text if the parser
                # left it there; using the rendered token keeps inline formatting.
                if content != tok.content:
                    rendered = inline_rich(tok, theme, rich_markup)
                lines.append(Text(indent + prefix) + rendered)
                searchable.append(content)
                pending_task = None
                continue

            if ordered_next and depth > 0:
                prefix = f"{ordered_next[-1]}. "
                ordered_next[-1] += 1
            else:
                prefix = "• "
            lines.append(Text(indent + prefix) + inline_rich(tok, theme, rich_markup))
            searchable.append(tok.content)

    return Group(*lines), " ".join(searchable)


class SafeTerminalImage(Widget):
    """Image widget with a guaranteed text fallback if native rendering fails."""

    def __init__(self, path: Path, alt: str = "", mode: str = "auto", **kwargs):
        self.path = path
        self.alt = alt or path.name
        self.mode = mode
        super().__init__(classes="image", **kwargs)

    def compose(self) -> ComposeResult:
        use_native = self.mode == "native" or (self.mode == "auto" and _native_image_terminal())
        if use_native and TerminalImage is not None:
            try:
                yield TerminalImage(str(self.path), width="90%", height="auto")
                return
            except Exception:
                pass
        if self.mode != "native":
            yield Static(chafa_image(self.path), classes="image-fallback")
        else:
            yield Static(Text(f"🖼 {self.alt}\nNative image rendering is unavailable in this terminal.", style="bold"), classes="image-fallback")


class MarkdownDocument(VerticalScroll):
    """Render a parsed Markdown document into stable Textual widgets."""

    def __init__(self, document: Document, theme: Theme, image_mode: str = "auto", rich_markup: bool | None = None, **kwargs):
        kwargs.setdefault("can_focus", True)
        super().__init__(**kwargs)
        self.document = document
        self.md_theme = theme
        self.base_dir = document.path.parent if document.path else None
        self.image_mode = image_mode
        self.rich_markup = rich_markup
        self.heading_widgets: dict[str, Static] = {}
        self.search_targets: list[tuple[str, Widget]] = []

    def compose(self) -> ComposeResult:
        yield from self._compose_document()

    def _register(self, widget: Widget, text: str) -> Widget:
        if text.strip():
            self.search_targets.append((text.strip(), widget))
        return widget

    def _compose_document(self) -> Iterable[Widget]:
        self.heading_widgets = {}
        self.search_targets = []
        tokens = self.document.tokens
        i = 0

        while i < len(tokens):
            token = tokens[i]

            if token.type == "heading_open":
                inline = tokens[i + 1] if i + 1 < len(tokens) else None
                heading = next((h for h in self.document.headings if h.token_index == i), None)
                text = inline_rich(inline, self.md_theme, self.rich_markup)
                level = int(token.tag[1:])
                glyphs = ("◆", "▰", "▸", "◇", "•", "·")
                glyph = glyphs[level - 1]
                rendered = Text(f"{glyph}  ", style=self.md_theme.heading[level - 1]) + text
                widget = Static(rendered, classes=f"heading h{level}")
                if heading:
                    widget.id = f"h-{heading.anchor}"
                    self.heading_widgets[heading.anchor] = widget
                yield self._register(widget, heading.text if heading else text.plain)
                i += 3
                continue

            if token.type == "paragraph_open":
                inline = tokens[i + 1] if i + 1 < len(tokens) else None
                # A paragraph containing a single image is a real image block.
                children = inline.children if inline else []
                image_children = [c for c in children if c.type == "image"]
                non_image_children = [c for c in children if c.type not in {"image", "softbreak"}]
                if image_children and not non_image_children and self.image_mode != "off":
                    img = image_children[0]
                    src = img.attrGet("src") or ""
                    alt = img.content or img.attrGet("alt") or "image"
                    resolved = resolve_image_source(src, self.base_dir)
                    if resolved:
                        yield image_widget(resolved, alt, self.image_mode)
                        i += 3
                        continue
                widget = Static(inline_rich(inline, self.md_theme, self.rich_markup), classes="paragraph")
                yield self._register(widget, inline.content if inline else "")
                i += 3
                continue

            if token.type == "fence":
                info = token.info.strip().split()[0].lower() if token.info.strip() else ""
                if info in {"mermaid", "mmd"}:
                    diagram_image = _mermaid_image_path(token.content, self.md_theme) if _can_show_math_image(self.image_mode) else None
                    if diagram_image:
                        widget = image_widget(diagram_image, "Mermaid diagram", self.image_mode)
                    else:
                        widget = Static(render_mermaid(token.content, self.md_theme), classes="diagram mermaid")
                elif info in {"math", "latex", "tex"}:
                    math_image = _math_image_path(token.content, True, self.md_theme) if _can_show_math_image(self.image_mode) else None
                    if math_image:
                        widget = image_widget(math_image, "math equation", self.image_mode)
                    else:
                        widget = Static(Panel(render_math(token.content, True, self.md_theme), title="Math", border_style="cyan"), classes="mathblock")
                else:
                    widget = Static(render_code(token, theme=self.md_theme), classes="codeblock")
                yield self._register(widget, token.content)
                i += 1
                continue

            if token.type in {"math_block", "dollarmath_block", "texmath_block"}:
                math_image = _math_image_path(token.content, True, self.md_theme) if _can_show_math_image(self.image_mode) else None
                if math_image:
                    widget = image_widget(math_image, "math equation", self.image_mode)
                else:
                    widget = Static(Panel(render_math(token.content, True, self.md_theme), title="Math", border_style="cyan"), classes="mathblock")
                yield self._register(widget, token.content)
                i += 1
                continue

            if token.type == "code_block":
                # Indented code must use the same readable palette as fenced code.
                # Applying a bare foreground style on a transparent Textual widget
                # caused white-on-white selection/background combinations.
                code = token.content.rstrip("\n")
                widget = Static(
                    render_code(type("CodeToken", (), {"info": "", "content": code})(), theme=self.md_theme),
                    classes="codeblock",
                )
                yield self._register(widget, token.content)
                i += 1
                continue

            if token.type == "hr":
                yield Static(Text("━" * 72, style=self.md_theme.muted), classes="rule")
                i += 1
                continue

            if token.type == "dl_open":
                rendered, end, searchable = render_definition_list(tokens, i, self.md_theme, self.rich_markup)
                widget = Static(Panel(rendered, title="Definition List", border_style="cyan"), classes="definition-list")
                yield self._register(widget, searchable)
                i = end + 1
                continue

            if token.type == "table_open":
                table, end, searchable = render_table(tokens, i, self.md_theme, self.rich_markup)
                widget = Static(table, classes="table")
                yield self._register(widget, searchable)
                i = end + 1
                continue

            if token.type == "alert_open":
                rendered_group, end, searchable = render_gfm_alert(tokens, i, self.md_theme, self.rich_markup)
                kind = ((token.meta or {}).get("kind") or "NOTE").lower()
                widget = Static(rendered_group, classes=f"alert alert-{kind}")
                yield self._register(widget, searchable)
                i = end + 1
                continue

            if token.type == "blockquote_open":
                alert = alert_from_tokens(tokens, i)
                end = find_matching(tokens, i, "blockquote_open", "blockquote_close")
                if alert:
                    content: list[str] = []
                    first_inline = True
                    for j in range(i + 1, end):
                        if tokens[j].type == "inline":
                            value = tokens[j].content
                            if first_inline:
                                value = re.sub(
                                    r"^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*",
                                    "",
                                    value,
                                    flags=re.I,
                                )
                                first_inline = False
                            if value:
                                content.append(value)
                    icon, color_attr = ALERTS[alert]
                    title = Text(f"{icon} {alert}", style=f"bold {getattr(self.md_theme, color_attr)}")
                    body = Text("\n".join(content), style=self.md_theme.base)
                    widget = Static(Group(title, body), classes=f"alert alert-{alert.lower()}")
                    yield self._register(widget, " ".join(content))
                    i = end + 1
                    continue

                lines = [tokens[j] for j in range(i + 1, end) if tokens[j].type == "inline"]
                body = Text("│ ", style=self.md_theme.quote)
                for idx, line in enumerate(lines):
                    if idx:
                        body.append("\n│ ", style=self.md_theme.quote)
                    body.append(inline_rich(line, self.md_theme, self.rich_markup))
                widget = Static(body, classes="blockquote")
                yield self._register(widget, " ".join(line.content for line in lines))
                i = end + 1
                continue

            if token.type in {"bullet_list_open", "ordered_list_open"}:
                end_type = "bullet_list_close" if token.type == "bullet_list_open" else "ordered_list_close"
                end = find_matching(tokens, i, token.type, end_type)
                rendered, searchable = render_list(tokens[i + 1 : end], self.md_theme, self.rich_markup)
                widget = Static(rendered, classes="list")
                yield self._register(widget, searchable)
                i = end + 1
                continue

            if token.type == "image":
                src = token.attrGet("src") or ""
                alt = token.content or token.attrGet("alt") or "image"
                resolved = resolve_image_source(src, self.base_dir)
                if resolved and self.image_mode != "off":
                    yield image_widget(resolved, alt, self.image_mode)
                else:
                    widget = Static(Text(f"🖼 {alt}", style="bold"), classes="image")
                    yield self._register(widget, alt)
                i += 1
                continue

            if token.type == "footnote_block_open":
                end = find_matching(tokens, i, "footnote_block_open", "footnote_block_close")
                lines: list[Text] = []
                searchable: list[str] = []
                for j in range(i + 1, end):
                    tok = tokens[j]
                    if tok.type == "inline":
                        lines.append(inline_rich(tok, self.md_theme, self.rich_markup))
                        searchable.append(tok.content)
                title = Text("Footnotes", style="bold bright_cyan")
                content = Group(title, *lines) if lines else Group(title)
                widget = Static(content, classes="footnotes")
                yield self._register(widget, " ".join(searchable))
                i = end + 1
                continue

            if token.type == "html_block":
                raw = token.content.strip()
                if re.search(r"<details\b", raw, re.I):
                    # GitHub-style <details> may be split across several Markdown
                    # tokens. Gather until the closing tag so a single Collapsible
                    # widget is created and the following tokens aren't left behind.
                    parts = [raw]
                    j = i + 1
                    while j < len(tokens) and not re.search(r"</details>\s*$", parts[-1], re.I):
                        part = tokens[j]
                        if part.type == "html_block":
                            parts.append(part.content.strip())
                            if re.search(r"</details>\s*$", parts[-1], re.I):
                                j += 1
                                break
                        elif part.type == "inline":
                            parts.append(part.content.strip())
                        j += 1
                    combined = "\n".join(parts)
                    summary_match = re.search(r"<summary[^>]*>(.*?)</summary>", combined, re.I | re.S)
                    summary = strip_html(summary_match.group(1)) if summary_match else "Details"
                    body_match = re.search(r"</summary>(.*?)(?:</details>|$)", combined, re.I | re.S)
                    body = strip_html(body_match.group(1)) if body_match else ""
                    open_default = bool(re.search(r"<details\b[^>]*\bopen\b", combined, re.I))
                    child = Static(body.strip() or "", classes="details-body")
                    yield Collapsible(
                        child,
                        title=summary,
                        collapsed=not open_default,
                        collapsed_symbol="▸",
                        expanded_symbol="▾",
                        classes="details",
                    )
                    if body.strip():
                        self.search_targets.append((body.strip(), child))
                    i = max(j, i + 1)
                    continue
                else:
                    cleaned = strip_html(raw)
                    if cleaned:
                        widget = Static(cleaned, classes="html")
                        yield self._register(widget, cleaned)
                i += 1
                continue

            if token.type in {
                "bullet_list_close",
                "ordered_list_close",
                "paragraph_close",
                "heading_close",
                "blockquote_close",
                "table_close",
                "thead_open",
                "thead_close",
                "tbody_open",
                "tbody_close",
                "tr_open",
                "tr_close",
                "th_open",
                "th_close",
                "td_open",
                "td_close",
                "alert_title_open",
                "alert_title_close",
                "alert_close",
                "footnote_open",
                "footnote_close",
                "footnote_anchor",
                "footnote_block_close",
                "dl_close",
                "dt_open",
                "dt_close",
                "dd_open",
                "dd_close",
                "math_block",
                "dollarmath_block",
                "texmath_block",
                "front_matter",
            }:
                i += 1
                continue

            if token.type == "front_matter":
                raw = token.content.strip()
                widget = Static(Panel(Text(raw, style="dim"), title="Front Matter", border_style="magenta"), classes="front-matter")
                yield self._register(widget, raw)
                i += 1
                continue

            if token.type == "inline":
                widget = Static(inline_rich(token, self.md_theme, self.rich_markup), classes="inline")
                yield self._register(widget, token.content)

            i += 1

    def plain_text(self) -> str:
        """Return a readable, copy-friendly representation of the rendered document."""
        lines: list[str] = []
        tokens = self.document.tokens
        i = 0
        while i < len(tokens):
            tok = tokens[i]
            if tok.type == "heading_open":
                inline = tokens[i + 1] if i + 1 < len(tokens) else None
                if inline:
                    lines.append(inline_rich(inline, self.md_theme, self.rich_markup).plain)
                i += 3; continue
            if tok.type == "paragraph_open":
                inline = tokens[i + 1] if i + 1 < len(tokens) else None
                if inline:
                    lines.append(inline_rich(inline, self.md_theme, self.rich_markup).plain)
                i += 3; continue
            if tok.type == "fence":
                info = tok.info.strip()
                if info:
                    lines.append(f"```{info}")
                lines.extend(tok.content.rstrip("\n").splitlines())
                if info:
                    lines.append("```")
                i += 1; continue
            if tok.type == "code_block":
                lines.extend(tok.content.rstrip("\n").splitlines())
                i += 1; continue
            if tok.type in {"math_block", "dollarmath_block", "texmath_block"}:
                math_plain = _math_normalize(tok.content)
                math_plain = re.sub(r"⟦FRAC:(.*?)¦(.*?)⟧", r"(\1)/(\2)", math_plain)
                lines.append(math_plain)
                i += 1; continue
            if tok.type == "hr":
                lines.append("─" * 40); i += 1; continue
            if tok.type == "inline":
                # Inline tokens not consumed by their block handlers (tables,
                # blockquotes, list items, footnotes) still contribute readable text.
                value = inline_rich(tok, self.md_theme, self.rich_markup).plain
                if value.strip(): lines.append(value)
            elif tok.type == "html_block":
                value = strip_html(tok.content).strip()
                if value: lines.extend(value.splitlines())
            elif tok.type == "front_matter":
                lines.extend(tok.content.strip().splitlines())
            i += 1
        return "\n".join(lines).strip()

    async def update_document(self, document: Document) -> None:
        self.document = document
        self.base_dir = document.path.parent if document.path else None
        async with self.batch():
            await self.remove_children()
            await self.mount_all(self._compose_document())
