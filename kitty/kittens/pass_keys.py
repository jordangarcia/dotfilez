import re

from kittens.tui.handler import result_handler
from kitty.key_encoding import KeyEvent, parse_shortcut


def is_window_vim(window, vim_id):
    fp = window.child.foreground_processes
    return any(re.search(vim_id, p['cmdline'][0] if len(p['cmdline']) else '', re.I) for p in fp)


def encode_key_mapping(window, key_mapping):
    mods, key = parse_shortcut(key_mapping)
    event = KeyEvent(
        mods=mods,
        key=key,
        shift=bool(mods & 1),
        alt=bool(mods & 2),
        ctrl=bool(mods & 4),
        super=bool(mods & 8),
        hyper=bool(mods & 16),
        meta=bool(mods & 32),
    ).as_window_system_event()

    return window.encoded_key(event)


def get_neighbors(tab):
    """Get all neighbors for the active window."""
    return tab.current_layout.neighbors_for_window(
        tab.active_window, tab.windows
    )


def has_vertical_split(tab):
    """Check if there's any pane above or below."""
    neighbors = get_neighbors(tab)
    return bool(neighbors.get('top')) or bool(neighbors.get('bottom'))


def has_neighbor(tab, direction):
    """Check if there's a neighboring window in the given direction."""
    return len(get_neighbors(tab).get(direction, [])) > 0


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    direction = args[1]
    key_mapping = args[2]
    vim_id = args[3] if len(args) > 3 else "n?vim"
    fallback_key = args[4] if len(args) > 4 else None

    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    tab = boss.active_tab
    is_vertical = direction in ('top', 'bottom')

    if is_vertical:
        # j/k: kitty panes take priority, otherwise always send arrow
        if has_vertical_split(tab):
            tab.neighboring_window(direction)
        elif fallback_key:
            encoded = encode_key_mapping(window, fallback_key)
            window.write_to_child(encoded)
    else:
        # h/l: normal vim-kitty-navigator logic
        if is_window_vim(window, vim_id):
            for keymap in key_mapping.split(">"):
                encoded = encode_key_mapping(window, keymap)
                window.write_to_child(encoded)
        else:
            tab.neighboring_window(direction)
