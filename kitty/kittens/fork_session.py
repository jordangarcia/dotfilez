"""
Fork the Claude session in the focused window into a sibling split.

Usage in kitty.conf:
    map cmd+shift+f kitten kittens/fork_session.py

Runs `claude --resume <id> --fork-session` with the original launch flags, so
the fork keeps the conversation and permission mode but writes a new session.
Adapted from loganlinn/dotfiles config/kitty/fork.py.
"""

import importlib.util
import os

from kittens.tui.handler import result_handler

FLAGS_WITH_VALUE = frozenset({'--resume', '-r', '--session-id'})
FLAGS_STANDALONE = frozenset({'--fork-session', '--continue', '-c'})


def _location():
    pass


def load_agents():
    # Kitty execs kitten source without __file__; import the sibling picker
    # module by path to share its session lookup.
    here = os.path.dirname(os.path.realpath(_location.__code__.co_filename))
    spec = importlib.util.spec_from_file_location('kitty_agents', os.path.join(here, 'agents.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def strip_session_flags(argv):
    result = []
    skip_next = False
    for i, arg in enumerate(argv):
        if skip_next:
            skip_next = False
            continue

        if arg in FLAGS_STANDALONE:
            continue

        if arg in FLAGS_WITH_VALUE:
            has_value = i + 1 < len(argv) and not argv[i + 1].startswith('-')
            skip_next = has_value
            continue

        if any(arg.startswith(f + '=') for f in FLAGS_WITH_VALUE):
            continue

        result.append(arg)

    return result


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    w = boss.window_id_map.get(target_window_id) or boss.active_window
    if w is None:
        return

    agents = load_agents()

    procs = list(w.child.foreground_processes)
    claude_proc = next(
        (p for p in procs if os.path.basename((p.get('cmdline') or [''])[0]) == 'claude'),
        None,
    )
    if claude_proc is None:
        boss.show_error('fork', 'No claude process in this window')
        return

    pidfile = agents.claude_pidfile(procs)
    session = w.user_vars.get('agent_session') or pidfile.get('sessionId') or ''
    if not session:
        boss.show_error('fork', 'Could not find the Claude session id for this window')
        return

    cmd = strip_session_flags(list(claude_proc['cmdline']))
    cmd.extend(['--resume', session, '--fork-session'])

    cwd = pidfile.get('cwd') or claude_proc.get('cwd') or w.cwd_of_child or ''

    from kitty.launch import launch, parse_launch_args

    opts, _ = parse_launch_args(['--type=window', '--location=vsplit', '--copy-env', *args[1:]])
    opts.source_window = f'id:{w.id}'
    opts.next_to = opts.source_window
    opts.cwd = cwd
    launch(boss, opts, cmd, target_tab=w.tabref(), rc_from_window=w)
