#!/usr/bin/env python3
"""Render a terminal capture (text with ANSI SGR colours) as an SVG image of a terminal window.

Usage: ansi2svg.py CAPTURE.ansi IMAGE.svg

Used by scripts/docs_examples.sh for the runs marked "!image ID": the images are generated, never edited by hand.
Only the SGR sequences FLAP writes are interpreted (reset, bold, italics, underline, the 8 colours and their bright
variants); any other escape sequence is dropped.
"""

from __future__ import annotations

import re
import sys
from html import escape

FONT = 14  # font size (px)
CHAR = 8.43  # width of a character (px), monospace
LINE = 19  # line height (px)
PAD = 18  # padding around the text (px)
BAR = 32  # height of the title bar (px)
COLOURS = {
    30: "#3b4252",
    31: "#e06c75",
    32: "#98c379",
    33: "#e5c07b",
    34: "#61afef",
    35: "#c678dd",
    36: "#56b6c2",
    37: "#dcdfe4",
}
FOREGROUND = "#dcdfe4"
BACKGROUND = "#282c34"
SGR = re.compile(r"\x1b\[([0-9;]*)m")
OTHER = re.compile(r"\x1b\[[0-9;?]*[A-Za-ln-z]")  # every escape sequence but SGR


def spans(line: str) -> list[tuple[str, dict[str, object]]]:
    """Split a line into (text, style) pieces."""
    style: dict[str, object] = {}
    pieces: list[tuple[str, dict[str, object]]] = []
    pos = 0
    for match in SGR.finditer(line):
        if match.start() > pos:
            pieces.append((line[pos : match.start()], dict(style)))
        for code in [int(c) for c in (match.group(1) or "0").split(";") if c]:
            if code == 0:
                style = {}
            elif code == 1:
                style["bold"] = True
            elif code == 3:
                style["italic"] = True
            elif code == 4:
                style["underline"] = True
            elif 30 <= code <= 37:
                style["fill"] = COLOURS[code]
            elif 90 <= code <= 97:
                style["fill"] = COLOURS[code - 60]
        pos = match.end()
    if pos < len(line):
        pieces.append((line[pos:], dict(style)))
    return pieces


def tspan(text: str, style: dict[str, object]) -> str:
    """One styled piece of text."""
    attributes = ""
    if "fill" in style:
        attributes += f' fill="{style["fill"]}"'
    if style.get("bold"):
        attributes += ' font-weight="bold"'
    if style.get("italic"):
        attributes += ' font-style="italic"'
    if style.get("underline"):
        attributes += ' text-decoration="underline"'
    return f"<tspan{attributes}>{escape(text)}</tspan>" if attributes else escape(text)


def render(capture: str) -> str:
    """The SVG of a capture."""
    lines = [OTHER.sub("", line) for line in capture.rstrip("\n").split("\n")]
    width = max(len(SGR.sub("", line)) for line in lines)
    w = round(2 * PAD + width * CHAR)
    h = round(BAR + 2 * PAD + len(lines) * LINE - (LINE - FONT))
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
        f'<rect width="{w}" height="{h}" rx="8" fill="{BACKGROUND}"/>',
        '<circle cx="18" cy="16" r="6" fill="#ff5f56"/><circle cx="38" cy="16" r="6" fill="#ffbd2e"/>',
        '<circle cx="58" cy="16" r="6" fill="#27c93f"/>',
        f'<text font-family="ui-monospace,SFMono-Regular,Menlo,Consolas,monospace" font-size="{FONT}" '
        f'fill="{FOREGROUND}" xml:space="preserve">',
    ]
    for n, line in enumerate(lines):
        y = BAR + PAD + FONT + n * LINE - (LINE - FONT)
        body = "".join(tspan(text, style) for text, style in spans(line))
        if line.startswith("$ "):
            body = f'<tspan fill="#98c379">$</tspan>{escape(SGR.sub("", line)[1:])}'
        out.append(f'<tspan x="{PAD}" y="{y}">{body}</tspan>')
    out.append("</text></svg>")
    return "\n".join(out) + "\n"


def main() -> None:
    """Convert the capture named on the command line."""
    capture, image = sys.argv[1:3]
    with open(capture, encoding="utf-8") as source:
        svg = render(source.read())
    with open(image, "w", encoding="utf-8") as target:
        target.write(svg)


if __name__ == "__main__":
    main()
