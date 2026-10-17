"""
Agent picker kitten for kitty.
Lists every window with Claude / Codex status, previews its screen, and focuses
the selected window on Enter. Starred sessions stay listed as "dormant" after
their window closes; Enter on one resumes it in a new tab. ctrl-h lists recently
closed sessions from the Claude and Codex transcripts on disk.

Usage in kitty.conf:
    map cmd+shift+a kitten kittens/agents.py

Keys: enter focus (or resume a dormant / closed session) · ctrl-s star / unstar
      ctrl-h history: recently closed sessions, newest first
      ctrl-g open the session's latest PR on GitHub
      tab sort by last message (default) / tab · ctrl-a all windows / agents only
      ctrl-r refresh · esc quit

Status and last prompt come from the window user vars written by
~/code/dotfilez/bin/agent-kitty-vars (Claude/Codex hooks). Claude windows
without vars yet fall back to ~/.claude/sessions/<pid>.json for the session
and its transcript for everything else. Stars live in
~/.local/state/kitty-agents/starred.json.

Chat names (kitty_mod+r, kittens/rename_chat.py) live per session in
~/.local/state/kitty-agents/names.json and outrank the generated title
everywhere: live, dormant and history rows, and the tab bar. See
kitty/AGENTS_SPEC.md for the title rules.

Rows are keyed by window id for live windows, "s:<session>" for dormant ones,
and "h:<agent>:<session>" for history.
The file also runs as a plain script, which fzf calls for its list and actions:
    python3 agents.py --list [--agents | --history] [--recent]
    python3 agents.py --preview KEY
    python3 agents.py --action refresh|scope|sort   (reads $FZF_PROMPT, prints fzf actions)
    python3 agents.py --open-pr KEY
    python3 agents.py --star KEY
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime

KITTEN = '/Applications/kitty.app/Contents/MacOS/kitten'
KITTY = '/Applications/kitty.app/Contents/MacOS/kitty'
HOME = os.path.expanduser('~')
STATE_DIR = os.path.join(HOME, '.local', 'state', 'kitty-agents')
STARS_PATH = os.path.join(STATE_DIR, 'starred.json')
NAMES_PATH = os.path.join(STATE_DIR, 'names.json')
PRS_PATH = os.path.join(STATE_DIR, 'prs.json')
# Written by rv (scripts/review-lib/agents-index.ts): {session: {agent, url, repo, number, title, dir, root}}.
REVIEWS_PATH = os.path.join(STATE_DIR, 'reviews.json')

# PR titles rarely change, but state (open / merged) does; refetch after this.
PR_CACHE_SECONDS = 10 * 60
PREVIEW_PRS = 4
CLAUDE_PROJECTS = os.path.join(HOME, '.claude', 'projects')
CODEX_SESSIONS = os.path.join(HOME, '.codex', 'sessions')

HISTORY_LIMIT = 40
HISTORY_DAYS = 14

# History reads only the ends of each transcript: recent ones run to 10MB+.
HEAD_BYTES = 64 * 1024
TAIL_BYTES = 1024 * 1024

STATUS_GLYPH = {
    'attention': '\x1b[1;31m● need\x1b[0m',
    'error': '\x1b[31m✗ err \x1b[0m',
    'working': '\x1b[33m◐ work\x1b[0m',
    'idle': '\x1b[2m○ idle\x1b[0m',
    'dormant': '\x1b[34m◌ dorm\x1b[0m',
    'closed': '\x1b[2m↺ past\x1b[0m',
    'shell': '\x1b[2m· sh  \x1b[0m',
}


def remote(*args):
    listen = os.environ.get('KITTY_LISTEN_ON')
    to = ['--to', listen] if listen else []
    result = subprocess.run(
        [KITTEN, '@', *to, *args],
        capture_output=True,
        text=True,
        timeout=5,
    )
    return result.stdout


# ---------------------------------------------------------------------------
# Stars

def load_json(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return {}

    return data if isinstance(data, dict) else {}


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)

    # Write then rename so a crash mid-write never truncates the file.
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix='.tmp.')
    with os.fdopen(fd, 'w') as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)


def load_stars():
    """{session_id: {agent, session, cwd, title, prompt, starred_at}}"""
    return load_json(STARS_PATH)


def save_stars(stars):
    save_json(STARS_PATH, stars)


def load_names():
    """{session_id: tab name you gave that session}"""
    return load_json(NAMES_PATH)


def save_names(names):
    save_json(NAMES_PATH, names)


def adopt_tab_names(rows):
    """Turn kitty tab names on agent tabs into names of the chat running there.

    kitty_mod+r names the chat directly; this covers tabs renamed some other
    way (command palette, set-tab-title). The kitty tab name is then cleared so
    it cannot carry over to the next chat started in that tab.
    """
    adopted = [r for r in rows if r['session'] and r['tab_name']]
    if not adopted:
        return

    names = load_names()
    save_names({**names, **{r['session']: r['tab_name'] for r in adopted}})

    for r in adopted:
        remote('set-tab-title', '--match', f"window_id:{r['key']}")


# ---------------------------------------------------------------------------
# PR details (preview only): one batched GitHub GraphQL call, cached on disk

PR_URL = re.compile(r'github\.com/([^/]+)/([^/]+)/pull/(\d+)')

PR_STATE_STYLE = {
    'OPEN': ('\x1b[32m', 'open'),
    'DRAFT': ('\x1b[2m', 'draft'),
    'MERGED': ('\x1b[35m', 'merged'),
    'CLOSED': ('\x1b[31m', 'closed'),
}


def fetch_pr_details(urls):
    """{url: {title, state}} for PRs, from cache when fresh, else one gh GraphQL query."""
    cache = load_json(PRS_PATH)
    now = time.time()
    stale = [u for u in urls if now - cache.get(u, {}).get('fetched_at', 0) > PR_CACHE_SECONDS]

    parsed = {u: PR_URL.search(u) for u in stale}
    by_repo = {}
    for url, m in parsed.items():
        if m:
            by_repo.setdefault((m[1], m[2]), []).append((url, int(m[3])))

    if by_repo:
        # Aliases keep one request for every repo and PR: r0 { p123: pullRequest(...) }.
        blocks = [
            f'r{i}: repository(owner: "{owner}", name: "{name}") {{ '
            + ' '.join(f'p{n}: pullRequest(number: {n}) {{ title state isDraft }}' for _, n in prs)
            + ' }'
            for i, ((owner, name), prs) in enumerate(by_repo.items())
        ]
        gh = shutil.which('gh') or '/opt/homebrew/bin/gh'
        try:
            result = subprocess.run(
                [gh, 'api', 'graphql', '-f', f"query=query {{ {' '.join(blocks)} }}"],
                capture_output=True,
                text=True,
                timeout=6,
            )
            data = json.loads(result.stdout).get('data') or {}
        except (OSError, ValueError, subprocess.SubprocessError):
            data = {}  # offline or gh not authed: fall back to whatever is cached

        for i, (_, prs) in enumerate(by_repo.items()):
            repo = data.get(f'r{i}') or {}
            for url, n in prs:
                pr = repo.get(f'p{n}')
                if not pr:
                    continue
                cache[url] = {
                    'title': pr.get('title', ''),
                    'state': 'DRAFT' if pr.get('isDraft') and pr.get('state') == 'OPEN' else pr.get('state', ''),
                    'fetched_at': now,
                }

        try:
            save_json(PRS_PATH, cache)
        except OSError:
            pass

    return {u: cache[u] for u in urls if u in cache}


def pr_lines(prs, width):
    """Preview lines: '#38731 merged  title', state colored, one per PR."""
    shown = prs[:PREVIEW_PRS]
    details = fetch_pr_details([url for _, url in shown])

    lines = []
    for number, url in shown:
        info = details.get(url)
        if not info:
            lines.append(f'\x1b[35m#{number}\x1b[0m \x1b[2m{url}\x1b[0m')
            continue

        color, label = PR_STATE_STYLE.get(info['state'], ('\x1b[2m', info['state'].lower()))
        prefix = f'#{number} {label:<6}  '
        title = info['title'][:max(10, width - len(prefix))]
        lines.append(f'\x1b[35m#{number}\x1b[0m {color}{label:<6}\x1b[0m  {title}')

    if len(prs) > PREVIEW_PRS:
        lines.append(f'\x1b[2m+{len(prs) - PREVIEW_PRS} more\x1b[0m')

    return lines


# ---------------------------------------------------------------------------
# rv review chats: PRs a chat is reviewing, shown in blue to tell them from PRs it made

REVIEW_COLOR = '\x1b[34m'
_reviews = None


def review_for(session):
    global _reviews
    if _reviews is None:
        _reviews = load_json(REVIEWS_PATH)

    return _reviews.get(session) if session else None


def review_summary(review):
    """'diff.html 2d ago · new commits · ✅ you, alice · ❌ bob' from rv's saved files."""
    saved = load_json(os.path.join(review.get('dir', ''), 'review.json'))
    html = load_json(os.path.join(review.get('dir', ''), 'html.json'))
    viewer = load_json(os.path.join(review.get('root', ''), 'pulls.json')).get('viewer', '')
    pull = saved.get('pull') or {}

    parts = []
    try:
        generated = os.path.getmtime(os.path.join(review['dir'], 'diff.html'))
        parts.append(f'diff.html {age(time.time() - generated)} ago')
    except (KeyError, OSError):
        parts.append('no diff.html yet')

    stale = html.get('headSha') and pull.get('sha') and html['headSha'] != pull['sha']
    if stale:
        parts.append('new commits since review')

    people = [p for p in pull.get('reviewers') or [] if not p.get('bot')]
    approved = sorted(
        ('you' if p['login'] == viewer else p['login'] for p in people if p.get('state') == 'APPROVED'),
        key=lambda login: login != 'you',
    )
    blocked = [p['login'] for p in people if p.get('state') == 'CHANGES_REQUESTED']
    if approved:
        parts.append('✅ ' + ', '.join(approved))
    if blocked:
        parts.append('❌ ' + ', '.join(blocked))

    return ' · '.join(parts)


