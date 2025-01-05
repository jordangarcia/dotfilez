dotfiles := env_var('HOME') + "/code/dotfilez"
config := env_var('HOME') + "/.config"

# Define lists as space-separated strings
dirs := "git karabiner nvim wezterm zsh"
files := "starship.toml"

default:
    @just --list


# Install from Brewfile
brew:
    brew bundle --file={{dotfiles}}/Brewfile


# Create all symlinks
link:
    mkdir -p {{config}}
    for dir in {{dirs}}; do ln -sfn {{dotfiles}}/$dir {{config}}/$dir; done
    for file in {{files}}; do ln -sf {{dotfiles}}/$file {{config}}/$file; done
    echo 'export ZDOTDIR="$HOME/.config/zsh"' > $HOME/.zshenv


# Remove all symlinks
clean:
    for dir in {{dirs}}; do rm -f {{config}}/$dir; done
    for file in {{files}}; do rm -f {{config}}/$file; done
