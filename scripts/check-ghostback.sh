#!/usr/bin/env bash
# Source-build and test only on disposable CI runners. Account setup uses a temp HOME.
set -euo pipefail
cd "$(dirname "$0")/.."

tap="$(brew --repository)/Library/Taps/cristipufu/homebrew-tap"
mkdir -p "$(dirname "$tap")"
if [[ ! -e "$tap" ]]; then ln -s "$PWD" "$tap"; fi
if [[ "$(cd "$tap" && pwd -P)" != "$(pwd -P)" ]]; then
  echo "The installed tap must refer to this checkout." >&2
  exit 1
fi
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_AUTOREMOVE=1 HOMEBREW_NO_ASK=1
formula=cristipufu/tap/ghostback
if brew command trust >/dev/null 2>&1; then brew trust --formula "$formula"; fi
brew style --formula "$formula"
brew audit --formula --online "$formula"
brew install --build-bottle "$formula"
trap 'brew uninstall "$formula" >/dev/null 2>&1 || true' EXIT
brew test "$formula"

binary="$(brew --prefix ghostback)/bin/ghostback"
if [[ $(wc -c < "$binary" | tr -d ' ') -gt 10485760 ]]; then
  echo "Ghostback exceeds the 10 MiB executable budget." >&2
  exit 1
fi
fixture=$(mktemp -d "${RUNNER_TEMP:?}/ghostback-account.XXXXXX")
run_fixture() {
  env HOME="$fixture" ZDOTDIR="" XDG_CONFIG_HOME="" CODEX_HOME="" CLAUDE_CONFIG_DIR="" GROK_HOME="" \
    PI_CODING_AGENT_DIR="" OPENCODE_CONFIG_DIR="" OPENCODE_TUI_CONFIG="" \
    "$binary" --state-dir "$fixture/state" "$@"
}
run_fixture setup --no-launch
ruby -rjson -e 'm=JSON.parse(File.read(ARGV[0])); abort "not Homebrew managed" unless m.fetch("distribution")=="homebrew"; abort "versioned executable path" unless m.fetch("binary").include?("/opt/ghostback/bin/ghostback")' "$fixture/state/install.json"
test ! -e "$fixture/.local/bin/ghostback"
touch "$fixture/state/retained-session-state"
run_fixture uninstall --no-launch
test -f "$binary"
test -f "$fixture/state/retained-session-state"

if [[ ${1:-} == --bottle ]]; then
  version=$("$binary" --version | sed -n 's/^ghostback //p')
  mkdir -p bottles
  (
    cd bottles
    brew bottle --json --root-url "https://github.com/cristipufu/homebrew-tap/releases/download/ghostback-v$version" "$formula"
    brew bottle --merge --write --no-commit ./*.bottle.json
    brew style --fix --formula "$formula"
    brew uninstall "$formula"
    cache=$(brew --cache --force-bottle "$formula")
    mkdir -p "$(dirname "$cache")"
    cp ./*.bottle.tar.gz "$cache"
    brew install --force-bottle "$formula"
    brew test "$formula"
    brew info --json=v2 "$formula" | ruby -rjson -e 'abort "not installed from bottle" unless JSON.parse(STDIN.read).fetch("formulae").first.fetch("installed").first.fetch("poured_from_bottle")'
    ruby -rjson -rfileutils -e 'Dir["*.bottle.json"].each { |f| JSON.parse(File.read(f)).each_value { |v| v.fetch("bottle").fetch("tags").each_value { |t| FileUtils.cp(t.fetch("local_filename"), t.fetch("filename")) unless t.fetch("local_filename")==t.fetch("filename") } } }'
  )
fi
