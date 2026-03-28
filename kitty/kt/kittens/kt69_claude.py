"""
Launch a Claude overlay in the current kt69 session's worktree.

Usage in kitty.conf:
    map cmd+shift+a kitten kt69/kittens/kt69_claude.py
"""

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
    if session is None:
        return

    worktree = session['worktree_path']

    boss.call_remote_control(None, (
        'launch', '--type=overlay',
        f'--cwd={worktree}',
        'claude'
    ))
