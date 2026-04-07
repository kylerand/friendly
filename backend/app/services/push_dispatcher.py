"""
Push Dispatcher — Firebase Cloud Messaging

Sends push notifications to users via FCM.
Respects push_opt_in, logs dispatches, and enforces
the "protect the channel" rules from NUDGE_SYSTEM.md.
"""

import logging
from datetime import datetime, timezone

logger = logging.getLogger("friendly.push")

# Firebase Admin SDK — initialized lazily
_firebase_app = None


def _get_firebase():
    """Lazy-init Firebase Admin SDK from GOOGLE_APPLICATION_CREDENTIALS."""
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    try:
        import firebase_admin
        from firebase_admin import credentials
        import os

        cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        if cred_path:
            cred = credentials.Certificate(cred_path)
            _firebase_app = firebase_admin.initialize_app(cred)
        else:
            # Try default credentials (GCP environments)
            _firebase_app = firebase_admin.initialize_app()
        logger.info("Firebase Admin SDK initialized")
        return _firebase_app
    except Exception as e:
        logger.warning(f"Firebase init failed: {e}. Push notifications disabled.")
        return None


def send_push(token: str, title: str, body: str, data: dict | None = None) -> bool:
    """
    Send a single FCM push notification.

    Returns True if sent successfully, False otherwise.
    """
    app = _get_firebase()
    if app is None:
        logger.info(f"Push skipped (no Firebase): {title} → {body}")
        return False

    try:
        from firebase_admin import messaging

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=token,
        )
        response = messaging.send(message)
        logger.info(f"Push sent: {response}")
        return True
    except Exception as e:
        logger.error(f"Push send failed: {e}")
        return False


def dispatch_nudge(repo, user_id: str, nudge_tier: str, copy_text: str,
                   friend_id: str | None = None) -> bool:
    """
    Full nudge dispatch: check opt-in, send push, log to nudge_log.

    Enforces:
    - push_opt_in must be True
    - push_token must exist
    - max 1 nudge per day
    - max 4 nudges per absence cycle
    """
    profile = repo.get_profile(user_id)
    if not profile:
        return False

    if not profile.get("push_opt_in", False):
        logger.debug(f"Nudge skipped: user {user_id} not opted in")
        return False

    token = profile.get("push_token")
    if not token:
        logger.debug(f"Nudge skipped: user {user_id} has no push token")
        return False

    # Max 1 per day
    last_sent = profile.get("last_nudge_sent_at")
    if last_sent:
        if isinstance(last_sent, str):
            last_sent = datetime.fromisoformat(last_sent)
        if last_sent.tzinfo is None:
            last_sent = last_sent.replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        if (now - last_sent).total_seconds() < 86400:
            logger.debug(f"Nudge skipped: already sent today for user {user_id}")
            return False

    # Max 4 per cycle
    cycle_count = profile.get("nudge_cycle_count", 0)
    if cycle_count >= 4:
        logger.debug(f"Nudge skipped: cycle limit reached for user {user_id}")
        return False

    # Send the push
    title = "Friendly"
    success = send_push(token, title, copy_text, data={
        "type": "nudge",
        "nudge_tier": nudge_tier,
        "friend_id": friend_id or "",
    })

    if success:
        repo.create_nudge_log(user_id, nudge_tier, copy_text, friend_id)
        repo.increment_nudge_cycle(user_id)

    return success
