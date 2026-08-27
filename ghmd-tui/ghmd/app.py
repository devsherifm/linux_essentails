from __future__ import annotations

from pathlib import Path

from textual import events
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import Footer, Header, Input, Label, OptionList
from textual.widgets.option_list import Option

from .parser import Document, GFMParser
from .renderer import MarkdownDocument
from .theme import THEMES


class GHMD(App):
    TITLE = "ghmd — GitHub-style Markdown browser"

    CSS = """
    Screen { background: $surface; color: $text; }
    Header { height: 1; }
    Footer { height: 1; }
    #body { height: 1fr; }
    #main { width: 1fr; height: 1fr; }
    #document { width: 1fr; height: 1fr; padding: 1 2; scrollbar-gutter: stable; }
    #toc { width: 36; height: 1fr; display: none; border: round $primary; background: $panel; padding: 1; }
    #toc.visible { display: block; }
    #toc-list { height: 1fr; }
    #toc-list:focus { border: none; }
    .toc-title { text-style: bold; padding-bottom: 1; }
    .heading { width: 1fr; margin: 1 0; padding: 0 1; text-wrap: wrap; }
    .h1 { border: double $primary; text-style: bold; padding: 1 2; margin: 1 0 2 0; }
    .h2 { border: round $primary; text-style: bold; padding: 0 2; margin: 1 0; }
    .h3 { border-left: thick $secondary; text-style: bold; padding-left: 2; margin: 1 0; }
    .h4 { border-left: solid $success; text-style: bold; padding-left: 2; margin: 1 0; }
    .h5 { background: $panel; text-style: bold; padding: 0 2; margin: 1 0; }
    .h6 { color: $text-muted; text-style: italic; padding-left: 2; margin: 1 0; }
    .search-hit { background: #3b2f00; border-left: thick $warning; padding-left: 1; }
    .paragraph { margin-bottom: 1; }
    .codeblock { margin: 1 0; padding: 0 1; }
    .table { margin: 1 0; }
    .blockquote { margin: 1 2; }
    .alert { margin: 1 0; padding: 1 2; border: round $primary; }
    .alert-note { border: round $primary; }
    .alert-tip { border: round $success; }
    .alert-important { border: round #8250df; }
    .alert-warning { border: round $warning; }
    .alert-caution { border: round $error; }
    .list { margin: 0 1 1 1; }
    .image { margin: 1 0; padding: 1; width: 1fr; height: auto; border: round #30363d; }
    .image-fallback { width: 1fr; height: auto; }
    .details { margin: 1 0; padding: 1 2; border: dashed $primary; }
    .definition-list { margin: 1 0; }
    .mathblock { margin: 1 0; }
    .diagram { margin: 1 0; }
    .front-matter { margin: 1 0; }
    #search { dock: top; display: none; height: 3; background: $panel; padding: 0 1; layer: overlay; }
    #search.visible { display: block; }
    #search-input { width: 1fr; }
    #status { height: 1; width: 1fr; background: $panel; color: $text; padding: 0 1; }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("escape", "escape", "Back"),
        Binding("t", "toc", "TOC"),
        Binding("slash", "search", "Search"),
        Binding("r", "reload", "Reload"),
        Binding("w", "watch", "Watch"),
        Binding("n", "next_match", "Next"),
        Binding("N", "prev_match", "Prev"),
        Binding("g", "top", "Top"),
        Binding("G", "bottom", "Bottom"),
        Binding("j", "scroll_down", "Down"),
        Binding("k", "scroll_up", "Up"),
        Binding("space", "page_down", "Page ↓"),
        Binding("b", "page_up", "Page ↑"),
        Binding("c", "copy_document", "Copy"),
        Binding("C", "copy_source", "Copy Source"),
    ]

    def __init__(self, path: Path, theme: str = "dark", watch: bool = False, image_mode: str = "auto", rich_markup: bool | None = None):
        super().__init__()
        self.path = path
        self.md_theme = THEMES[theme]
        self.parser = GFMParser()
        self.document: Document = self.parser.parse(self.path.read_text(encoding="utf-8"), self.path)
        self.watch_enabled = watch
        self.image_mode = image_mode
        self.rich_markup = rich_markup
        self.search_term = ""
        self.search_matches: list[object] = []
        self.search_index = -1
        self._mtime = self.path.stat().st_mtime_ns
        self._watch_timer = None

    def compose(self) -> ComposeResult:
        yield Header(show_clock=False)
        with Horizontal(id="body"):
            with Container(id="toc"):
                yield Label("TABLE OF CONTENTS", classes="toc-title")
                yield OptionList(id="toc-list")
            with Vertical(id="main"):
                with Container(id="search"):
                    yield Input(placeholder="Search Markdown…", id="search-input")
                yield MarkdownDocument(
                    self.document,
                    self.md_theme,
                    image_mode=self.image_mode,
                    rich_markup=self.rich_markup,
                    id="document",
                )
                yield Label("Ready", id="status")
        yield Footer()

    def on_mount(self) -> None:
        self._populate_toc()
        self._doc().focus()
        if self.watch_enabled:
            self._start_watch()

    def _start_watch(self) -> None:
        if self._watch_timer is None:
            self._watch_timer = self.set_interval(0.75, self._check_file)

    def _populate_toc(self) -> None:
        toc = self.query_one("#toc-list", OptionList)
        toc.clear_options()
        for idx, h in enumerate(self.document.headings):
            label = f"{'  ' * max(h.level - 1, 0)}{h.text}"
            toc.add_option(Option(label, id=f"toc-{idx}"))

    def action_toc(self) -> None:
        toc = self.query_one("#toc")
        visible = not toc.has_class("visible")
        toc.set_class(visible, "visible")
        if visible:
            self.query_one("#toc-list", OptionList).focus()
        else:
            self._doc().focus()

    def action_search(self) -> None:
        bar = self.query_one("#search")
        bar.add_class("visible")
        inp = self.query_one("#search-input", Input)
        inp.focus()
        inp.select_all()

    def action_escape(self) -> None:
        search = self.query_one("#search")
        toc = self.query_one("#toc")
        if search.has_class("visible"):
            search.remove_class("visible")
            self._doc().focus()
            return
        if toc.has_class("visible"):
            toc.remove_class("visible")
            self._doc().focus()
            return
        self.exit()

    def action_reload(self) -> None:
        self.run_worker(self._reload_async(), name="reload", exclusive=True, exit_on_error=False)

    def action_watch(self) -> None:
        self.watch_enabled = not self.watch_enabled
        if self.watch_enabled:
            self._start_watch()
        else:
            if self._watch_timer is not None:
                self._watch_timer.stop()
                self._watch_timer = None
        self._status("Live reload: ON" if self.watch_enabled else "Live reload: OFF")

    def _check_file(self) -> None:
        try:
            mtime = self.path.stat().st_mtime_ns
            if mtime != self._mtime:
                self._mtime = mtime
                self.run_worker(self._reload_async(), name="watch-reload", exclusive=True, exit_on_error=False)
        except OSError as exc:
            self.notify(f"File check failed: {exc}", severity="error")

    async def _reload_async(self) -> None:
        try:
            document = self.parser.parse(self.path.read_text(encoding="utf-8"), self.path)
            widget = self.query_one("#document", MarkdownDocument)
            await widget.update_document(document)
            self.document = document
            self._populate_toc()
            self.search_term = ""
            self.search_matches = []
            self.search_index = -1
            self._status("Reloaded")
        except Exception as exc:
            self.notify(f"Reload failed: {exc}", severity="error")

    def _doc(self) -> MarkdownDocument:
        return self.query_one("#document", MarkdownDocument)

    def _status(self, text: str) -> None:
        self.query_one("#status", Label).update(text)

    def action_copy_document(self) -> None:
        """Copy the readable rendered document through Textual/OSC-52."""
        try:
            self.copy_to_clipboard(self._doc().plain_text())
            self._status("Copied rendered text to clipboard")
        except Exception as exc:
            self._status(f"Copy failed: {exc}")

    def action_copy_source(self) -> None:
        """Copy the original Markdown source without losing formatting."""
        try:
            self.copy_to_clipboard(self.document.source)
            self._status("Copied Markdown source to clipboard")
        except Exception as exc:
            self._status(f"Copy failed: {exc}")

    def action_top(self) -> None:
        self._doc().scroll_home(animate=False, immediate=True)

    def action_bottom(self) -> None:
        self._doc().scroll_end(animate=False, immediate=True)

    def action_scroll_down(self) -> None:
        self._doc().scroll_down(animate=False, immediate=True)

    def action_scroll_up(self) -> None:
        self._doc().scroll_up(animate=False, immediate=True)

    def action_page_down(self) -> None:
        self._doc().scroll_page_down(animate=False)

    def action_page_up(self) -> None:
        self._doc().scroll_page_up(animate=False)

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if event.input.id != "search-input":
            return
        self.search_term = event.value.strip().casefold()
        self._find_matches()
        self.query_one("#search").remove_class("visible")
        self._doc().focus()
        if self.search_matches:
            self._search_step(1)
        else:
            self._status(f"No matches for: {self.search_term}")

    def _find_matches(self) -> None:
        self.search_matches = []
        self.search_index = -1
        if not self.search_term:
            return
        doc = self._doc()
        for text, widget in doc.search_targets:
            if self.search_term in text.casefold():
                self.search_matches.append(widget)

    def _search_step(self, delta: int) -> None:
        if not self.search_matches:
            self._status("No matches")
            return
        self.search_index = (self.search_index + delta) % len(self.search_matches)
        widget = self.search_matches[self.search_index]
        self._doc().scroll_to_widget(widget, animate=False, top=True, immediate=True)
        widget.add_class("search-hit")
        self.set_timer(0.8, lambda: widget.remove_class("search-hit"))
        self._status(f"Match {self.search_index + 1}/{len(self.search_matches)}  •  {self.search_term}")

    def on_option_list_option_selected(self, event: OptionList.OptionSelected) -> None:
        if event.option_list.id != "toc-list":
            return
        try:
            idx = int((event.option_id or "").split("-")[-1])
            if 0 <= idx < len(self.document.headings):
                self._goto_heading(self.document.headings[idx].anchor)
        finally:
            self.query_one("#toc").remove_class("visible")
            self._doc().focus()

    def _goto_heading(self, anchor: str) -> None:
        doc = self._doc()
        widget = doc.heading_widgets.get(anchor)
        if widget is not None:
            self._doc().scroll_to_widget(widget, animate=False, top=True, immediate=True)

    def on_key(self, event: events.Key) -> None:
        """Keep browser navigation active while focus is anywhere in the document."""
        focused = self.focused
        if isinstance(focused, Input):
            if event.key == "escape":
                self.action_escape()
                event.stop()
            return
        if isinstance(focused, OptionList):
            if event.key == "escape":
                self.action_escape()
                event.stop()
            return

        actions = {
            "g": self.action_top,
            "G": self.action_bottom,
            "n": self.action_next_match,
            "N": self.action_prev_match,
            "j": self.action_scroll_down,
            "k": self.action_scroll_up,
            "space": self.action_page_down,
            "b": self.action_page_up,
            "home": self.action_top,
            "end": self.action_bottom,
            "pagedown": self.action_page_down,
            "pageup": self.action_page_up,
        }
        action = actions.get(event.key)
        if action is not None:
            action()
            event.stop()

    def action_next_match(self) -> None:
        self._search_step(1)

    def action_prev_match(self) -> None:
        self._search_step(-1)
