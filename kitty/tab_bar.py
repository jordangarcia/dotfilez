from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    # Tab title logic: always show cwd, unless explicitly renamed
    cwd = getattr(tab, 'active_wd', '') or ''
    cwd_dir = cwd.rstrip("/").rsplit("/", 1)[-1] if cwd else ""

    # Check if user explicitly renamed the tab (title doesn't match cwd or common process names)
    user_title = tab.title
    is_explicit = user_title and user_title != cwd_dir and "/" not in user_title and user_title not in ("~", "zsh", "bash", "nvim", "vim", "vi", "python", "node", "fg")

    if is_explicit:
        title = user_title
    elif cwd_dir:
        title = cwd_dir
    else:
        title = "jordan"

    # Show "jordan" for home directory
    if title in ("~", "jordan", ""):
        title = "jordan"

    # Truncate long titles
    if len(title) > 12:
        title = title[:11] + "…"

    # Format like wezterm: "index title" center-padded to fixed width
    content = f"{index} {title}"
    width = 16

    # Center the content in the width
    padding = width - len(content)
    left_pad = padding // 2
    right_pad = padding - left_pad
    tab_text = " " * max(left_pad, 1) + content + " " * max(right_pad, 1)

    if tab.is_active:
        # Active: yellow bg, dark text
        screen.cursor.bg = as_rgb(0xe6c384)
        screen.cursor.fg = as_rgb(0x1f1f28)
    else:
        # Inactive: dark bg, gray text
        screen.cursor.bg = as_rgb(0x1f1f28)
        screen.cursor.fg = as_rgb(0x727169)

    screen.draw(tab_text)

    # Separator between tabs
    screen.cursor.bg = as_rgb(0x1f1f28)
    screen.draw(" ")

    return screen.cursor.x
