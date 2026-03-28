"""Powerline-style kitty tab bar — Kanagawa palette"""
# pyright: reportMissingImports=false,reportGeneralTypeIssues=false,reportAttributeAccessIssue=false,reportCallIssue=false

import datetime
import os

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb

# Kanagawa palette
BG              = 0x1F1F28
FG              = 0xDDD8BB
ACTIVE          = 0xE6C384
ACTIVE_FG       = 0x1F1F28
INACTIVE_TAB_BG = 0x2A2A37
MUTED           = 0x727169
PURPLE          = 0x957FB8

PL      = "\ue0b0"
PL_THIN = "\ue0b1"

REFRESH_TIME = 1


def _pl(screen, prev_bg, next_bg):
    screen.cursor.fg = as_rgb(prev_bg)
    screen.cursor.bg = as_rgb(next_bg)
    screen.draw(PL)


def _draw_session_indicator(draw_data: DrawData, screen: Screen, tab: TabBarData) -> int:
    session_name = tab.session_name
    if not session_name:
        return 0
    cell = f" {session_name} "
    screen.cursor.fg = as_rgb(ACTIVE_FG)
    screen.cursor.bg = as_rgb(PURPLE)
    screen.cursor.bold = True
    screen.draw(cell)
    screen.cursor.bold = False
    _pl(screen, PURPLE, INACTIVE_TAB_BG)
    return len(cell) + 1


def _tab_title(tab: TabBarData) -> tuple[str, str]:
    """Return (prefix, name). prefix includes trailing /."""
    boss = get_boss()
    if boss:
        t = boss.tab_for_id(tab.tab_id)
        if t and t.name:
            return "", t.name
        if t:
            cwd = t.get_cwd_of_active_window()
            if cwd:
                name = os.path.basename(cwd)
                parent = os.path.basename(os.path.dirname(cwd))
                if name in ("~", "jordan", ""):
                    return "", "jordan"
                if parent and name:
                    return f"{parent}/", name
                return "", name or cwd
    return "", tab.title


def _draw_right_status(draw_data: DrawData, screen: Screen, is_last: bool) -> int:
    if not is_last:
        return screen.cursor.x

    cell = datetime.datetime.now().strftime("\ue0b3 %a %b %-d %H:%M ")
    draw_spaces = screen.columns - screen.cursor.x - len(cell)
    if draw_spaces > 0:
        screen.cursor.bg = as_rgb(BG)
        screen.draw(" " * draw_spaces)

    screen.cursor.fg = as_rgb(MUTED)
    screen.cursor.bg = as_rgb(BG)
    screen.draw(cell)

    screen.cursor.x = max(screen.cursor.x, screen.columns - len(cell))
    return screen.cursor.x


def _redraw_tab_bar(_):
    tm = get_boss().active_tab_manager
    if tm is not None:
        tm.mark_tab_bar_dirty()


timer_id = None
prev_tab_was_active = False


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global timer_id, prev_tab_was_active
    if timer_id is None:
        timer_id = add_timer(_redraw_tab_bar, REFRESH_TIME, True)

    if index == 1:
        prev_tab_was_active = False
        has_session = bool(tab.session_name)
        before += _draw_session_indicator(draw_data, screen, tab)
        if not has_session:
            screen.cursor.bg = as_rgb(INACTIVE_TAB_BG)
            screen.draw(" ")
            before += 1

    prefix, name = _tab_title(tab)
    idx = f" {index} "
    after_bg = BG if is_last else INACTIVE_TAB_BG

    if tab.is_active:
        _pl(screen, INACTIVE_TAB_BG, ACTIVE)
        screen.cursor.bg = as_rgb(ACTIVE)
        screen.cursor.fg = as_rgb(ACTIVE_FG)
        screen.cursor.bold = True
        screen.draw(idx)
        screen.cursor.bold = False
        screen.cursor.fg = as_rgb(0x504A3A)
        screen.draw(prefix)
        screen.cursor.fg = as_rgb(ACTIVE_FG)
        screen.cursor.bold = True
        screen.draw(f"{name} ")
        screen.cursor.bold = False
        _pl(screen, ACTIVE, after_bg)
        end = screen.cursor.x
    else:
        screen.cursor.bg = as_rgb(INACTIVE_TAB_BG)
        if not prev_tab_was_active:
            screen.cursor.fg = as_rgb(0x3C3C51)
            screen.draw(PL_THIN)
        screen.cursor.fg = as_rgb(FG)
        screen.draw(idx)
        screen.cursor.fg = as_rgb(MUTED)
        screen.draw(prefix)
        screen.cursor.fg = as_rgb(0xA8A48D)
        screen.draw(f"{name} ")
        if is_last:
            _pl(screen, INACTIVE_TAB_BG, BG)
        end = screen.cursor.x

    prev_tab_was_active = tab.is_active
    _draw_right_status(draw_data, screen, is_last)
    return end
