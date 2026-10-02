#!/usr/bin/env python3
"""Render a terminal capture (text with ANSI SGR colours) as an SVG image of a terminal window.

Usage: ansi2svg.py CAPTURE.ansi IMAGE.svg
       ansi2svg.py --cast IMAGE.svg CAPTURE.ansi [CAPTURE.ansi ...]

The second form renders the captures as one animated terminal session: each command is typed, then its output
flows in, the window scrolling as a terminal does; the session restarts after a pause. The animation is SMIL with
discrete steps (no script), so it plays wherever the image is shown, a GitHub README included, and it depends only
on the captures: the same captures give the same bytes.

Used by scripts/docs_examples.sh for the runs marked "!image ID" and for the "!cast NAME ID ..." sessions: the images
are generated, never edited by hand.
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
ROWS = 28  # rows of the window of a cast, at most
START = 0.6  # times of a cast (s): before the first prompt,
THINK = 0.5  # between a prompt and the first key,
KEY = 0.06  # between two keys,
ENTER = 0.4  # between the last key and the output,
FLOW = 0.03  # between two lines of output,
READ = 1.4  # after an output, plus
READ_LINE = 0.08  # for each of its lines,
HOLD = 4.0  # and after the last output, before the session restarts
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


def steps(attribute: str, values: list[str], times: list[float], total: float) -> str:
    """An attribute taking each value from its time on, the session restarting after total seconds."""
    keys = ";".join(f"{t / total:.5f}" for t in times)
    return (
        f'<animate attributeName="{attribute}" values="{";".join(values)}" keyTimes="{keys}" '
        f'dur="{total:.2f}s" calcMode="discrete" repeatCount="indefinite"/>'
    )


def render_cast(captures: list[str]) -> str:
    """The animated SVG of a session: the captures one after the other, each command typed."""
    scenes = [
        [OTHER.sub("", line) for line in capture.rstrip("\n").split("\n")]
        for capture in captures
    ]
    lines = [line for scene in scenes for line in scene] + ["$ "]
    rows = min(ROWS, len(lines))
    w = round(2 * PAD + max(len(SGR.sub("", line)) for line in lines) * CHAR)
    h = round(BAR + 2 * PAD + rows * LINE - (LINE - FONT))
    # the timeline: when each line is shown, and when each command starts to be typed
    shown: list[float] = []
    typed: dict[int, float] = {}
    t = START
    for scene in scenes:
        typed[len(shown)] = t + THINK
        shown.append(t)
        t += THINK + (len(scene[0]) - 2) * KEY + ENTER
        for _ in scene[1:]:
            shown.append(t)
            t += FLOW
        t += READ + READ_LINE * (len(scene) - 1)
    shown.append(t)
    total = t + HOLD
    top = (
        BAR + PAD - (LINE - FONT) - 1
    )  # of the first row: the rows scrolled away are cut on a row boundary
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
        f'<rect width="{w}" height="{h}" rx="8" fill="{BACKGROUND}"/>',
        '<circle cx="18" cy="16" r="6" fill="#ff5f56"/><circle cx="38" cy="16" r="6" fill="#ffbd2e"/>',
        '<circle cx="58" cy="16" r="6" fill="#27c93f"/>',
        f'<clipPath id="screen"><rect y="{top}" width="{w}" height="{rows * LINE}"/></clipPath>',
        f'<g clip-path="url(#screen)" font-family="ui-monospace,SFMono-Regular,Menlo,Consolas,monospace" '
        f'font-size="{FONT}" fill="{FOREGROUND}"><g>',
    ]
    if (
        len(lines) > rows
    ):  # the window scrolls by a line when a line is shown below its last row
        offsets = ["0 0"] + [
            f"0 {-(n + 1 - rows) * LINE}" for n in range(rows, len(lines))
        ]
        keys = ";".join(f"{t / total:.5f}" for t in [0.0] + shown[rows:])
        out.append(
            f'<animateTransform attributeName="transform" type="translate" values="{";".join(offsets)}" '
            f'keyTimes="{keys}" dur="{total:.2f}s" calcMode="discrete" repeatCount="indefinite"/>'
        )
    for n, line in enumerate(lines):
        y = BAR + PAD + FONT + n * LINE - (LINE - FONT)
        body = "".join(tspan(text, style) for text, style in spans(line))
        if line.startswith("$ "):
            body = f'<tspan fill="#98c379">$</tspan>{escape(SGR.sub("", line)[1:])}'
        show = steps("opacity", ["0", "1"], [0.0, shown[n]], total)
        out.append(
            f'<text x="{PAD}" y="{y}" opacity="0" xml:space="preserve">{body}{show}</text>'
        )
        if not line.startswith("$ "):
            continue
        # a prompt: its command is behind a cover that uncovers a character at each key, the cursor on its edge
        x = PAD + 2 * CHAR
        keys = len(line) - 2
        start = typed.get(n, shown[n])
        edges = [f"{x + k * CHAR:.2f}" for k in range(keys + 1)]
        times = [0.0] + [start + k * KEY for k in range(1, keys + 1)]
        if keys:
            out.append(
                f'<rect x="{x:.2f}" y="{y - FONT}" width="{w}" height="{LINE}" fill="{BACKGROUND}">'
                f"{steps('x', edges, times, total)}</rect>"
            )
        leave = (
            start + keys * KEY + ENTER
        )  # the cursor leaves the line with the output; it stays on the last prompt
        blink = steps("opacity", ["0", "0.8", "0"], [0.0, shown[n], leave], total)
        if n == len(lines) - 1:
            blink = steps("opacity", ["0", "0.8"], [0.0, shown[n]], total)
        move = steps("x", edges, times, total) if keys else ""
        out.append(
            f'<rect x="{x:.2f}" y="{y - FONT + 1}" width="{CHAR}" height="{LINE - 3}" fill="{FOREGROUND}" '
            f'opacity="0">{move}{blink}</rect>'
        )
    out.append("</g></g></svg>")
    return "\n".join(out) + "\n"


def main() -> None:
    """Convert the capture (or, with --cast, the captures) named on the command line."""
    if sys.argv[1] == "--cast":
        image = sys.argv[2]
        captures = []
        for capture in sys.argv[3:]:
            with open(capture, encoding="utf-8") as source:
                captures.append(source.read())
        svg = render_cast(captures)
        with open(image, "w", encoding="utf-8") as target:
            target.write(svg)
        return
    capture, image = sys.argv[1:3]
    with open(capture, encoding="utf-8") as source:
        svg = render(source.read())
    with open(image, "w", encoding="utf-8") as target:
        target.write(svg)


if __name__ == "__main__":
    main()
