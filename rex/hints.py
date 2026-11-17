"""
kitty-style hints for Rex: label every URL, path, hash, … on a pane's screen,
type a label to open or copy it.

Run by the "hints" action in rex/init.lua inside a floating pane laid exactly
over the source pane:

    /usr/bin/python3 hints.py --session S --block B --kind KIND

KIND is one of KINDS below. The pane's screen comes from `rex capture
--format=vt`, which keeps OSC 8 hyperlinks. The overlay is a few rows and
columns smaller than the pane (its title bar and border), so it shows the
bottom of the screen and cuts lines at its width.

Keys: type a label · backspace undoes a typed character · esc cancels.
Either way focus returns to the source pane.

Python 3.9 compatible: the action runs this with the system python3.
"""

import curses
import json
import locale
import os
import re
import shutil
import subprocess
import sys
import unicodedata

HOME = os.path.expanduser('~')

# kitty's default hint alphabet; the bottom-most match gets the first label.
ALPHABET = '0123456789abcdefghijklmnopqrstuvwxyz'
FIRST_LABEL = 1

URL_PREFIXES = 'https?|file|ftp|gemini|irc|gopher|mailto|news|git|sftp|ssh'
TRAILING_PUNCTUATION = '.,;:!?\'"'

# kitty's own patterns (kittens/hints), with \r dropped: lines are matched one
# at a time.
PATTERNS = {
    'url': re.compile(r'(?:%s):(?://)?[^\s<>"\'`]+' % URL_PREFIXES),
    'path': re.compile(r'(?:\S*?/\S+)|(?:\S+\.[a-zA-Z0-9]{2,7})\b'),
    'hash': re.compile(r'\b[0-9a-f][0-9a-f]{6,127}\b'),
    'line': re.compile(r'\S.*\S|\S'),
    'branch': re.compile(
        r'(?<!/)(?:main|master|staging|(?:jordan|feat|feature|fix|chore|hotfix|bugfix|release|refactor)/[a-zA-Z0-9_-]+)'
    ),
    'resume': re.compile(
        r'claude\s+(?:--resume|-r)\s+"?[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]"?'
        r'|codex\s+(?:resume|--resume)\s+"?[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]"?'
    ),
}

# kind -> what happens to the chosen text
ACTIONS = {
    'url': 'open',
    'hyperlink': 'open',
    'path': 'copy',
    'hash': 'copy',
    'line': 'copy',
    'branch': 'copy',
    'resume': 'copy',
}

KINDS = tuple(ACTIONS)

# OSC 8 hyperlink, other OSC/DCS strings, SGR, cursor forward, other CSI, and
# any other escape. Order matters: the first alternative that matches wins.
VT_TOKEN = re.compile(
    r'\x1b\]8;[^;\x07\x1b]*;(?P<link>[^\x07\x1b]*)(?:\x1b\\|\x07)'
    r'|\x1b[\]P^_X][^\x07\x1b]*(?:\x1b\\|\x07)'
    r'|\x1b\[(?P<forward>\d*)C'
    r'|\x1b\[[0-9;:?]*[ -/]*[@-~]'
    r'|\x1b.'
)


# ---------------------------------------------------------------------------
# Rex

def rex_bin():
    found = shutil.which('rex')
    if found:
        return found

    return os.path.join(
        HOME,
        'Library/Application Support/com.superlogical.rex/RexServer/Versions/Current',
        'Rex Server.app/Contents/MacOS/rex',
    )


def rex(*args):
    result = subprocess.run([rex_bin(), *args], capture_output=True, text=True, timeout=10)
    if result.returncode != 0:
        raise RuntimeError(f"rex {' '.join(args[:2])} failed: {result.stderr.strip()}")

    return result.stdout


def pane_rows(session, block):
    size = json.loads(rex('block', 'call', '-s', session, '-b', block, 'size', '{}'))

    return int(size.get('rows') or 0)


def focus(session, block):
    payload = json.dumps({'block_id': block})
    try:
        rex('api', 'call', '-s', session, 'session.focus_block', payload)
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f'hints: could not return focus to {block}: {error}', file=sys.stderr)


# ---------------------------------------------------------------------------
# Screen

def cell_width(char):
    if unicodedata.combining(char):
        return 0

    return 2 if unicodedata.east_asian_width(char) in ('W', 'F') else 1


def parse_line(raw):
    """Plain text of one captured line, and its hyperlinks as (start, end, url)."""
    text = []
    links = []
    link_url, link_start = None, 0
    position = 0

    def close_link():
        if link_url and len(text) > link_start:
            links.append((link_start, len(text), link_url))

    while position < len(raw):
        token = VT_TOKEN.match(raw, position)
        if not token:
            char = raw[position]
            if char >= ' ' or char == '\t':
                text.append(' ' if char == '\t' else char)
            position += 1
            continue

        position = token.end()

        if token.group('link') is not None:
            close_link()
            link_url = token.group('link') or None
            link_start = len(text)
            continue

        if token.group('forward') is not None:
            # Rex encodes runs of blank cells as cursor-forward.
            text.extend(' ' * int(token.group('forward') or 1))

    close_link()

    return ''.join(text), links


