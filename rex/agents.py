"""
Agent picker for Rex: live Claude / Codex chats in every Rex session, the PRs
they made or review (rv), and recently closed chats to resume.

Bound in ~/.config/rex/init.lua as the "agents" action, which opens this
script in a floating pane:

    python3 agents.py --pick --client <client id> --origin <block id>

Keys: enter focus (or resume a closed chat in a new tab)
      ctrl-h history: recently closed chats, newest first
      ctrl-g open the chat's latest PR on GitHub, else the PR it reviews
      tab sort by last message (default) / tab · ctrl-a all panes / agents only
      ctrl-r refresh · esc quit

Live rows come from rex/blocks.lua: each block's foreground process, its OSC
7501 status records and its title. Claude reports its own status to Rex. A
Claude block maps to its session through ~/.claude/sessions/<pid>.json.

Transcript reading, history, PR details and rv review details are shared with
the kitty picker and imported from kitty/kittens/agents.py. Chat names from
~/.local/state/kitty-agents/names.json outrank the generated title.

Rows are keyed "b|<session id>|<block id>" for live blocks and
"h:<agent>:<session>" for history. fzf calls this file for its list and actions:
    python3 agents.py --list [--agents | --history] [--recent]
    python3 agents.py --preview KEY
    python3 agents.py --action refresh|scope|sort|history   (reads $FZF_PROMPT)
    python3 agents.py --open-pr KEY
"""

import importlib.util
import json
import os
import shlex
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.realpath(__file__))
BLOCKS_LUA = os.path.join(HERE, 'blocks.lua')
KITTY_AGENTS = os.path.join(HERE, '..', 'kitty', 'kittens', 'agents.py')


def load_shared():
    # Both files are named agents.py, so load the kitty one by path under its own name.
    spec = importlib.util.spec_from_file_location('kitty_agents', KITTY_AGENTS)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    return module


shared = load_shared()

HOME = shared.HOME

# OSC 7501 states -> picker statuses. "done" is a finished turn you have not looked at yet.
STATE_STATUS = {
    'working': 'working',
    'blocked': 'attention',
    'error': 'error',
    'done': 'done',
    'idle': 'idle',
}

STATUS_GLYPH = {
    **shared.STATUS_GLYPH,
    'done': '\x1b[32m✓ done\x1b[0m',
}

AGENT_APPS = ('claude-code', 'codex')


def rex_bin():
    # The picker runs inside a Rex terminal, but fall back to the app bundle if PATH is thin.
    found = shutil.which('rex')
    if found:
        return found

    return os.path.join(
        HOME,
        'Library/Application Support/com.superlogical.rex/RexServer/Versions/Current',
        'Rex Server.app/Contents/MacOS/rex',
    )


