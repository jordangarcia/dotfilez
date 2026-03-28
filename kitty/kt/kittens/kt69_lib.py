"""Shared utilities for kt kittens — all state from kitty user vars."""


def get_session_from_window(window):
    """Get session data from a kitty window's user vars."""
    branch = window.user_vars.get('kt69_branch')
    if not branch:
        return None, None
    worktree = window.user_vars.get('kt69_worktree')
    offset = window.user_vars.get('kt69_offset')
    session = {
        'branch': branch,
        'worktree_path': worktree,
        'port_offset': int(offset) if offset else None,
    }
    return branch, session


def get_offset_from_window(window):
    """Get port offset from window user vars."""
    offset = window.user_vars.get('kt69_offset')
    if offset:
        return int(offset)
    return None
