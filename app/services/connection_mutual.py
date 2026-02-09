from typing import Dict, List

from app.schemas.models import AmbientSignal


def mutual_signal_confirmation(signals_a: List[AmbientSignal], signals_b: List[AmbientSignal]) -> Dict[str, object]:
    """Confirm that both participants have shared ambient signals for mutual consent."""

    tags_a = {tag for signal in signals_a for tag in signal.tags}
    tags_b = {tag for signal in signals_b for tag in signal.tags}
    shared_tags = tags_a.intersection(tags_b)
    strength = sum(
        min(
            sum(tag in signal.tags for signal in signals_a),
            sum(tag in signal.tags for signal in signals_b),
        )
        for tag in shared_tags
    )
    mutual_strength = strength / max(len(shared_tags), 1) if shared_tags else 0.0

    # TODO: persist tagging thresholds and confirmation records in durable audit log
    return {
        "shared_tags": list(shared_tags),
        "mutual_strength": mutual_strength,
        "mutual_confirmed": mutual_strength >= 1.0 and bool(signals_a) and bool(signals_b),
    }