def review_lines(review, width):
    """Preview lines for the PR an rv chat reviews: 'rv #37716 open  title' and its review state."""
    url = review['url']
    info = fetch_pr_details([url]).get(url) or {}
    color, label = PR_STATE_STYLE.get(info.get('state', ''), ('\x1b[2m', ''))
    prefix = f"rv #{review['number']} {label:<6}  "
    title = (info.get('title') or review.get('title', ''))[:max(10, width - len(prefix))]

    return [
        f"{REVIEW_COLOR}rv #{review['number']}\x1b[0m {color}{label:<6}\x1b[0m  {title}",
        f"\x1b[2m   {review_summary(review)[:max(10, width - 3)]}\x1b[0m",
    ]


def toggle_star(key):
    row = resolve_row(key)
    if not row or not row['session']:
        return  # shells and Codex windows without hook vars have no session to keep

    stars = load_stars()
    if row['session'] in stars:
        del stars[row['session']]
    else:
        stars[row['session']] = {
            'agent': row['agent'],
            'session': row['session'],
            'cwd': row['resume_cwd'],
            # Codex has no transcript to re-read later, so keep what we know now.
            'title': clean_title(row['title']),
            'prompt': row['prompt'],
            'starred_at': int(time.time()),
        }

    save_stars(stars)


