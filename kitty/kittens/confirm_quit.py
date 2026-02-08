"""
Quit confirmation kitten for kitty.
Prompts before quitting the entire app.

Usage in kitty.conf:
    map cmd+q kitten confirm_quit.py
"""

from kittens.tui.handler import result_handler


def main(args):
    print("Quit kitty? [Y/n] ", end="", flush=True)
    answer = input().strip().lower()
    return answer


@result_handler()
def handle_result(args, answer, target_window_id, boss):
    if answer not in ('n', 'no'):
        boss.quit()
