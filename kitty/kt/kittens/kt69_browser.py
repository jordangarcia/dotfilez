"""
Open browser at the current kt69 session's client port.

Usage in kitty.conf:
    map cmd+shift+b kitten kt69/kittens/kt69_browser.py
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

    offset = kt69_lib.get_offset_from_window(window) or 0

    port = 3000 + offset
    subprocess.Popen(['open', f'https://localhost:{port}'])