# ---------------------------------------------------------------------------
# Claude transcripts: ~/.claude/projects/<project>/<session>.jsonl

# Claude appends {"type":"pr-link","prNumber":N,"prUrl":…} whenever a session
# creates or touches a PR, and {"type":"ai-title","aiTitle":…} as the topic changes.
PR_LINK = re.compile(rb'"type":"pr-link"[^\n]*?"prNumber":(\d+)[^\n]*?"prUrl":"([^"]+)"')
AI_TITLE = re.compile(rb'"type":"ai-title","aiTitle":("(?:[^"\\]|\\.)*")')
CWD = re.compile(rb'"cwd":("(?:[^"\\]|\\.)*")')


def prompt_text(entry):
    """Text you typed in a transcript user entry, or None for tool results and wrappers."""
    if entry.get('type') != 'user' or entry.get('isMeta'):
        return None

    content = (entry.get('message') or {}).get('content')
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

    return content


def reply_text(entry):
    if entry.get('type') != 'assistant':
        return None

    content = (entry.get('message') or {}).get('content') or []
    texts = [
        part.get('text', '')
        for part in content
        if isinstance(part, dict) and part.get('type') == 'text'
    ]

    return '\n'.join(texts).strip() or None


def entry_epoch(entry):
    # Transcript timestamps are ISO 8601 UTC with a trailing Z.
    stamp = entry.get('timestamp')
    if not stamp:
        return None
    try:
        return datetime.fromisoformat(stamp.replace('Z', '+00:00')).timestamp()
    except ValueError:
        return None


def read_file(path, windowed):
    """Whole file, or its first HEAD_BYTES plus last TAIL_BYTES."""
    with open(path, 'rb') as f:
        if not windowed:
            return f.read()

        head = f.read(HEAD_BYTES)
        f.seek(0, os.SEEK_END)
        size = f.tell()
        if size <= HEAD_BYTES + TAIL_BYTES:
            f.seek(0)
            return f.read()

        f.seek(size - TAIL_BYTES)
        # The newline keeps a partial line at the seam from merging into the head.
        return head + b'\n' + f.read()


def claude_transcript_path(session_id):
    paths = glob.glob(os.path.join(CLAUDE_PROJECTS, '*', f'{session_id}.jsonl'))

    return paths[0] if paths else None


