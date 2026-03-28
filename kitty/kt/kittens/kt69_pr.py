"""
Open or create a PR for the current kt69 session's branch.

Usage in kitty.conf:
    map cmd+shift+p kitten kt69/kittens/kt69_pr.py open
    map cmd+shift+c kitten kt69/kittens/kt69_pr.py create
"""

import subprocess
from kittens.tui.handler import result_handler
import kt69_lib


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    # args[0] is the script path, args[1] is the action
    action = args[1] if len(args) > 1 else 'open'

    branch, session = kt69_lib.get_session_from_window(window)
    if session is None:
        return

    worktree = session['worktree_path']

    if action == 'open':
        subprocess.Popen(
            ['gh', 'pr', 'view', '--web'],
            cwd=worktree
        )
    elif action == 'create':
        boss.call_remote_control(None, (
            'launch', '--type=overlay',
            f'--cwd={worktree}',
            'gh', 'pr', 'create', '--web'
        ))
