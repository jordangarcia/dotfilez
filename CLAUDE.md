# Neovim Upgrade Instructions

## Dual Configuration Setup

This repository maintains separate Neovim configurations to safely test version upgrades:

- `nvim` → `~/.config/nvim` → `~/code/dotfilez/nvim` (current/testing version)
- `nvim10` → `~/.config/nvim10` → `~/code/dotfilez/nvim10` (stable fallback)

## Creating a New Version Backup

When upgrading to a new Neovim version (e.g., 0.10 → 0.11):

1. **Copy current stable config to versioned backup:**
   ```bash
   cp -r ~/code/dotfilez/nvim ~/code/dotfilez/nvim10
   ```

2. **Create symlink for the backup config:**
   ```bash
   ln -s ~/code/dotfilez/nvim10 ~/.config/nvim10
   ```

3. **Add shell alias in `~/code/dotfilez/zsh/aliases.zsh`:**
   ```bash
   alias nvim10="NVIM_APPNAME=nvim10 /opt/homebrew/Cellar/neovim/0.10.3/bin/nvim"
   ```
   
   **Note:** The alias points to the specific 0.10.3 binary path to preserve this version even when upgrading the main neovim formula via Homebrew.

4. **Reload shell configuration:**
   ```bash
   source ~/.config/zsh/.zshrc
   ```

## Usage

- Use `nvim` for testing the new version with your main config
- Use `nvim10` to access the stable backup configuration
- Both configurations maintain separate plugin states and settings

## Testing Workflow

1. Test new features and plugins in main `nvim` config
2. If issues arise, use `nvim10` for stable editing
3. Once satisfied with upgrades, the backup can be removed or kept as reference

## Version Management

### Preserving Specific Versions
To maintain access to a specific Neovim version during upgrades:

1. **Before upgrading:** Note the current binary path from `brew info neovim`
2. **Update alias:** Point to the specific version path in your shell aliases
3. **Upgrade safely:** Run `brew upgrade neovim` knowing your stable version is preserved

### Upgrading Process
1. Use `nvim10` with the preserved 0.10.3 binary for stable work
2. Upgrade main neovim: `brew upgrade neovim` 
3. Test new version with your main `nvim` command and config
4. Update configurations as needed for the new version

## Neovim Binary Management

### Directory Structure
This setup uses `~/nvim/` to manage different Neovim versions:

```
~/nvim/
├── 0.10.3/          # Complete neovim 0.10.3 installation
│   ├── bin/nvim     # Binary
│   ├── lib/         # Libraries
│   └── share/       # Lua runtime files and documentation
└── bin/             # Symlinks directory (added to PATH)
    └── nvim-0.10.3 -> ~/nvim/0.10.3/bin/nvim
```

### Installing Version-Specific Binaries
When Homebrew removes old versions during upgrades:

1. **Download specific version from GitHub releases:**
   ```bash
   curl -LO https://github.com/neovim/neovim/releases/download/v0.10.3/nvim-macos-arm64.tar.gz
   tar -xzf nvim-macos-arm64.tar.gz
   ```

2. **Install to versioned directory:**
   ```bash
   mkdir -p ~/nvim/0.10.3
   cp -r nvim-macos-arm64/* ~/nvim/0.10.3/
   ```

3. **Create symlink in bin directory:**
   ```bash
   mkdir -p ~/nvim/bin
   ln -s ~/nvim/0.10.3/bin/nvim ~/nvim/bin/nvim-0.10.3
   ```

4. **Add to PATH in `~/code/dotfilez/zsh/path.zsh`:**
   ```bash
   export PATH="$PATH:$HOME/nvim/bin"
   ```

5. **Update alias to use binary name:**
   ```bash
   alias nvim10="NVIM_APPNAME=nvim10 nvim-0.10.3"
   ```

This approach preserves complete Neovim installations with all runtime files, avoiding missing module errors.

## Environment Variable

The `NVIM_APPNAME` environment variable directs Neovim to use configs from:
- Default: `~/.config/nvim/`
- Custom: `~/.config/$NVIM_APPNAME/`