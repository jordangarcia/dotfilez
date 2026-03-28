"""
Toggle dev-cli tab for the current kt69 session.

First press: create a new tab "[dev] branch" running dev-cli.
Subsequent presses: toggle focus between dev tab and session tab.

Usage in kitty.conf:
    map cmd+shift+d kitten kt69/kittens/kt69_dev.py
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

    import os

    offset = kt69_lib.get_offset_from_window(window)
    branch, session = kt69_lib.get_session_from_window(window)

    if offset is None:
        offset = 0
    if session:
        worktree = session['worktree_path']
    else:
        worktree = os.path.expanduser('~/code/gamma')
        branch = branch or 'gamma'

    # Check if dev tab already exists (any window with kt69_dev_tab for this branch)
    dev_window = None
    dev_tab = None
    session_tab = None
    for osw in boss.os_window_map.values():
        for t in osw.tabs:
            for w in t.windows:
                if (w.user_vars.get('kt69_dev_tab')
                        and w.user_vars.get('kt69_branch') == branch):
                    dev_window = w
                    dev_tab = t
                if (w.user_vars.get('kt69_branch') == branch
                        and not w.user_vars.get('kt69_dev_tab')):
                    session_tab = t

    if dev_tab:
        # Dev tab exists — toggle between dev tab and session tab
        active_tab = boss.active_tab
        if active_tab is dev_tab:
            # On dev tab, go back to session tab
            if session_tab:
                boss.call_remote_control(None, (
                    'focus-tab', '-m', f'id:{session_tab.id}'
                ))
        else:
            # Go to dev tab
            boss.call_remote_control(None, (
                'focus-tab', '-m', f'id:{dev_tab.id}'
            ))
    else:
        # Create dev tab
        boss.call_remote_control(None, (
            'launch', '--type=tab',
            f'--tab-title=[dev] {branch[:20]}',
            f'--cwd={worktree}',
            '--var', f'kt69_branch={branch}',
            '--var', f'kt69_offset={offset}',
            '--var', f'kt69_worktree={worktree}',
            '--var', 'kt69_dev_tab=true',
            '--env', f'KT69_BRANCH={branch}',
            '--env', f'KT69_OFFSET={offset}',
            '--env', f'KT69_WORKTREE={worktree}',
        ))

        boss.call_remote_control(None, (
            'send-text', '-m', 'recent:0',
            f'yarn dev-cli start --offset {offset}\r'
        ))
