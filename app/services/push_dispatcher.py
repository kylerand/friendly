from typing import Dict

from app.schemas.models import CheckIn
from app.storage.storage import InMemoryStorage


def dispatch_push_notification(
    storage: InMemoryStorage, user_id: str, message: str, metadata: Dict[str, object]
) -> None:
    """Queue a push while documenting consent steps for future persistence."""

    # TODO: respect explicit push opt-ins and archive dispatch logs
    # TODO: replace CheckIn reuse with dedicated push queue records
    check_in = CheckIn(
        id=f"push-{user_id}-{len(metadata)}",
        user_id=user_id,
        mood=message,
        notes=str(metadata),
    )
    storage.save_check_in(check_in)
