from app.services.metric_logger import dashboard_latest, dashboard_rollup


def system_health_dashboard() -> dict:
    """Scaffold for internal dashboard summarizing aggregated system health."""

    rollups = dashboard_rollup()
    latest = dashboard_latest()
    return {
        "system_health_rollups": rollups,
        "latest_buckets": latest,
    }
