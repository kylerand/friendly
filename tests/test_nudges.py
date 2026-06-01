import unittest
import importlib.util
import sys
import types
from pathlib import Path


def _load_nudges_module():
    repo_module = types.ModuleType("app.db.repository")
    repo_module.Repository = type("Repository", (), {})
    deps_module = types.ModuleType("app.dependencies")
    deps_module.get_current_user_id = lambda: "user-1"
    deps_module.get_repository = lambda: repo_module.Repository()
    sys.modules["app.db.repository"] = repo_module
    sys.modules["app.dependencies"] = deps_module

    module_path = Path(__file__).resolve().parents[1] / "app" / "routers" / "nudges.py"
    spec = importlib.util.spec_from_file_location("nudges_under_test", module_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


nudges = _load_nudges_module()


class EffectiveNudgeTierTests(unittest.TestCase):
    def test_friend_drift_triggers_nudge_even_when_user_is_active(self):
        suggested = nudges.FriendSuggestion(
            friend_id="friend-1",
            friend_name="Alex",
            days_since_contact=15,
        )

        self.assertEqual(
            nudges._compute_effective_nudge_tier(
                days_since_activity=0,
                suggested_friend=suggested,
            ),
            "caring_concern",
        )

    def test_recent_friend_does_not_create_false_positive(self):
        suggested = nudges.FriendSuggestion(
            friend_id="friend-1",
            friend_name="Alex",
            days_since_contact=2,
        )

        self.assertIsNone(
            nudges._compute_effective_nudge_tier(
                days_since_activity=0,
                suggested_friend=suggested,
            )
        )

    def test_global_absence_still_triggers_when_no_friend_suggestion_exists(self):
        self.assertEqual(
            nudges._compute_effective_nudge_tier(
                days_since_activity=7,
                suggested_friend=None,
            ),
            "warm_invitation",
        )


if __name__ == "__main__":
    unittest.main()
