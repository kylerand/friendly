from typing import Dict

from app.schemas.models import Interaction
from app.services.connection import connection_drift, eligible_for_nudge
from app.services.metric_logger import (
    record_connection_enablement,
    record_signal_trust,
    record_user_relief,
)
from app.storage.storage import InMemoryStorage


def track_interaction(storage: InMemoryStorage, interaction: Interaction) -> Dict[str, object]:
    """Record the interaction, compute derived signals, and keep a TODO trail for persistence."""

    storage.save_interaction(interaction)
    interactions = storage.list_interactions(interaction.user_id)
    drift = connection_drift(interactions)
    nudge = eligible_for_nudge(interactions)
    record_signal_trust(min(drift, 1.0), bucket_label="drift")
    record_connection_enablement(bucket_label="interaction")
    if nudge:
        record_user_relief(bucket_label="nudge")
    # TODO: persist computed interaction summaries to a durable analytics store
    return {"connection_drift": drift, "nudge_eligible": nudge}
