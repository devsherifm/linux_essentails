from __future__ import annotations

import argparse
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path
import shutil
import sys

from .app import GHMD


def package_version() -> str:
    try:
        return version("ghmd")
    except PackageNotFoundError:
        return "0.5.4"


def diagnose() -> int:
    print(f"ghmd {package_version()}")
    print(f"Python: {sys.version.split()[0]}")
    try:
        import textual
        print(f"Textual: {getattr(textual, '__version__', 'unknown')}")
    except Exception as exc:
        print(f"Textual: ERROR: {exc}")
    try:
        import rich
        print(f"Rich: {getattr(rich, '__version__', 'unknown')}")
    except Exception as exc:
        print(f"Rich: ERROR: {exc}")
    try:
        import markdown_it
        print(f"markdown-it-py: {getattr(markdown_it, '__version__', 'unknown')}")
    except Exception as exc:
        print(f"markdown-it-py: ERROR: {exc}")
    try:
        from textual_image.widget import Image  # noqa: F401
        print("textual-image: available")
    except Exception as exc:
        print(f"textual-image: unavailable ({exc})")
    print(f"chafa: {'available' if shutil.which('chafa') else 'not found'}")
    print(f"TERM: {__import__('os').environ.get('TERM', '')}")
    print(f"COLORTERM: {__import__('os').environ.get('COLORTERM', '')}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="ghmd",
        description="GitHub-style GFM Markdown TUI browser for the terminal",
    )
    p.add_argument("file", type=Path, nargs="?", help="Markdown file to open")
    p.add_argument("--theme", choices=["dark", "light"], default="dark")
    p.add_argument("--watch", action="store_true", help="watch the file and reload on change")
    p.add_argument(
        "--image-mode",
        choices=["auto", "native", "chafa", "off"],
        default="auto",
        help="image rendering strategy (default: auto)",
    )
    p.add_argument("--no-images", action="store_true", help="alias for --image-mode off")
    markup = p.add_mutually_exclusive_group()
    markup.add_argument(
        "--rich-markup", dest="rich_markup", action="store_true",
        help="force Rich markup parsing such as [bold]...[/bold]",
    )
    markup.add_argument(
        "--no-rich-markup", dest="rich_markup", action="store_false",
        help="disable automatic Rich markup detection",
    )
    p.set_defaults(rich_markup=None)
    p.add_argument("--diagnose", action="store_true", help="show runtime and terminal capabilities")
    p.add_argument("--version", action="version", version=f"ghmd {package_version()}")
    return p


def main() -> None:
    args = build_parser().parse_args()
    if args.diagnose:
        raise SystemExit(diagnose())
    if args.file is None:
        build_parser().error("the following arguments are required: file")
    if not args.file.exists():
        print(f"ghmd: file not found: {args.file}", file=sys.stderr)
        raise SystemExit(2)
    if not args.file.is_file():
        print(f"ghmd: not a file: {args.file}", file=sys.stderr)
        raise SystemExit(2)
    image_mode = "off" if args.no_images else args.image_mode
    GHMD(args.file.resolve(), args.theme, args.watch, image_mode, args.rich_markup).run()


if __name__ == "__main__":
    main()
