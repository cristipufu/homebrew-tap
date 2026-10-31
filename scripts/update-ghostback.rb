# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "rubygems/version"
require "tempfile"

module GhostbackRelease
  module_function

  def version(release)
    raise "Expected a published stable release" if release["draft"] || release["prerelease"]

    match = /\Av(\d+\.\d+\.\d+)\z/.match(release.fetch("tag_name"))
    raise "Ghostback release tag must be vX.Y.Z" unless match

    match[1]
  end

  def source_url(version)
    raise "Invalid version" unless /\A\d+\.\d+\.\d+\z/.match?(version)

    "https://github.com/cristipufu/ghostback/archive/refs/tags/v#{version}.tar.gz"
  end

  def formula(version, checksum)
    raise "Invalid checksum" unless /\A[0-9a-f]{64}\z/.match?(checksum)

    <<~FORMULA
      class Ghostback < Formula
        desc "Recover coding-agent conversations in native Ghostty terminals"
        homepage "https://github.com/cristipufu/ghostback"
        url "#{source_url(version)}"
        sha256 "#{checksum}"
        license "MIT"

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
          assert_match version.to_s, shell_output("\#{bin}/ghostback --version")
          %w[
            ZDOTDIR XDG_CONFIG_HOME CODEX_HOME CLAUDE_CONFIG_DIR GROK_HOME
            PI_CODING_AGENT_DIR OPENCODE_CONFIG_DIR OPENCODE_TUI_CONFIG
          ].each { |key| ENV.delete(key) }
          system bin/"ghostback", "--state-dir", testpath/"state", "setup", "--dry-run", "--no-launch"
          refute_path_exists testpath/"state"
        end
      end
    FORMULA
  end

  def needs_update?(release_version, content)
    current = content[/archive\/refs\/tags\/v(\d+\.\d+\.\d+)\.tar\.gz/, 1]
    return true unless current
    raise "Refusing a Ghostback downgrade" if Gem::Version.new(release_version) < Gem::Version.new(current)

    current != release_version || !content.include?("  bottle do\n")
  end

  def command(*args)
    output, error, status = Open3.capture3(*args)
    raise "#{args.first} failed: #{error}" unless status.success?

    output
  end

  def update
    release = JSON.parse(command("gh", "api", "repos/cristipufu/ghostback/releases/latest"))
    selected = version(release)
    path = File.expand_path("../Formula/ghostback.rb", __dir__)
    content = File.exist?(path) ? File.read(path) : ""
    changed = needs_update?(selected, content)
    if changed
      Tempfile.create(["ghostback-source", ".tar.gz"]) do |source|
        command("curl", "--fail", "--location", "--retry", "2", "--max-time", "120", "--output", source.path, source_url(selected))
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, formula(selected, Digest::SHA256.file(source.path).hexdigest))
      end
    end
    if ENV["GITHUB_OUTPUT"]
      File.open(ENV.fetch("GITHUB_OUTPUT"), "a") { |out| out.puts("changed=#{changed}\nversion=#{selected}") }
    end
    puts "Ghostback #{selected}: #{changed ? 'bottle build needed' : 'up to date'}"
  end
end

if $PROGRAM_NAME == __FILE__
  require "fileutils"
  begin
    GhostbackRelease.update
  rescue StandardError => e
    warn "Ghostback update failed: #{e.message}"
    exit 1
  end
end
