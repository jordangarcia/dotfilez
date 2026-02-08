"""
Absolute resize kitten for kitty.
Moves the border in the direction pressed, regardless of which pane you're in.
Like wezterm's AdjustPaneSize behavior.

Usage in kitty.conf:
    map kitty_mod+left kitten resize_pane.py left 12
    map kitty_mod+right kitten resize_pane.py right 12
    map kitty_mod+up kitten resize_pane.py up 5
    map kitty_mod+down kitten resize_pane.py down 5
"""

from kittens.tui.handler import result_handler


def get_neighbors(tab):
    """Get all neighbors for the active window."""
    return tab.current_layout.neighbors_for_window(
        tab.active_window, tab.windows
    )


def has_neighbor(tab, direction):
    """Check if there's a neighboring window in the given direction."""
    return len(get_neighbors(tab).get(direction, [])) > 0


def main():
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    direction = args[1]  # left, right, up, down
    amount = int(args[2]) if len(args) > 2 else 5

    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    tab = boss.active_tab
    if tab is None:
        return

    # Map direction names to kitty's neighbor directions
    dir_map = {'left': 'left', 'right': 'right', 'up': 'top', 'down': 'bottom'}
    neighbor_dir = dir_map.get(direction)
    opposite_map = {'left': 'right', 'right': 'left', 'top': 'bottom', 'bottom': 'top'}
    opposite_dir = opposite_map.get(neighbor_dir)

    # Determine resize action based on direction and neighbors
    # Goal: always move the border in the pressed direction
    if direction in ('left', 'right'):
        # Horizontal resize
        if has_neighbor(tab, neighbor_dir):
            # Neighbor in pressed direction: push into them
            tab.resize_window('wider', amount)
        elif has_neighbor(tab, opposite_dir):
            # Neighbor on opposite side: shrink away from them (border moves in pressed direction)
            tab.resize_window('narrower', amount)
    else:
        # Vertical resize (up/down)
        if has_neighbor(tab, neighbor_dir):
            # Neighbor in pressed direction: push into them
            tab.resize_window('taller', amount)
        elif has_neighbor(tab, opposite_dir):
            # Neighbor on opposite side: shrink away from them
            tab.resize_window('shorter', amount)