def read_transcript(session_id, path=None, windowed=False):
    """Everything the picker needs from one read of a Claude transcript."""
    info = {
        'prompt': '',
        'prompt_at': None,
        'reply': '',
        'prs': [],
        'title': '',
        'start_cwd': '',
    }
    if not session_id:
        return info

    path = path or claude_transcript_path(session_id)
    if not path:
        return info

    try:
        data = read_file(path, windowed)
    except OSError:
        return info

    # dict keeps each PR's latest position; reverse for most recent first.
    links = {int(m[1]): m[2].decode() for m in PR_LINK.finditer(data)}
    info['prs'] = list(reversed(links.items()))

    titles = AI_TITLE.findall(data)
    if titles:
        info['title'] = json.loads(titles[-1])

    # `claude --resume` looks sessions up by the directory the session started in.
    first_cwd = CWD.search(data)
    if first_cwd:
        info['start_cwd'] = json.loads(first_cwd[1])

    # Walk back from the end; only decode lines that can hold what we want.
    for line in reversed(data.splitlines()):
        is_user = b'"type":"user"' in line
        is_reply = not info['reply'] and b'"type":"assistant"' in line
        if not (is_user or is_reply):
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue

        if is_reply:
            info['reply'] = reply_text(entry) or ''
            continue

        text = prompt_text(entry)
        if text:
            info['prompt'] = ' '.join(text.split())
            info['prompt_at'] = entry_epoch(entry)
            break

    return info


# ---------------------------------------------------------------------------
# Rows

def claude_pidfile(procs):
    """Claude writes ~/.claude/sessions/<pid>.json for each live interactive session."""
    for proc in procs:
        argv = proc.get('cmdline') or []
        is_claude = argv and os.path.basename(argv[0]) == 'claude'
        if not is_claude:
            continue

        path = os.path.join(HOME, '.claude', 'sessions', f"{proc['pid']}.json")
        try:
            with open(path) as f:
                return json.load(f)
        except (OSError, ValueError):
            return {}

    return {}


def detect_agent(procs):
    for proc in procs:
        argv = proc.get('cmdline') or []
        names = [os.path.basename(a) for a in argv[:2]]
        if 'claude' in names:
            return 'claude'
        if any(n.startswith('codex') for n in names):
            return 'codex'

    return None


def short_path(path):
    if path.startswith(HOME):
        return '~' + path[len(HOME):]

    return path


def shorten(text, width):
    if len(text) <= width:
        return text

    return '…' + text[-(width - 1):]


def clean_title(title):
    # Claude prefixes its terminal title with ✳ (idle) or a spinner frame.
    return title.lstrip('✳◐◑◒◓⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏ ')


def age(seconds):
    if seconds is None:
        return ''
    if seconds < 60:
        return f'{int(seconds)}s'
    if seconds < 3600:
        return f'{int(seconds / 60)}m'
    if seconds < 86400 * 2:
        return f'{int(seconds / 3600)}h'

    return f'{int(seconds / 86400)}d'


def named_window_id(tab):
    """The window a renamed tab's name belongs to: its only agent window, else its active one."""
    if not tab.get('title_overridden'):
        return None

    # Claude sets tab titles itself, prefixed with its ✳ / spinner glyph, and kitty
    # marks those overridden too. Only a name without that glyph is yours.
    if tab.get('title', '') != clean_title(tab.get('title', '')):
        return None

    windows = tab.get('windows') or []
    agents = [
        w for w in windows
        if (w.get('user_vars') or {}).get('agent') or detect_agent(w.get('foreground_processes') or [])
    ]
    if len(agents) == 1:
        return agents[0]['id']

    active = [w for w in windows if w.get('is_active')]

    return active[0]['id'] if active else None


def window_row(tab_label, w, now, stars, tab_name=None, names=None):
    uv = w.get('user_vars') or {}
    procs = w.get('foreground_processes') or []

    agent = uv.get('agent') or detect_agent(procs)
    pidfile = claude_pidfile(procs) if agent == 'claude' else {}

    status = uv.get('agent_status')
    if not status and pidfile.get('status') in ('busy', 'working'):
        status = 'working'
    if not status and agent:
        status = 'idle'
    if not status:
        status = 'shell'

    session = uv.get('agent_session') or pidfile.get('sessionId') or ''
    cwd = uv.get('agent_cwd') or w.get('cwd') or ''
    transcript = read_transcript(session) if agent == 'claude' else read_transcript('')

    # Hook vars are freshest; prompts stored before agent_prompt_at existed
    # have no time, and the transcript has both.
    prompt = uv.get('agent_prompt') or ''
    prompt_at = int(uv['agent_prompt_at']) if uv.get('agent_prompt_at') else None
    if not prompt or not prompt_at:
        prompt = transcript['prompt']
        prompt_at = transcript['prompt_at']

    return {
        'key': str(w['id']),
        'tab': tab_label,
        'agent': agent or 'shell',
        'status': status,
        'since': now - prompt_at if prompt_at else None,  # seconds since your last prompt
        # Chat name > leftover kitty tab name > generated title (AGENTS_SPEC.md).
        'title': (names or {}).get(session) or tab_name or w.get('title', ''),
        'tab_name': tab_name,
        'cwd': short_path(cwd),
        'resume_cwd': transcript['start_cwd'] or cwd,
        'session': session,
        'starred': bool(session) and session in stars,
        'prompt': prompt,
        'reply': transcript['reply'],
        'prs': transcript['prs'],
        'review': review_for(session),
        'is_self': w.get('is_self', False),
        # fzf's argv carries the preview command, which names this file.
        'is_picker': any(
            'agents.py' in ' '.join(proc.get('cmdline') or [])
            for proc in procs
        ),
    }


