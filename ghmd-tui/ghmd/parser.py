from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from importlib import import_module

from markdown_it import MarkdownIt
from mdit_py_plugins.footnote import footnote_plugin


@dataclass(frozen=True)
class Heading:
    level: int
    text: str
    token_index: int
    anchor: str


@dataclass(frozen=True)
class Document:
    source: str
    path: Path | None
    tokens: list
    headings: list[Heading]


_OPTIONAL_PLUGINS = (
    ("mdit_py_plugins.subscript", "sub_plugin"),
    ("mdit_py_plugins.superscript", "superscript_plugin"),
    ("mdit_py_plugins.deflist", "deflist_plugin"),
    ("mdit_py_plugins.abbr", "abbr_plugin"),
    ("mdit_py_plugins.mark", "mark_plugin"),
    ("mdit_py_plugins.ins", "ins_plugin"),
    ("mdit_py_plugins.emoji", "emoji_plugin"),
    ("mdit_py_plugins.dollarmath", "dollarmath_plugin"),
    ("mdit_py_plugins.texmath", "texmath_plugin"),
    ("mdit_py_plugins.front_matter", "front_matter_plugin"),
    ("mdit_py_plugins.attrs", "attrs_plugin"),
    ("mdit_py_plugins.amsmath", "amsmath_plugin"),
    ("mdit_py_plugins.admon", "admon_plugin"),
    ("mdit_py_plugins.field_list", "fieldlist_plugin"),
    ("mdit_py_plugins.colon_fence", "colon_fence_plugin"),
    ("mdit_py_plugins.section_ref", "section_ref_plugin"),
)


class GFMParser:
    """GitHub/GFM-oriented Markdown parser with safe common extensions.

    The baseline is markdown-it-py's current GFM-like preset. Optional plugins
    are loaded when present so ghmd remains installable on lightweight systems
    such as Termux even if a plugin is absent.
    """

    def __init__(self) -> None:
        # mdit-py-plugins >= 0.6 provides a composite GFM plugin which keeps
        # task lists, alerts and GFM autolinks in one well-tested configuration.
        # Keep the markdown-it-py preset as a fallback for lightweight installs.
        self.md = MarkdownIt(
            "gfm-like2",
            {
                "html": True,
                "linkify": True,
                "breaks": False,
            },
        )
        self.enabled_plugins: list[str] = []
        try:
            from mdit_py_plugins.gfm import gfm_plugin
            self.md.use(gfm_plugin, dollarmath=True, front_matter=True)
            self.enabled_plugins.append("gfm")
        except Exception:
            # The core preset still gives tables/strikethrough/task lists/alerts
            # on markdown-it-py versions which do not ship the composite plugin.
            pass
        self.md.use(footnote_plugin)
        self.enabled_plugins.append("footnote")
        for module_name, symbol in _OPTIONAL_PLUGINS:
            if "gfm" in self.enabled_plugins and module_name in {
                "mdit_py_plugins.dollarmath",
                "mdit_py_plugins.front_matter",
            }:
                continue
            try:
                module = import_module(module_name)
                plugin = getattr(module, symbol)
                self.md.use(plugin)
                self.enabled_plugins.append(symbol.removesuffix("_plugin"))
            except Exception:
                # Plugin availability must never prevent the core reader from
                # opening a Markdown document.
                continue

    def parse(self, source: str, path: Path | None = None) -> Document:
        tokens = self.md.parse(source)
        headings: list[Heading] = []
        seen: dict[str, int] = {}

        for i, token in enumerate(tokens):
            if token.type != "heading_open":
                continue
            level = int(token.tag[1:])
            inline = tokens[i + 1] if i + 1 < len(tokens) else None
            text = self._plain_inline(inline) if inline else ""
            base = slugify(text)
            count = seen.get(base, 0)
            seen[base] = count + 1
            anchor = base if count == 0 else f"{base}-{count}"
            headings.append(Heading(level, text, i, anchor))

        return Document(source, path, tokens, headings)

    @staticmethod
    def _plain_inline(token) -> str:
        if token is None:
            return ""
        if token.children:
            parts: list[str] = []
            for child in token.children:
                if child.type in {"text", "code_inline", "html_inline", "math_inline", "sub", "sup"}:
                    parts.append(child.content)
                elif child.type in {"softbreak", "hardbreak"}:
                    parts.append(" ")
            return "".join(parts).strip()
        return token.content.strip()


def slugify(value: str) -> str:
    import re

    value = value.lower().strip()
    value = re.sub(r"[^\w\s-]", "", value, flags=re.UNICODE)
    value = re.sub(r"[\s_-]+", "-", value).strip("-")
    return value or "section"
