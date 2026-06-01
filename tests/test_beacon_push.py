import importlib.util
import sys
import types
import unittest
from datetime import datetime, timezone
from pathlib import Path


def _load_signals_module(dispatch_fn):
    module_names = [
        "app.db.repository",
        "app.dependencies",
        "app.services.push_dispatcher",
    ]
    originals = {name: sys.modules.get(name) for name in module_names}

    repo_module = types.ModuleType("app.db.repository")
    repo_module.Repository = type("Repository", (), {})
    deps_module = types.ModuleType("app.dependencies")
    deps_module.get_current_user_id = lambda: "user-1"
    deps_module.get_repository = lambda: repo_module.Repository()
    push_module = types.ModuleType("app.services.push_dispatcher")
    push_module.dispatch_beacon_alert = dispatch_fn

    sys.modules["app.db.repository"] = repo_module
    sys.modules["app.dependencies"] = deps_module
    sys.modules["app.services.push_dispatcher"] = push_module

    module_path = Path(__file__).resolve().parents[1] / "app" / "routers" / "signals.py"
    spec = importlib.util.spec_from_file_location("signals_under_test", module_path)
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


class FakeBeaconRepo:
    def __init__(self, *, signals=None):
        self.signals = signals or {}
        self.created_signals = []
        self.friendships = [
            {"user_id": "user-1", "friend_id": "friend-1", "status": "confirmed"},
            {"user_id": "user-1", "friend_id": "friend-2", "status": "pending"},
            {"user_id": "friend-3", "friend_id": "user-1", "status": "confirmed"},
        ]
        self.profiles = {
            "user-1": {"id": "user-1", "display_name": "Kyle"},
            "friend-1": {"id": "friend-1", "display_name": "Liz"},
            "friend-3": {"id": "friend-3", "display_name": "Sam"},
        }

    def list_ambient_signals(self, user_id, limit=50):
        return self.signals.get(user_id, [])

    def create_ambient_signal(self, user_id, signal_type, value, tags=None):
        row = {
            "id": "signal-1",
            "user_id": user_id,
            "signal_type": signal_type,
            "value": value,
            "tags": tags or [],
            "created_at": "2026-06-01T22:54:32+00:00",
        }
        self.created_signals.append(row)
        return row

    def list_friendships(self, user_id):
        return self.friendships

    def get_profile(self, user_id):
        return self.profiles.get(user_id)


class BeaconRouteTests(unittest.TestCase):
    def test_new_beacon_notifies_confirmed_friends_only(self):
        calls = []

        def fake_dispatch(repo, recipient_id, sender_id, sender_name):
            calls.append((recipient_id, sender_id, sender_name))
            return {"sent": True, "reachable": True, "reason": "sent"}

        signals = _load_signals_module(fake_dispatch)
        repo = FakeBeaconRepo()

        response = signals.activate_beacon(user_id="user-1", repo=repo)

        self.assertTrue(response.active)
        self.assertEqual(response.notified_count, 2)
        self.assertEqual(response.reachable_friends, 2)
        self.assertEqual(
            calls,
            [
                ("friend-1", "user-1", "Kyle"),
                ("friend-3", "user-1", "Kyle"),
            ],
        )
        self.assertEqual(len(repo.created_signals), 1)

    def test_existing_active_beacon_does_not_resend_pushes(self):
        calls = []
        active_signal = {
            "id": "signal-active",
            "user_id": "user-1",
            "signal_type": "support_beacon",
            "value": 1.0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        def fake_dispatch(repo, recipient_id, sender_id, sender_name):
            calls.append((recipient_id, sender_id, sender_name))
            return {"sent": True, "reachable": True, "reason": "sent"}

        signals = _load_signals_module(fake_dispatch)
        repo = FakeBeaconRepo(signals={"user-1": [active_signal]})

        response = signals.activate_beacon(user_id="user-1", repo=repo)

        self.assertTrue(response.active)
        self.assertEqual(response.activated_at, active_signal["created_at"])
        self.assertEqual(response.notified_count, 0)
        self.assertEqual(calls, [])
        self.assertEqual(repo.created_signals, [])


class FakePushRepo:
    def __init__(self, profile):
        self.profile = profile
        self.logs = []

    def get_profile(self, user_id):
        return self.profile

    def create_nudge_log(self, user_id, nudge_tier, copy_text, friend_id=None):
        self.logs.append((user_id, nudge_tier, copy_text, friend_id))
        return {}


class BeaconDispatcherTests(unittest.TestCase):
    def test_beacon_alert_respects_recipient_preference(self):
        from app.services import push_dispatcher

        sent = []
        original_send_push = push_dispatcher.send_push
        push_dispatcher.send_push = lambda *args, **kwargs: sent.append((args, kwargs)) or True
        try:
            repo = FakePushRepo({
                "id": "friend-1",
                "push_token": "token-1",
                "metadata": {"beacon_alerts": False},
            })

            result = push_dispatcher.dispatch_beacon_alert(
                repo,
                recipient_id="friend-1",
                sender_id="user-1",
                sender_name="Kyle",
            )
        finally:
            push_dispatcher.send_push = original_send_push

        self.assertEqual(result["reason"], "disabled")
        self.assertFalse(result["sent"])
        self.assertEqual(sent, [])
        self.assertEqual(repo.logs, [])

    def test_beacon_alert_sends_and_logs_when_reachable(self):
        from app.services import push_dispatcher

        sent = []
        original_send_push = push_dispatcher.send_push
        push_dispatcher.send_push = lambda *args, **kwargs: sent.append((args, kwargs)) or True
        try:
            repo = FakePushRepo({
                "id": "friend-1",
                "push_token": "token-1",
                "metadata": {},
            })

            result = push_dispatcher.dispatch_beacon_alert(
                repo,
                recipient_id="friend-1",
                sender_id="user-1",
                sender_name="Kyle",
            )
        finally:
            push_dispatcher.send_push = original_send_push

        self.assertTrue(result["sent"])
        self.assertEqual(result["reason"], "sent")
        self.assertEqual(len(sent), 1)
        args, kwargs = sent[0]
        self.assertEqual(args[0], "token-1")
        self.assertEqual(args[1], "Friendly")
        self.assertEqual(args[2], "Kyle could use some warmth right now.")
        self.assertEqual(kwargs["data"]["type"], "support_beacon")
        self.assertEqual(repo.logs[0][1], "support_beacon")


if __name__ == "__main__":
    unittest.main()
