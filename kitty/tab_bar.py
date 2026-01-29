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
    # Tab title logic (matching wezterm):
    # 1. Explicit title (if set and not matching cwd)
    # 2. Last directory name from cwd
    # 3. Fallback to pane title
    title = tab.title
    cwd = getattr(tab, 'active_wd', '') or ''

    # Check if title was explicitly set (doesn't match cwd-derived name)
    cwd_dir = cwd.rstrip("/").rsplit("/", 1)[-1] if "/" in cwd else ""
    title_is_explicit = title and title != cwd_dir and "/" not in title and title not in ("~", "jordan", "zsh", "bash")

    if title_is_explicit:
        pass  # Use explicit title as-is
    elif cwd:
        # Extract last directory name from cwd
        title = cwd.rstrip("/").rsplit("/", 1)[-1] or "jordan"
    elif "/" in title:
        # Fallback: extract from title if it's a path
        title = title.rstrip("/").rsplit("/", 1)[-1]

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
