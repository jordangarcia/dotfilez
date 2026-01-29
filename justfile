dotfiles := env_var('HOME') + "/code/dotfilez"
config := env_var('HOME') + "/.config"

# Define lists as space-separated strings
dirs := "git karabiner kitty nvim wezterm zsh raycast-scripts"
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


# Configure macOS defaults
macos:
    # Keyboard settings
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

    # UI Preferences
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Mouse/Trackpad
    defaults write NSGlobalDomain com.apple.mouse.linear -bool true
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

    # Sound
    defaults write NSGlobalDomain com.apple.sound.beep.feedback -bool false
    defaults write NSGlobalDomain com.apple.sound.beep.flash -bool false
    defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool false

    # Typing
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Trackpad settings
    # Enable tap to click
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    # Enable right click
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
    # Enable gestures
    defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
    # Three finger gestures
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 1
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 1
    # Four & Five finger gestures
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int 2
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int 2
    # Scrolling settings
    defaults write com.apple.AppleMultitouchTrackpad TrackpadScroll -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadHorizScroll -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadMomentumScroll -bool true
    # Other settings
    defaults write com.apple.AppleMultitouchTrackpad HIDScrollZoomModifierMask -int 262144
    defaults write com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad -bool false
    
    # Dock settings
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock "expose-group-apps" -bool true
    defaults write com.apple.dock mineffect -string "scale"
    defaults write com.apple.dock "minimize-to-application" -bool false
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock show-process-indicators -bool true
    defaults write com.apple.dock tilesize -int 51
    defaults write com.apple.dock showAppExposeGestureEnabled -bool true
    defaults write com.apple.dock showMissionControlGestureEnabled -bool true
    # Set bottom right corner to start screen saver
    defaults write com.apple.dock wvous-br-corner -int 1
    defaults write com.apple.dock wvous-br-modifier -int 0

    # Kill Dock to apply changes
    killall Dock




# Remove all symlinks
clean:
    for dir in {{dirs}}; do rm -f {{config}}/$dir; done
    for file in {{files}}; do rm -f {{config}}/$file; done
