"""
Render a live Claude Code chat as styled text for Rex copy mode.

Claude Code draws on the terminal's alternate screen, so Rex keeps no
scrollback for it. Its transcript on disk has the whole conversation:

    /usr/bin/python3 claude_transcript.py PID

PID is the pane's foreground Claude process. ~/.claude/sessions/<pid>.json maps
it to a session id, and ~/.claude/projects/*/<session>.jsonl is the transcript.
Prints Markdown: your prompts as "❯ …" lines, Claude's replies as written, and
each tool call as one "● Tool detail" line. The first line is an OSC marker
(MARKER) that tells the copy-mode viewer to show the text in a Markdown buffer
instead of a terminal. Exits 1 when PID is not a Claude session with a
transcript, so copy mode falls back to the pane's screen.

Python 3.9 compatible: copy mode runs this with the system python3.
"""

import glob
import json
import os
import sys

HOME = os.path.expanduser('~')

# Copy mode reads stdout in one piece; very long chats keep their latest part.
MAX_OUTPUT_BYTES = 4 * 1024 * 1024

# Read by ~/code/dotfilez/rex/copy-mode-init.lua. copy-mode strips OSC
# sequences before drawing, so the marker never shows.
MARKER = '\x1b]1337;rex-copy-mode=markdown\x07'

TOOL_DETAIL_CHARS = 110

TOOL_INPUT_KEYS = ('command', 'file_path', 'pattern', 'url', 'query', 'skill', 'subagent_type', 'description', 'prompt')


def session_id(pid):
    path = os.path.join(HOME, '.claude', 'sessions', f'{pid}.json')
    try:
        with open(path) as f:
            return json.load(f).get('sessionId')
    except (OSError, ValueError):
        return None


def transcript_path(session):
    paths = glob.glob(os.path.join(HOME, '.claude', 'projects', '*', f'{session}.jsonl'))

    return paths[0] if paths else None


def prompt_text(content):
    """Text you typed, or None for tool results and injected context."""
    if isinstance(content, list):
        content = ' '.join(
            part.get('text', '')
            for part in content
            if isinstance(part, dict) and part.get('type') == 'text'
        )
    if not isinstance(content, str) or not content.strip():
        return None

    # Slash commands are stored as <command-name>/foo</command-name><command-args>…
    if '<command-name>' in content:
        name = content.split('<command-name>', 1)[1].split('<', 1)[0]
        args = content.split('<command-args>', 1)[1].split('<', 1)[0] if '<command-args>' in content else ''
        return f'{name} {args}'.strip()

    # Other tagged content is injected context (reminders, local command output).
    if content.lstrip().startswith('<'):
        return None

    return content.strip()


def tool_summary(part):
    name = part.get('name', 'tool')
    tool_input = part.get('input') or {}
    detail = next(
        (str(tool_input[key]) for key in TOOL_INPUT_KEYS if tool_input.get(key)),
        '',
    )

    # One line per call: the first line of a command or path, cut to fit.
    lines = detail.strip().splitlines() or ['']
    first = ' '.join(lines[0].split())
    is_cut = len(lines) > 1 or len(first) > TOOL_DETAIL_CHARS
    first = first[:TOOL_DETAIL_CHARS] + ('…' if is_cut else '')

    return f'● {name}  {first}'.rstrip()


def render_user(entry):
    if entry.get('isMeta'):
        return None

    text = prompt_text((entry.get('message') or {}).get('content'))
    if not text:
        return None

    lines = [line for line in text.splitlines() if line.strip()] or ['']
    first = f'❯ {lines[0]}'
    rest = [f'  {line}' for line in lines[1:]]

    return '\n'.join([first, *rest])


def render_assistant(entry):
    parts = (entry.get('message') or {}).get('content') or []
    blocks = []

    for part in parts:
        if not isinstance(part, dict):
            continue

        if part.get('type') == 'text' and part.get('text', '').strip():
            blocks.append(part['text'].strip())
            continue

        if part.get('type') == 'tool_use':
            blocks.append(tool_summary(part))

    return '\n'.join(blocks) if blocks else None


def join_blocks(blocks):
    """Blank line between messages; consecutive tool calls stay together."""
    out = []
    previous_kind = None

    for kind, text in blocks:
        separator = '\n' if kind == previous_kind == 'tool' else '\n\n'
        out.append((separator if out else '') + text)
        previous_kind = kind

    return ''.join(out) + '\n'


def render(path):
    blocks = []

    with open(path, 'rb') as f:
        for raw in f:
            is_user = b'"type":"user"' in raw
            is_assistant = b'"type":"assistant"' in raw
            if not (is_user or is_assistant):
                continue

            try:
                entry = json.loads(raw)
            except ValueError:
                continue

            if entry.get('isSidechain'):
                continue

            if entry.get('type') == 'user':
                text = render_user(entry)
                kind = 'prompt'
            else:
                text = render_assistant(entry)
                is_tools_only = text and all(line.startswith('● ') for line in text.splitlines())
                kind = 'tool' if is_tools_only else 'reply'

            if text:
                blocks.append((kind, text))

    return join_blocks(blocks)


def main():
    pid = sys.argv[1] if len(sys.argv) > 1 else ''
    session = session_id(pid) if pid.isdigit() else None
    path = transcript_path(session) if session else None
    if not path:
        return 1

    try:
        text = render(path)
    except OSError as error:
        print(f'claude_transcript: could not read {path}: {error}', file=sys.stderr)
        return 1

    data = text.encode('utf-8', 'replace')
    if len(data) > MAX_OUTPUT_BYTES:
        # Cut at a line boundary so no escape sequence or character is split.
        data = data[-MAX_OUTPUT_BYTES:]
        data = data[data.find(b'\n') + 1:]
        data = '*(earlier messages omitted)*\n\n'.encode() + data

    sys.stdout.buffer.write((MARKER + '\n').encode() + data)

    return 0


if __name__ == '__main__':
    sys.exit(main())
