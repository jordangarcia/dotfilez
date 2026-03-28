"""
Attach to dev-cli TUI for the current kt69 session in an overlay.

Usage in kitty.conf:
    map cmd+shift+g kitten kt69/kittens/kt69_attach.py
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

    offset = session['port_offset']
    worktree = session['worktree_path']

    boss.call_remote_control(None, (
        'launch', '--type=overlay',
        f'--cwd={worktree}',
        'yarn', 'dev-cli', 'attach', '--offset', str(offset)
    ))
