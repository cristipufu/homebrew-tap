import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("update_strata", Path(__file__).resolve().parents[1] / "scripts/update-strata.py")
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.path = Path(self.temporary.name) / "strata.rb"
        self.original = 'cask "strata" do\n  version "0.7.4"\n  sha256 "' + "a" * 64 + '"\n  app "Strata.app"\nend\n'
        self.path.write_text(self.original)
        self.release = {
            "tag_name": "v0.7.5", "draft": False, "prerelease": False,
            "assets": [{"name": name, "browser_download_url": f"{updater.DOWNLOADS}/v0.7.5/{name}"}
                       for name in ["Strata.dmg", "SHA256SUMS.txt"]],
        }
        self.sums = ("b" * 64 + "  Strata.dmg\n" + "c" * 64 + "  Strata.zip\n").encode()

    def run_update(self):
        with patch.object(updater, "read", side_effect=[json.dumps(self.release).encode(), self.sums]), \
             patch.object(updater, "download_sha256", return_value="b" * 64):
            return updater.update(self.path)

    def test_verified_release_changes_only_version_and_checksum(self):
        self.assertTrue(self.run_update())
        self.assertEqual(self.path.read_text(), self.original.replace('"0.7.4"', '"0.7.5"').replace("a" * 64, "b" * 64))

    def test_same_or_older_version_does_not_download_or_change_cask(self):
        for tag in ["v0.7.4", "v0.7.3", "v0.6.99"]:
            self.release["tag_name"] = tag
            with patch.object(updater, "read", return_value=json.dumps(self.release).encode()) as read, \
                 patch.object(updater, "download_sha256") as download:
                self.assertFalse(updater.update(self.path))
                self.assertEqual(read.call_count, 1)
                download.assert_not_called()
            self.assertEqual(self.path.read_text(), self.original)

    def test_prerelease_draft_and_invalid_tag_leave_cask_unchanged(self):
        for changes in [{"prerelease": True}, {"draft": True}, {"tag_name": "v0.7.5-beta.1"},
                        {"tag_name": 'v0.7.5";system("bad")'}, {"tag_name": "v00.7.5"}]:
            with self.subTest(changes=changes), patch.dict(self.release, changes):
                with self.assertRaises(ValueError):
                    self.run_update()
                self.assertEqual(self.path.read_text(), self.original)

    def test_missing_duplicate_and_foreign_assets_leave_cask_unchanged(self):
        original = self.release["assets"]
        for assets in [[], original + [original[0]],
                       [dict(asset, browser_download_url="https://example.com/file") for asset in original]]:
            self.release["assets"] = assets
            with self.assertRaises(ValueError):
                self.run_update()
            self.assertEqual(self.path.read_text(), self.original)

    def test_invalid_or_duplicate_checksum_leaves_cask_unchanged(self):
        for sums in [b"", b"wrong  Strata.dmg\n", b"a" * 64 + b"  Strata.zip\n", self.sums * 2]:
            self.sums = sums
            with self.assertRaises(ValueError):
                self.run_update()
            self.assertEqual(self.path.read_text(), self.original)

    def test_mismatched_download_and_failed_read_leave_cask_unchanged(self):
        with patch.object(updater, "read", side_effect=[json.dumps(self.release).encode(), self.sums]), \
             patch.object(updater, "download_sha256", return_value="d" * 64):
            with self.assertRaisesRegex(ValueError, "does not match"):
                updater.update(self.path)
        self.assertEqual(self.path.read_text(), self.original)
        with patch.object(updater, "read", side_effect=OSError("unavailable")):
            with self.assertRaises(OSError):
                updater.update(self.path)
        self.assertEqual(self.path.read_text(), self.original)


if __name__ == "__main__":
    unittest.main()
