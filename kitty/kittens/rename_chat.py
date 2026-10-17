"""
Rename the agent chat in the focused window (plain tabs fall back to kitty's tab rename).

Usage in kitty.conf:
    map kitty_mod+r kitten kittens/rename_chat.py

The name belongs to the chat (its session id), not the tab: it is saved in
~/.local/state/kitty-agents/names.json, which the tab bar and the agents picker
read. A new chat in the same tab shows its own title; resuming a renamed chat
brings the name back. Submitting an empty name clears it, falling back to the
chat's generated title. See kitty/AGENTS_SPEC.md.
"""

import importlib.util
import os

from kittens.tui.handler import result_handler


def _location():
    pass


def load_agents():
    # Kitty execs kitten source without __file__; import the sibling picker
    # module by path so all agent kittens share one store and one set of rules.
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
        # No chat here: behave like kitty's own set_tab_title.
        boss.set_tab_title()
        return

    names = agents.load_names()
    transcript = agents.read_transcript(session) if agent == 'claude' else agents.read_transcript('')
    generated = transcript['title'] or agents.clean_title(w.title)
    current = names.get(session) or generated

    def save(name):
        # get_line skips the callback on cancel; an empty submit clears the name.
        latest = agents.load_names()
        name = (name or '').strip()
        if name:
            latest[session] = name
        else:
            latest.pop(session, None)
        agents.save_names(latest)

        # Drop any kitty tab name so the tab carries no name of its own; the
        # tab bar reads the chat name from names.json. set_title('') resets it.
        tab = w.tabref()
        if tab is not None:
            if tab.name:
                tab.set_title('')
            tab.mark_tab_bar_dirty()

    boss.get_line(
        'Rename this chat. An empty name goes back to the generated title.',
        save,
        window=w,
        initial_value=current,
        window_title='Rename chat',
    )