def dormant_row(star, now, names=None):
    session = star['session']
    names = load_names() if names is None else names
    transcript = read_transcript(session) if star['agent'] == 'claude' else read_transcript('')

    prompt = transcript['prompt'] or star.get('prompt', '')
    prompt_at = transcript['prompt_at'] or star.get('starred_at')
    cwd = transcript['start_cwd'] or star.get('cwd', '')

    return {
        'key': f's:{session}',
        'tab': '–',
        'agent': star['agent'],
        'status': 'dormant',
        'since': now - prompt_at if prompt_at else None,
        'title': names.get(session) or transcript['title'] or star.get('title', ''),
        'tab_name': None,
        'cwd': short_path(cwd),
        'resume_cwd': cwd,
        'session': session,
        'starred': True,
        'prompt': prompt,
        'reply': transcript['reply'],
        'prs': transcript['prs'],
        'review': review_for(session),
        'is_self': False,
        'is_picker': False,
    }


def codex_text(payload):
    parts = payload.get('content') or []
    return ' '.join(
        part.get('text', '')
        for part in parts
        if isinstance(part, dict) and part.get('type') in ('input_text', 'output_text', 'text')
    ).strip()


def read_rollout(path):
    """Session meta, first/last prompt, and last reply from a Codex rollout file."""
    info = {
        'session': '',
        'cwd': '',
        'interactive': False,
        'first_prompt': '',
        'prompt': '',
        'prompt_at': None,
        'reply': '',
    }
    try:
        data = read_file(path, windowed=True)
    except OSError:
        return info

    lines = data.splitlines()
    for line in lines:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        payload = entry.get('payload') or {}

        if entry.get('type') == 'session_meta':
            info['session'] = payload.get('id', '')
            info['cwd'] = payload.get('cwd', '')
            # codex-tui is an interactive session; codex_exec and wrappers are scripted.
            info['interactive'] = payload.get('originator') in ('codex-tui', 'codex_cli_rs')
            continue

        if entry.get('type') != 'response_item' or payload.get('type') != 'message':
            continue

        text = codex_text(payload)
        # Injected context arrives as user messages: tagged environment blocks
        # and "# AGENTS.md instructions for …" with an <INSTRUCTIONS> body.
        is_injected = text.startswith(('<', '# AGENTS.md')) or '<INSTRUCTIONS>' in text
        if not text or is_injected:
            continue

        if payload.get('role') == 'user':
            info['first_prompt'] = info['first_prompt'] or text
            info['prompt'] = text
            info['prompt_at'] = entry_epoch(entry)
        elif payload.get('role') == 'assistant':
            info['reply'] = text

    info['prompt'] = ' '.join(info['prompt'].split())

    return info


def claude_history(cutoff):
    """(mtime, row-builder) for interactive Claude transcripts modified since cutoff."""
    found = []
    for path in glob.glob(os.path.join(CLAUDE_PROJECTS, '*', '*.jsonl')):
        try:
            mtime = os.stat(path).st_mtime
        except OSError:
            continue
        if mtime < cutoff:
            continue
        found.append((mtime, 'claude', path))

    return found


def codex_history(cutoff):
    found = []
    for path in glob.glob(os.path.join(CODEX_SESSIONS, '*', '*', '*', 'rollout-*.jsonl')):
        try:
            mtime = os.stat(path).st_mtime
        except OSError:
            continue
        if mtime < cutoff:
            continue
        found.append((mtime, 'codex', path))

    return found


def is_scripted_claude(path):
    # `claude -p` and SDK runs record entrypoint "sdk-cli"; interactive ones "cli".
    try:
        with open(path, 'rb') as f:
            head = f.read(HEAD_BYTES)
    except OSError:
        return True

    return b'"entrypoint":"sdk-cli"' in head


