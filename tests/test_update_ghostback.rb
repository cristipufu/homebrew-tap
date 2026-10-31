# frozen_string_literal: true

require "minitest/autorun"
require_relative "../scripts/update-ghostback"

class TestGhostbackRelease < Minitest::Test
  def test_accepts_stable_release
    assert_equal "0.1.0", GhostbackRelease.version({ "tag_name" => "v0.1.0", "draft" => false, "prerelease" => false })
  end

  def test_rejects_unpublished_and_non_stable_releases
    [
      { "tag_name" => "v0.1.0", "draft" => true },
      { "tag_name" => "v0.1.0", "prerelease" => true },
      { "tag_name" => "v0.1.0-alpha.1" },
      { "tag_name" => "main" },
      { "tag_name" => "v1.2.3;touch /tmp/unwanted" },
    ].each { |release| assert_raises(RuntimeError) { GhostbackRelease.version(release) } }
  end

  def test_refuses_downgrade
    content = GhostbackRelease.formula("0.2.0", "a" * 64)
    assert_raises(RuntimeError) { GhostbackRelease.needs_update?("0.1.0", content) }
  end

  def test_builds_missing_bottle_without_overwriting_existing_bottle
    content = GhostbackRelease.formula("0.1.0", "a" * 64)
    assert GhostbackRelease.needs_update?("0.1.0", content)
    refute GhostbackRelease.needs_update?("0.1.0", content + "  bottle do\n")
    assert GhostbackRelease.needs_update?("0.2.0", content + "  bottle do\n")
  end

  def test_uses_fixed_upstream_and_validated_checksum
    content = GhostbackRelease.formula("0.1.0", "a" * 64)
    assert_includes content, GhostbackRelease.source_url("0.1.0")
    assert_includes content, 'depends_on "rust" => :build'
    assert_includes content, 'license "MIT"'
    assert_raises(RuntimeError) { GhostbackRelease.formula("0.1.0", "invalid") }
    assert_raises(RuntimeError) { GhostbackRelease.source_url("../../other") }
  end
end
