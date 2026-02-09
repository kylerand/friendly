from typing import Dict, List

from app.schemas.models import AmbientSignal
from app.services.metric_logger import (
    record_device_presence,
    record_signal_trust,
)


def summarize_signals(signals: List[AmbientSignal]) -> Dict[str, object]:
    if not signals:
        return {}

    values = [s.value for s in signals]
    tags = {tag for signal in signals for tag in signal.tags}
    record_signal_trust(sum(values) / len(values) if values else 0.0, bucket_label="ambient")
    record_device_presence(bucket_label="device_poll")
    return {"average": sum(values) / len(values), "tags": list(tags)}