def rex(*args, timeout=10):
    result = subprocess.run(
        [rex_bin(), *args],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    if result.returncode != 0:
        raise RuntimeError(f"rex {' '.join(args[:2])} failed: {result.stderr.strip()}")

    return result.stdout


# ---------------------------------------------------------------------------
# Live blocks

def read_blocks(block_id=None):
    args = ['do', BLOCKS_LUA, '--json']
    if block_id:
        args.append(f'block={block_id}')

    data = json.loads(rex(*args) or '[]')

    # Lua encodes an empty table as {}, not [].
    return data if isinstance(data, list) else []


def detect_agent(foreground):
    names = [
        os.path.basename(foreground.get('argv0') or ''),
        os.path.basename(foreground.get('invoked_path') or ''),
    ]
    path = foreground.get('path') or ''

    if 'claude' in names or '/claude/versions/' in path:
        return 'claude'

    if any(n.startswith('codex') for n in names) or '/codex' in path:
        return 'codex'

    return None


def status_record(block):
    records = (block.get('status') or {}).get('records') or []
    if not isinstance(records, list):
        return {}

    agent_records = [r for r in records if r.get('effective_app') in AGENT_APPS]

    return (agent_records or records or [{}])[0]


def claude_pidfile(pid):
    path = os.path.join(HOME, '.claude', 'sessions', f'{pid}.json')
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def is_picker(block):
    # The picker's own pane, and any other open picker (its fzf preview names this file).
    if block['block_id'] == os.environ.get('REX_BLOCK'):
        return True

    foreground = (block.get('process') or {}).get('foreground') or {}

    return foreground.get('argv0') == 'fzf' and 'agents' in (block.get('title') or {}).get('title', '')


def tab_label(block, multiple_sessions):
    # Window position is what cmd+1..9 jumps to; prefix the session only when there are several.
    if multiple_sessions:
        return f"{block['session_index']}.{block['window_index']}"

    return str(block['window_index'])


def block_row(block, now, names, multiple_sessions=False):
    foreground = (block.get('process') or {}).get('foreground') or {}
    agent = detect_agent(foreground)
    record = status_record(block)

    status = STATE_STATUS.get(record.get('state'))
    if not status and agent:
        status = 'idle'
    if not status:
        status = 'shell'

    pidfile = claude_pidfile(foreground.get('pid')) if agent == 'claude' else {}
    session = pidfile.get('sessionId') or ''
    cwd = foreground.get('cwd') or ''
    transcript = shared.read_transcript(session) if session else shared.read_transcript('')

    prompt_at = transcript['prompt_at']
    rex_title = (block.get('title') or {}).get('title', '')

    return {
        'key': f"b|{block['session_id']}|{block['block_id']}",
        'session_id': block['session_id'],
        'window_id': block['window_id'],
        'block_id': block['block_id'],
        'tab': tab_label(block, multiple_sessions),
        'agent': agent or 'shell',
        'status': status,
        'status_msg': record.get('msg', ''),
        'since': now - prompt_at if prompt_at else None,
        'title': names.get(session) or rex_title or transcript['title'],
        'cwd': shared.short_path(cwd),
        'resume_cwd': transcript['start_cwd'] or cwd,
        'session': session,
        'prompt': transcript['prompt'],
        'reply': transcript['reply'],
        'prs': transcript['prs'],
        'review': shared.review_for(session),
    }


def collect_live(blocks, agents_only=False, recent=False):
    now = time.time()
    names = shared.load_names()
    multiple = len({b['session_id'] for b in blocks}) > 1

    rows = [
        block_row(b, now, names, multiple)
        for b in blocks
        if not is_picker(b)
    ]

    if agents_only:
        rows = [r for r in rows if r['agent'] != 'shell']

    if recent:
        # Newest message first; rows with no known message sink to the bottom.
        return sorted(rows, key=lambda r: r['since'] if r['since'] is not None else float('inf'))

    # blocks.lua lists sessions, windows and blocks in Rex's order.
    return rows


# ---------------------------------------------------------------------------
# History: recently closed chats, from the transcripts on disk

def live_sessions(blocks):
    sessions = set()
    for block in blocks:
        foreground = (block.get('process') or {}).get('foreground') or {}
        if detect_agent(foreground) != 'claude':
            continue

        session = claude_pidfile(foreground.get('pid')).get('sessionId')
        if session:
            sessions.add(session)

    return sessions


def collect_history(blocks):
    now = time.time()
    names = shared.load_names()
    live = live_sessions(blocks)
    cutoff = now - shared.HISTORY_DAYS * 86400

    candidates = sorted(shared.claude_history(cutoff) + shared.codex_history(cutoff), reverse=True)

    rows = []
    for _, agent, path in candidates:
        if len(rows) >= shared.HISTORY_LIMIT:
            break

        session_hint = os.path.basename(path)[:-len('.jsonl')]
        is_open = agent == 'claude' and session_hint in live
        # rv generates Claude reviews with `claude -p`, then resumes them interactively.
        is_scripted = agent == 'claude' and shared.is_scripted_claude(path) and not shared.review_for(session_hint)
        if is_open or is_scripted:
            continue

        row = shared.history_row(agent, path, now, {}, names)
        if row and row['session'] not in live:
            rows.append(row)

    return sorted(rows, key=lambda r: r['since'] if r['since'] is not None else float('inf'))


# ---------------------------------------------------------------------------
# Rows by key

def resolve_row(key):
    if key.startswith('h:'):
        return shared.resolve_row(key)

    if not key.startswith('b|'):
        return None

    _, _, block_id = key.split('|', 2)
    blocks = read_blocks(block_id)
    if not blocks:
        return None

    return block_row(blocks[0], time.time(), shared.load_names())


def format_row(r):
    # Field 1 (row key) is hidden by fzf's --with-nth and used for preview and actions.
    # The session id sits last so it is searchable without crowding the view.
    title = shared.clean_title(r['title'])[:40]
    prompt = f"❯ {r['prompt'][:70]}" if r['prompt'] else ''

    # Latest PR, plus a count of any others the chat touched.
    prs = r['prs']
    pr = f'#{prs[0][0]}' + (f' +{len(prs) - 1}' if len(prs) > 1 else '') if prs else ''
    pr_color = '\x1b[35m'
    if not prs and r.get('review'):
        pr = f"rv#{r['review']['number']}"
        pr_color = shared.REVIEW_COLOR

    cols = [
        r['key'],
        f"\x1b[1m{r['tab']:>3}\x1b[0m",
        STATUS_GLYPH.get(r['status'], r['status']),
        f"{shared.age(r['since']):>4}",
        f"\x1b[36m{r['agent']:<6}\x1b[0m",
        f"{pr_color}{pr:<9}\x1b[0m",
        f'{title:<40}',
        f"\x1b[2m{prompt:<72}\x1b[0m",
        f"\x1b[2m{shared.shorten(r['cwd'], 40)}\x1b[0m",
        f"\x1b[2m{r['session'][:8]}\x1b[0m",
    ]

    return '\t'.join(cols)


def print_list(agents_only, recent, history=False):
    try:
        blocks = read_blocks()
        rows = collect_history(blocks) if history else collect_live(blocks, agents_only, recent)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f'x\tcould not read Rex blocks: {error}')
        return

    for r in rows:
        print(format_row(r))


