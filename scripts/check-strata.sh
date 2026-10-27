#!/usr/bin/env bash
# Validate and install in a disposable app directory on a fresh macOS runner.
set -euo pipefail
cd "$(dirname "$0")/.."

tap="$(brew --repository)/Library/Taps/cristipufu/homebrew-tap"
mkdir -p "$(dirname "$tap")"
if [[ ! -e "$tap" ]]; then ln -s "$PWD" "$tap"; fi
if [[ "$(cd "$tap" && pwd -P)" != "$(pwd -P)" ]]; then
  echo "The installed tap must refer to this checkout." >&2
  exit 1
fi

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_AUTOREMOVE=1
export HOMEBREW_NO_ASK=1
if brew command trust >/dev/null 2>&1; then
  brew trust --cask cristipufu/tap/strata
fi
brew style --cask cristipufu/tap/strata
brew audit --cask --online cristipufu/tap/strata
brew install --cask --appdir "${RUNNER_TEMP:?}/strata-apps" cristipufu/tap/strata
strata --help
brew uninstall --cask cristipufu/tap/strata
