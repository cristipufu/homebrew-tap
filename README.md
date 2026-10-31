# Cristi Pufu's Homebrew tap

A shared Homebrew tap for software maintained by [cristipufu](https://github.com/cristipufu).
Each package points to the releases in its own upstream repository.

| Package | Description | Upstream |
| --- | --- | --- |
| `strata` | Native macOS file manager | [cristipufu/strata-files](https://github.com/cristipufu/strata-files) |
| `ghostback` | Automatic coding-agent session recovery for Ghostty | [cristipufu/ghostback](https://github.com/cristipufu/ghostback) |

## Install Strata

Install [Strata Files](https://stratafiles.app/) using Homebrew:

```sh
brew install --cask cristipufu/tap/strata
```

Requires an Apple silicon Mac running macOS 26 (Tahoe) or later. Homebrew installs `Strata.app` in Applications and
links the bundled `strata` command into its executable directory. Use `strata --help` to see its options.

You can also add the tap before installing:

```sh
brew tap cristipufu/tap
brew install --cask strata
```

If you already installed Strata manually, Homebrew refuses to overwrite it. An identical copy of the same release
can be adopted with `brew install --cask --adopt cristipufu/tap/strata`.

## Install Ghostback

```sh
brew install cristipufu/tap/ghostback
ghostback setup --dry-run
ghostback setup
```

Requires macOS, Ghostty 1.4+, and zsh or bash. The current prebuilt bottle targets
Apple Silicon on macOS 26 (Tahoe); other configurations build from source with
Homebrew's build dependencies. The bottle needs no Rust runtime or compiler.

Setup is an explicit account-level step: it installs shell/agent hooks and the
login helper. Open a new Ghostty tab afterward and allow Automation access if
prompted. Check capture with `ghostback status`.

Ghostback uses Homebrew's stable executable path and picks up upgrades:

```sh
brew update
brew upgrade ghostback
```

Remove account integration before uninstalling the formula:

```sh
ghostback uninstall
brew uninstall ghostback
```

Saved sessions are retained. The **Update Ghostback** workflow checks upstream
stable releases hourly and can be run manually. It builds from checksummed source,
tests setup/uninstall with a disposable HOME, builds and tests a Homebrew bottle,
and publishes the bottle and formula update. It uses this tap's `GITHUB_TOKEN`;
no Apple signing credentials or cross-repository token are needed.

## Updates

Strata includes its own updater. To update explicitly through Homebrew, including apps with an in-app updater:

```sh
brew update
brew upgrade --cask --greedy strata
```

The **Update Strata** workflow checks the latest stable [GitHub release](https://github.com/cristipufu/strata-files/releases/latest)
hourly and can also be run manually from Actions. GitHub may delay scheduled runs; the tap updates after a successful run.
It verifies the downloaded DMG against the release's `SHA256SUMS.txt`, checks the cask and tests installation before
committing the new version. It uses this repository's `GITHUB_TOKEN`; no additional secrets are required.

Only stable `vX.Y.Z` releases are accepted. Older versions and prereleases cannot replace the current cask. The cask
uses a versioned download URL and checksum. Release downloads remain hosted in the Strata application repository.

## Uninstall

```sh
brew uninstall --cask strata
```

This removes the app and Homebrew's CLI link. Application preferences, saved state and credentials are retained.

## Development

Add macOS application definitions under `Casks/` and source-built command-line packages under `Formula/`.
Document each new package in the table above. Keep release URLs, checksums, platform requirements and update
workflows specific to each package's upstream repository. Strata's scripts and workflows provide its own checks
and release updater; future packages can have independent workflows.

```sh
python3 -m unittest discover -s tests
python3 scripts/update-strata.py
brew style --cask cristipufu/tap/strata
brew audit --cask --online cristipufu/tap/strata
brew livecheck --cask cristipufu/tap/strata
```
