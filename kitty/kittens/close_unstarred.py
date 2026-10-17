"""
Close every window except starred agent sessions and agents still working.

Usage in kitty.conf:
    map cmd+shift+o kitten kittens/close_unstarred.py

Lists what will close and what stays, then asks for confirmation. Stars come
from the agents picker store (kittens/agents.py); "working" means an agent is
mid-turn or waiting on a permission prompt (agent_status from the hooks).
Tabs and OS windows left empty close with their last window.
"""

import importlib.util
import os

KEEP_STATUSES = ('working', 'attention')


def _location():
    pass


def load_agents():
    # Kitty execs kitten source without __file__; import the sibling picker
    # module by path so all agent kittens share one set of rules.
    here = os.path.dirname(os.path.realpath(_location.__code__.co_filename))
    spec = importlib.util.spec_from_file_location('kitty_agents', os.path.join(here, 'agents.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def describe(agents, row):
    title = agents.clean_title(row['title'])[:50]
    star = '\x1b[33m★\x1b[0m' if row['starred'] else ' '
    status = agents.STATUS_GLYPH.get(row['status'], row['status'])

    return f"  {row['tab']:>3}  {status} {star} {title:<50} \x1b[2m{row['cwd']}\x1b[0m"


def main(args):
    agents = load_agents()

    try:
        rows = agents.collect()
    except Exception as error:
        print(f'Could not read kitty windows: {error}')
        input('Press Enter to quit')
        return None

    # collect() also returns starred sessions with no window; nothing to close there.
    live = [r for r in rows if r['status'] != 'dormant']
    keep = [r for r in live if r['starred'] or r['status'] in KEEP_STATUSES]
    close = [r for r in live if r not in keep]

    print('\x1b[1mKeep\x1b[0m')
    for r in keep:
        print(describe(agents, r))
    if not keep:
        print('  \x1b[2m(nothing)\x1b[0m')

    print('\n\x1b[1;31mClose\x1b[0m')
    for r in close:
        print(describe(agents, r))

    if not close:
        print('  \x1b[2m(nothing)\x1b[0m')
        input('\nNothing to close. Press Enter to quit')
        return None

    answer = input(f'\nClose {len(close)} window(s)? [y/N] ').strip().lower()
    if answer != 'y':
        return None

    return ','.join(r['key'] for r in close)


def handle_result(args, answer, target_window_id, boss):
    if not answer:
        return

    for key in answer.split(','):
        w = boss.window_id_map.get(int(key)) if key.isdecimal() else None
        if w is not None:
            # Already confirmed in the kitten, so skip kitty's own close prompt.
            boss.mark_window_for_close(w)
