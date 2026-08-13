import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[2] / "scripts" / "classify_ci_paths.py"
SPEC = importlib.util.spec_from_file_location("classify_ci_paths", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ClassifyCiPathsTest(unittest.TestCase):
    def test_documentation_only_skips_application_ci(self):
        result = MODULE.classify(
            ["README.md", "docs/INSTALLATION.md", "docs_site/index.md"]
        )

        self.assertFalse(result["app_changed"])
        self.assertTrue(result["docs_site_changed"])

    def test_non_site_docs_do_not_deploy_pages(self):
        result = MODULE.classify(["USER_GUIDE.md", "docs/spec.md"])

        self.assertFalse(result["app_changed"])
        self.assertFalse(result["docs_site_changed"])

    def test_application_assets_and_workflows_force_full_ci(self):
        for path in [
            "lib/main.dart",
            "assets/branding/app_icon.png",
            "android/settings.gradle",
            ".github/workflows/ci.yml",
            "scripts/tool.py",
        ]:
            with self.subTest(path=path):
                self.assertTrue(MODULE.classify([path])["app_changed"])

    def test_empty_or_unknown_change_set_fails_safe(self):
        self.assertTrue(MODULE.classify([])["app_changed"])
        self.assertTrue(MODULE.classify(["unexpected.file"])["app_changed"])

    def test_workflow_routes_expensive_jobs_through_classifier(self):
        workflow = (Path(__file__).parents[2] / ".github/workflows/ci.yml").read_text()

        self.assertIn("name: Classify Changed Paths", workflow)
        self.assertEqual(
            workflow.count("if: needs.classify-changes.outputs.app_changed == 'true'"),
            3,
        )
        self.assertIn("needs.classify-changes.outputs.docs_site_changed", workflow)


if __name__ == "__main__":
    unittest.main()