def read_screen(session, block):
    rows = pane_rows(session, block)
    capture = rex('capture', '-s', session, '-b', block, '--format=vt')
    raw_lines = capture.replace('\r\n', '\n').rstrip('\n').split('\n')

    return [parse_line(raw) for raw in raw_lines[-rows:]] if rows else []


# ---------------------------------------------------------------------------
# Matches

def clean_url(url):
    url = url.rstrip(TRAILING_PUNCTUATION)

    # Keep a closing bracket only when the URL opened one, as in wiki links.
    for opener, closer in ('()', '[]', '{}'):
        while url.endswith(closer) and url.count(closer) > url.count(opener):
            url = url[:-1]

    return url


def find_matches(lines, kind):
    """[(row, start, end, text)] in screen order."""
    matches = []

    for row, (text, links) in enumerate(lines):
        if kind in ('hyperlink', 'url'):
            matches.extend((row, start, end, url) for start, end, url in links)

        if kind == 'hyperlink':
            continue

        for found in PATTERNS[kind].finditer(text):
            value = found.group(0)
            if kind == 'url':
                value = clean_url(value)
            start = found.start()
            if kind == 'path':
                stripped = value.lstrip('`"\'([{<')
                start += len(value) - len(stripped)
                value = stripped.rstrip(TRAILING_PUNCTUATION + '`)]}>')
                # Code such as foo.bar(baz) looks like a path; real paths rarely hold "(".
                if '(' in value:
                    continue

            end = start + len(value)
            overlaps_link = any(row == m[0] and start < m[2] and end > m[1] for m in matches)
            if value and not overlaps_link:
                matches.append((row, start, end, value))

    return sorted(matches, key=lambda m: (m[0], m[1]))


def make_labels(count):
    """Labels for count matches, the shortest for the bottom-most."""
    base = len(ALPHABET)
    width = 1
    while base ** width < count + FIRST_LABEL:
        width += 1

    def encode(number):
        digits = []
        for _ in range(width):
            digits.append(ALPHABET[number % base])
            number //= base
        return ''.join(reversed(digits)) if width > 1 else digits[0]

    return [encode(index + FIRST_LABEL) for index in range(count)]


# ---------------------------------------------------------------------------
# UI

def draw(screen, lines, matches, labels, typed):
    height, width = screen.getmaxyx()
    offset = max(0, len(lines) - height)

    screen.erase()

    for row, (text, _) in enumerate(lines[offset:]):
        put(screen, row, 0, text, width, curses.A_DIM)

    for (row, start, end, text), label in zip(matches, labels):
        screen_row = row - offset
        is_visible = 0 <= screen_row < height
        is_candidate = label.startswith(typed)
        if not (is_visible and is_candidate):
            continue

        line_text = lines[row][0]
        column = sum(cell_width(c) for c in line_text[:start])
        put(screen, screen_row, column, line_text[start:end], width, curses.color_pair(1) | curses.A_BOLD)
        put(screen, screen_row, column, label[len(typed):], width, curses.color_pair(2) | curses.A_BOLD)

    screen.refresh()


def put(screen, row, column, text, width, attr):
    room = width - column - (1 if row == screen.getmaxyx()[0] - 1 else 0)
    if room <= 0:
        return

    try:
        screen.addnstr(row, column, text, room, attr)
    except curses.error:
        pass  # writing into the last cell raises after drawing it


def choose(screen, lines, matches):
    curses.curs_set(0)
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_GREEN, -1)
    curses.init_pair(2, curses.COLOR_BLACK, curses.COLOR_YELLOW)

    # Bottom-most match first, so the likeliest target gets the shortest label.
    labels = list(reversed(make_labels(len(matches))))
    by_label = dict(zip(labels, matches))
    typed = ''

    while True:
        draw(screen, lines, matches, labels, typed)
        key = screen.get_wch()

        if key in ('\x1b', '\x03') or key == 27:
            return None

        if key in ('\x7f', '\b', curses.KEY_BACKSPACE):
            typed = typed[:-1]
            continue

        if not isinstance(key, str) or key.lower() not in ALPHABET:
            continue

        candidate = typed + key.lower()
        if not any(label.startswith(candidate) for label in labels):
            continue

        typed = candidate
        if typed in by_label:
            return by_label[typed]


def act(kind, text):
    if ACTIONS[kind] == 'open':
        subprocess.run(['open', text], check=False)
        return

    subprocess.run(['pbcopy'], input=text.encode('utf-8'), check=False)


# ---------------------------------------------------------------------------

def flag(name, default=''):
    if name not in sys.argv:
        return default

    index = sys.argv.index(name) + 1

    return sys.argv[index] if index < len(sys.argv) else default


def main():
    session = flag('--session')
    block = flag('--block')
    kind = flag('--kind', 'url')
    if not (session and block and kind in KINDS):
        print(__doc__)
        return 2

    locale.setlocale(locale.LC_ALL, '')

    # Esc must cancel at once, not wait for a possible escape sequence.
    os.environ.setdefault('ESCDELAY', '10')

    try:
        lines = read_screen(session, block)
        matches = find_matches(lines, kind)
        if not matches:
            focus(session, block)
            return 0

        chosen = curses.wrapper(choose, lines, matches)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f'hints: {error}')
        input('press enter')
        focus(session, block)
        return 1

    focus(session, block)

    if chosen:
        act(kind, chosen[3])

    return 0


if __name__ == '__main__':
    sys.exit(main())
