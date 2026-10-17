"""
Star / unstar the agent session in the focused window.

Usage in kitty.conf:
    map cmd+shift+s kitten kittens/star_session.py

Uses the same star file as the agents picker (kittens/agents.py), so starred
sessions show a ★ in the tab bar and stay in the picker as dormant rows after
their window closes.
"""

import importlib.util
import os
import time

from kittens.tui.handler import result_handler


def _location():
    pass


def load_agents():
    # Kitty execs kitten source without __file__; import the sibling picker
    # module by path so both kittens share one star store and one set of rules.
    here = os.path.dirname(os.path.realpath(_location.__code__.co_filename))
    spec = importlib.util.spec_from_file_location('kitty_agents', os.path.join(here, 'agents.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    w = boss.window_id_map.get(target_window_id) or boss.active_window
    if w is None:
        return

    agents = load_agents()

    # Read window state directly. Calling `kitten @` from here would wait on the
    # remote-control loop this handler is running on.
    procs = list(w.child.foreground_processes)
    agent = w.user_vars.get('agent') or agents.detect_agent(procs)
    pidfile = agents.claude_pidfile(procs) if agent == 'claude' else {}
    session = w.user_vars.get('agent_session') or pidfile.get('sessionId') or ''

    if not agent or not session:
        return

    transcript = agents.read_transcript(session) if agent == 'claude' else agents.read_transcript('')
    title = agents.load_names().get(session) or transcript['title'] or agents.clean_title(w.title)

    stars = agents.load_stars()
    if session in stars:
        del stars[session]
    else:
        stars[session] = {
            'agent': agent,
            'session': session,
            'cwd': transcript['start_cwd'] or w.user_vars.get('agent_cwd') or w.cwd_of_child or '',
            'title': title,
            'prompt': w.user_vars.get('agent_prompt') or transcript['prompt'],
            'starred_at': int(time.time()),
        }

    agents.save_stars(stars)

    # The tab bar re-reads the star file on its 1s timer; redraw now instead.
    tab = w.tabref()
    if tab is not None:
        tab.mark_tab_bar_dirty()
