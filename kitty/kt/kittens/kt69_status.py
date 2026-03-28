"""
Show kt69 status overlay for the current session.

Launches kt69 status as an overlay window, showing PR state, dev-cli status,
branch info. Press any key to dismiss.

Usage in kitty.conf:
    map cmd+shift+s kitten kt69/kittens/kt69_status.py
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

    branch = window.user_vars.get('kt69_branch') if window else None
    if not branch:
        return

    boss.call_remote_control(None, (
        'launch', '--type=overlay',
        'kt69', 'status', branch
    ))
