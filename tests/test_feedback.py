import unittest
import importlib.util
import sys
import types
from pathlib import Path

from app.schemas.models import FeedbackCreate


def _load_feedback_module():
    module_names = ["app.db.repository", "app.dependencies"]
    originals = {name: sys.modules.get(name) for name in module_names}

    repo_module = types.ModuleType("app.db.repository")
    repo_module.Repository = type("Repository", (), {})
    deps_module = types.ModuleType("app.dependencies")
    deps_module.get_current_user_id = lambda: "user-1"
    deps_module.get_repository = lambda: repo_module.Repository()

    sys.modules["app.db.repository"] = repo_module
    sys.modules["app.dependencies"] = deps_module

    module_path = Path(__file__).resolve().parents[1] / "app" / "routers" / "feedback.py"
    spec = importlib.util.spec_from_file_location("feedback_under_test", module_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    try:
        spec.loader.exec_module(module)
    finally:
        for name, original in originals.items():
            if original is None:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = original
    return module


feedback = _load_feedback_module()


class FakeFeedbackRepo:
    def __init__(self):
        self.payloads = []

    def create_tester_report(self, payload):
        self.payloads.append(payload)
        return {
            "id": "00000000-0000-0000-0000-000000000001",
            "status": "new",
            "created_at": "2026-06-02T12:00:00+00:00",
            "updated_at": "2026-06-02T12:00:00+00:00",
            **payload,
        }


class FeedbackRouteTests(unittest.TestCase):
    def test_create_feedback_maps_app_error_to_tester_report(self):
        repo = FakeFeedbackRepo()

        result = feedback.create_feedback(
            body=FeedbackCreate(
                type="error",
                source="AppState.refresh",
                message="ApiException(500): Internal Server Error",
                stack_trace="trace line",
            ),
            user_id="00000000-0000-0000-0000-000000000002",
            repo=repo,
        )

        self.assertEqual(result["type"], "error")
        self.assertEqual(result["title"], "AppState.refresh")
        self.assertIn("ApiException(500)", result["description"])
        self.assertIn("Stack trace:", result["description"])
        self.assertEqual(
            repo.payloads[0]["user_id"],
            "00000000-0000-0000-0000-000000000002",
        )


if __name__ == "__main__":
    unittest.main()
