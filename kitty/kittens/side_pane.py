"""
Side pane kitten for kitty.
Opens a 20% right pane if only one window exists, otherwise focuses the right pane.

Usage in kitty.conf:
    map kitty_mod+\\ kitten side_pane.py
"""

from kittens.tui.handler import result_handler


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    tab = boss.active_tab
    if tab is None:
        return

    windows = tab.windows

    SIDE_PANE_TITLE = 'side-pane'

    # Check if side pane already exists
    side_pane = None
    for w in windows:
        if w.title == SIDE_PANE_TITLE or w.user_vars.get('is_side_pane'):
            side_pane = w
            break

    if side_pane:
        tab.set_active_window(side_pane)
    elif len(windows) == 1:
        boss.call_remote_control(None, (
            'launch', '--location=vsplit', '--cwd=current', '--bias=30',
            '--var', 'is_side_pane=true', '--title', SIDE_PANE_TITLE
        ))
