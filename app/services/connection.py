from statistics import mean
from typing import Iterable, List

from app.schemas.models import InteractionResponse


def _interaction_deltas(interactions: Iterable[InteractionResponse]) -> List[float]:
    # InteractionResponse uses `created_at` for timestamps
    sorted_interactions = sorted(interactions, key=lambda i: i.created_at)
    return [
        (sorted_interactions[i].created_at - sorted_interactions[i - 1].created_at).total_seconds()
        for i in range(1, len(sorted_interactions))
    ]


def connection_drift(interactions: Iterable[InteractionResponse]) -> float:
    deltas = _interaction_deltas(interactions)
    if not deltas:
        return 0.0
    # TODO: link with sentiment scoring to weight drift
    recent = deltas[-3:]
    window = len(recent)
    return max(0.0, min(1.0, sum(recent) / (window * 60 * 60 * 24)))


def average_interaction_rate(interactions: Iterable[InteractionResponse]) -> float:
    deltas = _interaction_deltas(interactions)
    if not deltas:
        return 0.0
    return mean(deltas)


def eligible_for_nudge(interactions: Iterable[InteractionResponse]) -> bool:
    drift = connection_drift(interactions)
    rate = average_interaction_rate(interactions)
    # TODO: add logging for eligibility decision and review drift thresholds quarterly
    return drift > 0.5 or rate > 60 * 60 * 24
