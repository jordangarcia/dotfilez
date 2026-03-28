"""
Open kt69 command menu as a centered overlay.

Usage in kitty.conf:
    map cmd+shift+k kitten kt69/kittens/kt69_menu.py
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

    offset = kt69_lib.get_offset_from_window(window)
    worktree = session['worktree_path'] if session else ''

    menu_script = os.path.expanduser('~/.config/kitty/kt/kt69-menu.sh')

    boss.call_remote_control(None, (
        'launch', '--type=overlay',
        '--env', f'KT69_BRANCH={branch}',
        '--env', f'KT69_OFFSET={offset}',
        '--env', f'KT69_WORKTREE={worktree}',
        'bash', menu_script
    ))