# ---------------------------------------------------------------------------
# Preview

def capture_screen(row):
    try:
        text = rex('capture', '-s', row['session_id'], '-b', row['block_id'], '--trim')
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        return [f'\x1b[2m(could not capture the screen: {error})\x1b[0m']

    return text.rstrip().splitlines()


def print_preview(key):
    height = int(os.environ.get('FZF_PREVIEW_LINES', '40'))
    width = int(os.environ.get('FZF_PREVIEW_COLUMNS', '100'))
    rule = '\x1b[2m' + '─' * width + '\x1b[0m'

    try:
        row = resolve_row(key)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f'could not read this row: {error}')
        return
    if row is None:
        return

    header = []
    if row['prompt']:
        # Full last prompt on top, capped at 4 lines so the screen stays visible.
        header = [
            ('\x1b[1;36m❯\x1b[0m ' if i == 0 else '  ') + f'\x1b[1m{line}\x1b[0m'
            for i, line in enumerate(shared.wrap(row['prompt'], width - 2, 4))
        ]

    if row.get('review'):
        header.extend(shared.review_lines(row['review'], width))

    if row['prs']:
        header.extend(shared.pr_lines(row['prs'], width))

    if row.get('status_msg'):
        header.append(f"\x1b[2m{row['status_msg'][:width]}\x1b[0m")

    if header:
        header.append(rule)

    if row['status'] == 'closed':
        # No pane to capture; show where it resumes and how the chat ended.
        body = [
            '\x1b[2m↺ closed\x1b[0m · enter resumes in a new tab',
            f"\x1b[2m{row['agent']} {row['session']}  in  {row['cwd']}\x1b[0m",
            rule,
            *shared.wrap(row['reply'] or '(no reply recorded)', width, height),
        ]
        print('\n'.join((header + body)[:height]))
        return

    # Agent TUIs keep the latest output and input box at the bottom.
    lines = capture_screen(row)
    body = lines[-max(1, height - len(header)):]
    print('\n'.join(header + body))


def open_pr(key):
    row = resolve_row(key)
    if not row:
        return

    url = row['prs'][0][1] if row['prs'] else (row.get('review') or {}).get('url')
    if url:
        subprocess.run(['open', url], check=False)


# ---------------------------------------------------------------------------
# Enter: focus a live block, or resume a closed chat in a new tab

def focus_block(row, client_id):
    origin = os.environ.get('REX_SESSION')
    other_session = row['session_id'] != origin

    # Only the app can change which session it shows; the server focuses the block.
    if other_session and client_id:
        rex('-C', client_id, 'do', 'session.select', f"session_id={row['session_id']}", f"window_id={row['window_id']}")

    payload = json.dumps({'block_id': row['block_id']})
    rex('api', 'call', '-s', row['session_id'], 'session.focus_block', payload)


