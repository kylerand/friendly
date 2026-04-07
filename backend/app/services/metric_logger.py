from __future__ import annotations

from collections import defaultdict
from datetime import datetime, timedelta
from typing import Dict

FORBIDDEN_METRICS = {
    "engagement_time",
    "daily_active_users",
    "click_through_rate",
    "session_length_seconds",
}


class MetricLedger:
    def __init__(self, expiry_days: int = 7):
        self.expiry = timedelta(days=expiry_days)
        self._buckets: Dict[str, Dict[str, Dict[str, object]]] = defaultdict(dict)

    def _bucket_key(self, label: str | None = None) -> str:
        now = datetime.utcnow()
        hour_bucket = now.replace(minute=0, second=0, microsecond=0).isoformat()
        return f"{hour_bucket}#{label}" if label else hour_bucket

    def _cleanup(self) -> None:
        cutoff = datetime.utcnow() - self.expiry
        for name in list(self._buckets):
            buckets = self._buckets[name]
            for key in list(buckets):
                if buckets[key]["updated"] < cutoff:
                    del buckets[key]
            if not buckets:
                del self._buckets[name]

    def record(
        self,
        name: str,
        value: float = 1.0,
        bucket_label: str | None = None,
        note: str | None = None,
    ) -> None:
        """Record anonymized, bucketed events with expiration and aggregate rollups."""
        if name in FORBIDDEN_METRICS:
            return  # Forbidden metrics focus on engagement-first signals and must not be recorded.
        bucket_key = self._bucket_key(bucket_label)
        bucket = self._buckets[name].setdefault(
            bucket_key, {"value": 0.0, "updated": datetime.utcnow(), "note": None}
        )
        bucket["value"] += value
        bucket["updated"] = datetime.utcnow()
        bucket["note"] = note or bucket.get("note")
        self._cleanup()

    def rollup_summary(self) -> Dict[str, Dict[str, object]]:
        return {
            name: {
                "total": sum(bucket["value"] for bucket in buckets.values()),
                "bucket_count": len(buckets),
                "buckets": {key: bucket["value"] for key, bucket in buckets.items()},
            }
            for name, buckets in self._buckets.items()
        }

    def latest_buckets(self) -> Dict[str, str | None]:
        return {
            name: max(buckets.keys(), default=None)
            for name, buckets in self._buckets.items()
        }


metric_ledger = MetricLedger()


def record_connection_enablement(bucket_label: str | None = None) -> None:
    """Capture connection enablement signals while trading off granularity for privacy."""
    metric_ledger.record(
        "connection_enablement",
        bucket_label=bucket_label,
        note="Tracks gentle reconnection opportunity without capturing session durations.",
    )


def record_user_relief(bucket_label: str | None = None) -> None:
    """Log user relief attempts to monitor if nudges land without measuring usage."""
    metric_ledger.record(
        "user_relief",
        bucket_label=bucket_label,
        note="Focuses on relief-intent rather than engagement speed or clicks.",
    )


def record_signal_trust(trust_score: float, bucket_label: str | None = None) -> None:
    """Signal trust is bucketed so the dashboard can trade off coverage with anonymity."""
    safe_label = bucket_label or f"trust-{int(trust_score * 100)}"
    metric_ledger.record(
        "signal_trust",
        bucket_label=safe_label,
        note="Maintains ethical tradeoffs between accuracy and noise for aggregated insights.",
    )


def record_device_presence(bucket_label: str | None = None) -> None:
    """Device presence is tracked via aggregated buckets instead of per-user pings."""
    metric_ledger.record(
        "device_presence",
        bucket_label=bucket_label,
        note="Preserves privacy by never linking presence to identities or dwell times.",
    )


def dashboard_rollup() -> Dict[str, Dict[str, object]]:
    return metric_ledger.rollup_summary()


def dashboard_latest() -> Dict[str, str | None]:
    return metric_ledger.latest_buckets()