def history_row(agent, path, now, stars, names=None):
    names = load_names() if names is None else names
    if agent == 'claude':
        session = os.path.basename(path)[:-len('.jsonl')]
        t = read_transcript(session, path=path, windowed=True)
        title = t['title']
        prompt, prompt_at, reply, prs, cwd = t['prompt'], t['prompt_at'], t['reply'], t['prs'], t['start_cwd']
    else:
        r = read_rollout(path)
        review = review_for(r['session'])
        # rv starts review chats through codex app-server, so they are not TUI-originated.
        if not r['session'] or not (r['interactive'] or review):
            return None
        session = r['session']
        # Codex has no generated title; the opening prompt describes the session,
        # except for review chats, which open with rv's instructions.
        title = review['title'] if review else ' '.join(r['first_prompt'].split())[:60]
        prompt, prompt_at, reply, prs, cwd = r['prompt'], r['prompt_at'], r['reply'], [], r['cwd']

    # Review chats stay listed even when their last prompt sits outside the read window.
    if not prompt and not review_for(session):
        return None  # opened and closed without a message

    return {
        'key': f'h:{agent}:{session}',
        'tab': '–',
        'agent': agent,
        'status': 'closed',
        'since': now - prompt_at if prompt_at else None,
        'title': names.get(session) or title,
        'tab_name': None,
        'cwd': short_path(cwd),
        'resume_cwd': cwd,
        'session': session,
        'starred': session in stars,
        'prompt': prompt,
        'reply': reply,
        'prs': prs,
        'review': review_for(session),
        'is_self': False,
        'is_picker': False,
    }


def open_sessions():
    raw = remote('ls')
    sessions = set()
    for os_window in json.loads(raw):
        for tab in os_window['tabs']:
            for w in tab['windows']:
                uv = w.get('user_vars') or {}
                procs = w.get('foreground_processes') or []
                session = uv.get('agent_session') or claude_pidfile(procs).get('sessionId')
                if session:
                    sessions.add(session)

    return sessions


def collect_history():
    """Recently closed sessions: newest transcripts with no open window."""
    now = time.time()
    stars = load_stars()
    names = load_names()
    live = open_sessions()
    cutoff = now - HISTORY_DAYS * 86400

    candidates = sorted(claude_history(cutoff) + codex_history(cutoff), reverse=True)

    rows = []
    for _, agent, path in candidates:
        if len(rows) >= HISTORY_LIMIT:
            break
        session_hint = os.path.basename(path)[:-len('.jsonl')]
        # rv generates Claude reviews with `claude -p`, then resumes them interactively.
        scripted = agent == 'claude' and is_scripted_claude(path) and not review_for(session_hint)
        if agent == 'claude' and session_hint in live or scripted:
            continue

        row = history_row(agent, path, now, stars, names)
        if row and row['session'] not in live:
            rows.append(row)

    return sorted(rows, key=lambda r: r['since'] if r['since'] is not None else float('inf'))


def collect(agents_only=False, recent=False):
    raw = remote('ls')
    now = time.time()
    stars = load_stars()
    names = load_names()

    os_windows = json.loads(raw)
    multiple = len(os_windows) > 1

    # Label tabs by position (what cmd+1..9 jumps to), not kitty's internal id.
    # Prefix the OS window number only when there is more than one.
    live = [
        window_row(
            f'{oi}.{ti}' if multiple else str(ti),
            w,
            now,
            stars,
            tab_name=tab['title'] if w['id'] == named_window_id(tab) else None,
            names=names,
        )
        for oi, os_window in enumerate(os_windows, 1)
        for ti, tab in enumerate(os_window['tabs'], 1)
        for w in tab['windows']
    ]

    try:
        adopt_tab_names(live)
    except (OSError, subprocess.SubprocessError):
        pass  # losing name adoption must not break the list

    # Sessions open anywhere, including the window this list runs from, are not dormant.
    open_sessions = {r['session'] for r in live if r['session']}

    # Hide the picker's own overlay window, including one open from another tab.
    live = [r for r in live if not (r['is_self'] or r['is_picker'])]

    if agents_only:
        live = [r for r in live if r['agent'] != 'shell']

    dormant = [
        dormant_row(star, now, names)
        for session, star in stars.items()
        if session not in open_sessions
    ]

    if recent:
        # Newest message first; rows with no known message sink to the bottom.
        return sorted(live + dormant, key=lambda r: r['since'] if r['since'] is not None else float('inf'))

    # kitty @ ls already lists tabs and windows in tab-bar order; dormant rows follow.
    return live + dormant


def resolve_row(key):
    now = time.time()
    stars = load_stars()

    if key.startswith('s:'):
        star = stars.get(key[2:])
        return dormant_row(star, now) if star else None

    if key.startswith('h:'):
        _, agent, session = key.split(':', 2)
        if agent == 'claude':
            path = claude_transcript_path(session)
        else:
            paths = glob.glob(os.path.join(CODEX_SESSIONS, '*', '*', '*', f'rollout-*{session}.jsonl'))
            path = paths[0] if paths else None
        return history_row(agent, path, now, stars) if path else None

    try:
        # --match-tab returns the whole tab, so the tab name maps to the right window.
        tab = json.loads(remote('ls', '--match-tab', f'window_id:{key}'))[0]['tabs'][0]
        w = next(w for w in tab['windows'] if str(w['id']) == key)
        tab_name = tab['title'] if w['id'] == named_window_id(tab) else None
        return window_row('', w, now, stars, tab_name, load_names())
    except (IndexError, KeyError, ValueError, StopIteration, OSError, subprocess.SubprocessError):
        return None


