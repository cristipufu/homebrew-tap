class Ghostback < Formula
  desc "Recover coding-agent conversations in native Ghostty terminals"
  homepage "https://github.com/cristipufu/ghostback"
  url "https://github.com/cristipufu/ghostback/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "142baa908b5d69869b9110a6725d3b70153ffc770b4dd72df2dae56e6d1d013e"
  license "MIT"

  bottle do
    root_url "https://github.com/cristipufu/homebrew-tap/releases/download/ghostback-v0.2.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "091e1bb4d97d593178266c8523bd33dcb192ab97c0606b25c2824d48f235d7c6"
  end

  depends_on "rust" => :build
  depends_on :macos

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args
    system "cargo", "run", "--offline", "--locked", "--example", "notices", "--", "THIRD_PARTY_NOTICES.txt"
    pkgshare.install "LICENSE", "THIRD_PARTY_NOTICES.txt"
    doc.install "README.md", "CONTRIBUTING.md", "docs"
  end

  def caveats
    <<~EOS
      Enable recovery for your account:
        ghostback setup --dry-run
        ghostback setup

      Open a new Ghostty tab and allow Automation access when prompted.
      Inspect capture with: ghostback status

      After upgrading, rerun ghostback setup and restart Pi/OpenCode.

      Before removing Ghostback, remove its account integration:
        ghostback uninstall
        brew uninstall ghostback

      Saved conversation state is retained.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ghostback --version")
    %w[
      ZDOTDIR XDG_CONFIG_HOME CODEX_HOME CLAUDE_CONFIG_DIR GROK_HOME
      PI_CODING_AGENT_DIR OPENCODE_CONFIG_DIR OPENCODE_TUI_CONFIG
    ].each { |key| ENV.delete(key) }
    system bin/"ghostback", "--state-dir", testpath/"state", "setup", "--dry-run", "--no-launch"
    refute_path_exists testpath/"state"
  end
end
