"""
Pick a claude session for this branch and resume it in the CC pane.

Usage in kitty.conf:
    map cmd+shift+t kitten kt69/kittens/kt69_trs.py
"""

import os
from kittens.tui.handler import result_handler
import kt69_lib


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    branch, session = kt69_lib.get_session_from_window(window)
    if branch is None:
        return

    worktree = session['worktree_path'] if session else ''
    picker = os.path.expanduser('~/.config/kitty/kt69/kt69-trs-pick.sh')

    boss.call_remote_control(None, (
        'launch', '--type=overlay',
        '--env', f'KT69_BRANCH={branch}',
        '--env', f'KT69_WORKTREE={worktree}',
        picker
    ))