def resume_in_new_tab(row):
    cwd, _, argv = shared.resume_command(row)

    # No window label: the tab shows the title Claude sets once the chat starts.
    payload = json.dumps({
        'focus': True,
        'layout': {
            'block': {
                'flavor': 'com.superlogical.terminal.shell',
                'options': {
                    'command': argv,
                    'cwd': cwd,
                },
            },
        },
    })
    rex('api', 'call', '-s', os.environ.get('REX_SESSION', ''), 'session.new_window', payload)


def restore_focus(origin):
    """Back to the pane the picker was opened from; closing it lets Rex pick another."""
    if not origin:
        return

    payload = json.dumps({'block_id': origin})
    try:
        rex('api', 'call', '-s', os.environ.get('REX_SESSION', ''), 'session.focus_block', payload)
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        # The origin pane may have closed while the picker was open.
        print(f'agents: could not return focus to {origin}: {error}', file=sys.stderr)


def handle_pick(key, client_id):
    row = resolve_row(key)
    if row is None:
        return

    if row['status'] == 'closed':
        resume_in_new_tab(row)
        return

    focus_block(row, client_id)


# ---------------------------------------------------------------------------
# fzf

def runner():
    return f'{shlex.quote(sys.executable)} {shlex.quote(os.path.realpath(__file__))}'


def print_action(action):
    scope, sort = shared.parse_prompt(os.environ.get('FZF_PROMPT', ''))

    # ctrl-a flips all/agents (leaving history), ctrl-h flips history/all.
    if action == 'scope':
        scope = 'agents' if scope == 'all' else 'all'
    elif action == 'history':
        scope = 'all' if scope == 'history' else 'history'
    elif action == 'sort':
        sort = shared.SORTS[(shared.SORTS.index(sort) + 1) % len(shared.SORTS)]

    flags = ''
    if scope == 'agents':
        flags += ' --agents'
    if scope == 'history':
        flags += ' --history'  # always newest first
    if sort == 'recent':
        flags += ' --recent'

    print(f'change-prompt({shared.view_prompt(scope, sort)})+reload({runner()} --list{flags})')


def pick():
    """Run fzf over the rows and return the chosen row key, or None."""
    run = runner()
    action = f'{run} --action'
    header = 'enter focus/resume · ctrl-h history · ctrl-g PR · tab sort · ctrl-a all/agents · ctrl-r refresh'

    fzf = [
        shutil.which('fzf') or '/opt/homebrew/bin/fzf',
        '--ansi',
        '--no-sort',
        '--layout=reverse',
        '--delimiter=\t',
        '--with-nth=2..',
        '--tabstop=1',
        f'--header={header}',
        f'--prompt={shared.view_prompt(shared.SCOPES[0], shared.SORTS[0])}',
        f'--preview={run} --preview {{1}}',
        '--preview-window=down,60%,border-top,follow',
        f'--bind=tab:transform:{action} sort',
        f'--bind=ctrl-g:execute-silent({run} --open-pr {{1}})',
        f'--bind=ctrl-a:transform:{action} scope',
        f'--bind=ctrl-h:transform:{action} history',
        f'--bind=ctrl-r:transform:{action} refresh',
    ]

    listing = subprocess.run(
        [sys.executable, os.path.realpath(__file__), '--list', '--recent'],
        capture_output=True,
        text=True,
    ).stdout

    try:
        picked = subprocess.run(fzf, input=listing, stdout=subprocess.PIPE, text=True)
    except FileNotFoundError:
        print('fzf not found on PATH')
        input('press enter')
        return None

    line = picked.stdout.strip()
    if not line:
        return None

    return line.split('\t', 1)[0]


def flag_value(name):
    if name not in sys.argv:
        return None

    index = sys.argv.index(name) + 1

    return sys.argv[index] if index < len(sys.argv) else None


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else '--pick'
    target = sys.argv[2] if len(sys.argv) > 2 else ''

    if command == '--list':
        print_list('--agents' in sys.argv, '--recent' in sys.argv, '--history' in sys.argv)
        return

    if command == '--action' and target:
        print_action(target)
        return

    if command == '--preview' and target:
        print_preview(target)
        return

    if command == '--open-pr' and target:
        open_pr(target)
        return

    if command != '--pick':
        print(__doc__)
        return

    origin = flag_value('--origin')

    key = pick()
    if not key:
        restore_focus(origin)
        return

    try:
        handle_pick(key, flag_value('--client'))
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        # The pane closes when this exits, so hold it open long enough to read the failure.
        print(f'agents: could not open {key}: {error}')
        input('press enter')


if __name__ == '__main__':
    main()