def format_row(r):
    # Field 1 (row key) is hidden by fzf's --with-nth and used for preview and actions.
    # The session id sits last so it is searchable without crowding the view.
    star = '\x1b[33m★\x1b[0m ' if r['starred'] else '  '
    title = clean_title(r['title'])[:40]
    prompt = f"❯ {r['prompt'][:70]}" if r['prompt'] else ''

    # Latest PR, plus a count of any others the session touched.
    prs = r['prs']
    pr = f'#{prs[0][0]}' + (f' +{len(prs) - 1}' if len(prs) > 1 else '') if prs else ''
    pr_color = '\x1b[35m'
    if not prs and r.get('review'):
        pr = f"rv#{r['review']['number']}"
        pr_color = REVIEW_COLOR

    cols = [
        r['key'],
        f"\x1b[1m{r['tab']:>3}\x1b[0m",
        STATUS_GLYPH.get(r['status'], r['status']),
        f"{age(r['since']):>4}",
        f"\x1b[36m{r['agent']:<6}\x1b[0m",
        f"{pr_color}{pr:<9}\x1b[0m",
        f'{star}{title:<40}',
        f"\x1b[3m{prompt:<72}\x1b[0m",
        f"\x1b[2m{shorten(r['cwd'], 40)}\x1b[0m",
        f"\x1b[2m{r['session'][:8]}\x1b[0m",
    ]

    return '\t'.join(cols)


def print_list(agents_only, recent, history=False):
    try:
        rows = collect_history() if history else collect(agents_only, recent)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f'0\tcould not read kitty windows: {error}')
        return

    for r in rows:
        print(format_row(r))


def wrap(text, width, max_lines):
    lines = []
    for paragraph in text.splitlines() or ['']:
        lines += [paragraph[i:i + width] for i in range(0, max(len(paragraph), 1), width)]

    return lines[:max_lines]


def print_preview(key):
    height = int(os.environ.get('FZF_PREVIEW_LINES', '40'))
    width = int(os.environ.get('FZF_PREVIEW_COLUMNS', '100'))
    rule = '\x1b[2m' + '─' * width + '\x1b[0m'

    row = resolve_row(key)
    if row is None:
        return

    header = []
    if row['prompt']:
        # Full last prompt on top, capped at 4 lines so the screen stays visible.
        header = [
            ('\x1b[1;36m❯\x1b[0m ' if i == 0 else '  ') + f'\x1b[1m{line}\x1b[0m'
            for i, line in enumerate(wrap(row['prompt'], width - 2, 4))
        ]

    if row.get('review'):
        header.extend(review_lines(row['review'], width))

    if row['prs']:
        header.extend(pr_lines(row['prs'], width))

    if header:
        header.append(rule)

    if row['status'] in ('dormant', 'closed'):
        # No window to capture; show where it resumes and how the session ended.
        label = '\x1b[34m◌ dormant\x1b[0m' if row['status'] == 'dormant' else '\x1b[2m↺ closed\x1b[0m'
        star_hint = 'ctrl-s unstars' if row['starred'] else 'ctrl-s stars'
        body = [
            f"{label} · enter resumes in a new tab · {star_hint}",
            f"\x1b[2m{row['agent']} {row['session']}  in  {row['cwd']}\x1b[0m",
            rule,
            *wrap(row['reply'] or '(no reply recorded)', width, height),
        ]
        print('\n'.join((header + body)[:height]))
        return

    text = remote('get-text', '--match', f'id:{key}', '--extent', 'screen', '--ansi')
    lines = text.rstrip().splitlines()

    # Agent TUIs keep the latest output and input box at the bottom.
    body = lines[-max(1, height - len(header)):]
    print('\n'.join(header + body))


def open_pr(key):
    row = resolve_row(key)
    if not row:
        return

    url = row['prs'][0][1] if row['prs'] else (row.get('review') or {}).get('url')
    if url:
        subprocess.run(['open', url], check=False)


def resume_command(row):
    """(cwd, title, shell argv) that resumes a dormant or closed session in a fresh tab."""
    shell = os.environ.get('SHELL', '/bin/zsh')
    # Resumed sessions run without permission prompts. `command` skips the
    # shell's claude alias, which would add the same flag a second time.
    resume = {
        'claude': f"command claude --dangerously-skip-permissions --resume {row['session']}",
        'codex': f"codex resume --dangerously-bypass-approvals-and-sandbox {row['session']}",
    }[row['agent']]

    title = clean_title(row['title']) or f"{row['agent']} {row['session'][:8]}"

    # An interactive shell loads the full PATH (nvm, Homebrew); stay in it on exit.
    return row['resume_cwd'] or HOME, title, [shell, '-ic', f'{resume}; exec {shell} -l']


