import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BuildConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads((ROOT / "config" / "build-config.json").read_text(encoding="utf-8"))

    def test_required_configuration(self):
        self.assertEqual(self.config["schemaVersion"], 1)
        self.assertEqual(self.config["project"]["name"], "Install-Wulf")
        self.assertEqual(self.config["project"]["installerFileName"], "Winamp_InstallWulf-fixed.exe")
        self.assertEqual(self.config["installerVersion"]["fileVersion"], "1.33.7.0")
        self.assertEqual(self.config["installerVersion"]["displayVersion"], "1,33,7a")

    def test_source_identity_matches_repository(self):
        source = self.config["source"]
        source_path = ROOT / source["path"]
        self.assertTrue(source_path.is_file())
        self.assertEqual(source_path.stat().st_size, source["sizeBytes"])
        self.assertRegex(source["gitBlobSha1"], r"^[0-9a-f]{40}$")
        self.assertRegex(source.get("expectedSha256", ""), r"^[0-9a-f]{64}$")

    def test_toolchain_hashes_are_pinned(self):
        for tool_name in ("nsis", "sevenZip"):
            tool = self.config["toolchain"][tool_name]
            self.assertRegex(tool["sha256"], r"^[0-9A-Fa-f]{64}$")
            self.assertRegex(tool["version"], r"^\d+\.\d+(?:\.\d+)?$")
            self.assertTrue(tool["url"].startswith("https://"))

    def test_required_payload_files(self):
        self.assertIn("winamp.exe", self.config["payload"]["requiredFiles"])

    def test_workflow_is_pinned_and_staged(self):
        workflow = (ROOT / ".github" / "workflows" / "build-installer.yml").read_text(encoding="utf-8")
        self.assertIn("runs-on: [self-hosted, windows, x64, winamp-build]", workflow)
        self.assertNotIn("runs-on: windows-2025", workflow)
        self.assertNotIn("pull_request:", workflow)
        self.assertIn("actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683", workflow)
        self.assertIn("actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02", workflow)
        for stage in (
            "Source validation",
            "Toolchain setup",
            "Payload extraction",
            "Payload validation",
            "Installer build",
            "Installer validation",
            "SHA-256",
            "Artifact upload",
        ):
            self.assertIn(stage, workflow)

    def test_release_promotion_uses_linux_self_hosted_runner(self):
        workflow = (ROOT / ".github" / "workflows" / "release-promotion.yml").read_text(encoding="utf-8")
        self.assertIn("runs-on: [self-hosted, linux, x64, legion]", workflow)
        self.assertNotRegex(workflow, r"runs-on:\s+(?:ubuntu|windows|macos)-")
        self.assertIn("config.source.expectedSha256", workflow)
        self.assertIn("conclusion", workflow)
        self.assertIn("sha256sum -c SHA256SUMS.txt", workflow)

    def test_documentation_does_not_claim_a_license_file_exists(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("The repository currently has **no `LICENSE` file**.", readme)
        self.assertFalse((ROOT / "LICENSE").exists())


if __name__ == "__main__":
    unittest.main()