# ---------------------------------------------------------------------------
# fzf

# The fzf prompt carries the view state, e.g. "all · recent> ", so key bindings
# can compute the next view without any state file.
SCOPES = ('all', 'agents', 'history')
SORTS = ('recent', 'tab')  # first entry is the default view


def view_prompt(scope, sort):
    return f'{scope} · {sort}> '


def parse_prompt(prompt):
    scope, _, sort = prompt.rstrip('> ').partition(' · ')
    scope = scope if scope in SCOPES else SCOPES[0]
    sort = sort if sort in SORTS else SORTS[0]

    return scope, sort


def print_action(action, list_cmd):
    scope, sort = parse_prompt(os.environ.get('FZF_PROMPT', ''))

    # ctrl-a flips all/agents (leaving history), ctrl-h flips history/all.
    if action == 'scope':
        scope = 'agents' if scope == 'all' else 'all'
    elif action == 'history':
        scope = 'all' if scope == 'history' else 'history'
    elif action == 'sort':
        sort = SORTS[(SORTS.index(sort) + 1) % len(SORTS)]

    flags = ''
    if scope == 'agents':
        flags += ' --agents'
    if scope == 'history':
        flags += ' --history'  # always newest first
    if sort == 'recent':
        flags += ' --recent'

    print(f'change-prompt({view_prompt(scope, sort)})+reload({list_cmd}{flags})')


def _location():
    pass


def pick(script):
    """Run fzf over the rows and return the chosen row key, or None."""
    # kitty's bundled python: no PATH or pyenv dependency, and faster startup.
    runner = f'{KITTY} +launch {script}'
    action_cmd = f'{runner} --action'

    header = 'enter focus/resume · ctrl-s star · ctrl-h history · ctrl-g PR · tab sort · ctrl-a all/agents · ctrl-r refresh'
    # Kitty launched from the Dock may not have Homebrew on PATH.
    fzf_bin = shutil.which('fzf') or '/opt/homebrew/bin/fzf'
    fzf = [
        fzf_bin,
        '--ansi',
        '--no-sort',
        '--layout=reverse',
        '--delimiter=\t',
        '--with-nth=2..',
        '--tabstop=1',
        f'--header={header}',
        f'--prompt={view_prompt(SCOPES[0], SORTS[0])}',
        f'--preview={runner} --preview {{1}}',
        '--preview-window=down,60%,border-top,follow',
        f'--bind=tab:transform:{action_cmd} sort',
        f'--bind=ctrl-s:execute-silent({runner} --star {{1}})+transform:{action_cmd} refresh',
        f'--bind=ctrl-g:execute-silent({runner} --open-pr {{1}})',
        f'--bind=ctrl-a:transform:{action_cmd} scope',
        f'--bind=ctrl-h:transform:{action_cmd} history',
        f'--bind=ctrl-r:transform:{action_cmd} refresh',
    ]

    listing = subprocess.run(
        [KITTY, '+launch', script, '--list', '--recent'],
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


# ---------------------------------------------------------------------------
# kitten entry points

def main(args):
    # Kitty execs kitten source without __file__; a function's code object
    # still records the real path.
    script = os.path.realpath(_location.__code__.co_filename)

    return pick(script)


def handle_result(args, answer, target_window_id, boss):
    if not answer:
        return

    if answer.isdecimal():
        w = boss.window_id_map.get(int(answer))
        if w is not None:
            boss.set_active_window(w, switch_os_window_if_needed=True)
        return

    if answer.startswith(('s:', 'h:')):
        row = resolve_row(answer)
        if row is None:
            return

        # No tab name: the tab bar shows the chat's name from names.json (or its
        # generated title) once the SessionStart hook tags the window.
        cwd, _, argv = resume_command(row)
        boss.call_remote_control(None, ('launch', '--type=tab', '--cwd', cwd, *argv))


if __name__ == '__main__':
    command = sys.argv[1] if len(sys.argv) > 1 else ''
    this = os.path.realpath(sys.argv[0])

    if command == '--list':
        print_list('--agents' in sys.argv, '--recent' in sys.argv, '--history' in sys.argv)
    elif command == '--action' and len(sys.argv) > 2:
        print_action(sys.argv[2], f'{KITTY} +launch {this} --list')
    elif command == '--preview' and len(sys.argv) > 2:
        print_preview(sys.argv[2])
    elif command == '--open-pr' and len(sys.argv) > 2:
        open_pr(sys.argv[2])
    elif command == '--star' and len(sys.argv) > 2:
        toggle_star(sys.argv[2])
