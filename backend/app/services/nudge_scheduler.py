"""
Nudge Scheduler — APScheduler background job

Runs inside the FastAPI process. Checks nudge eligibility for all
opted-in users and dispatches push notifications via FCM.

Design rules (from NUDGE_SYSTEM.md):
- Max 1 push per day per user
- Max 4 pushes per absence cycle
- Respectful silence after cycle 4
- Stateless scheduling: all state comes from the database
"""

import logging
from datetime import datetime, timezone

from apscheduler.schedulers.background import BackgroundScheduler

from app.db.repository import Repository
from app.routers.nudges import get_warmth, _compute_nudge_tier, _pick_copy
from app.services.push_dispatcher import dispatch_nudge

logger = logging.getLogger("friendly.scheduler")

scheduler = BackgroundScheduler()


def _run_nudge_dispatch():
    """Check all eligible users and send nudges."""
    logger.info("Running nudge dispatch job...")
    try:
        repo = Repository()
        users = repo.list_nudge_eligible_users()
        dispatched = 0

        for user in users:
            user_id = user["id"]
            try:
                warmth = get_warmth(user_id=user_id, repo=repo)
                if warmth.nudge_tier is None:
                    continue

                friend_name = (
                    warmth.suggested_friend.friend_name
                    if warmth.suggested_friend
                    else None
                )
                friend_id = (
                    warmth.suggested_friend.friend_id
                    if warmth.suggested_friend
                    else None
                )
                copy = _pick_copy(warmth.nudge_tier, friend_name)

                success = dispatch_nudge(
                    repo, user_id, warmth.nudge_tier, copy, friend_id
                )
                if success:
                    dispatched += 1

            except Exception as e:
                logger.error(f"Nudge dispatch error for user {user_id}: {e}")
                continue

        logger.info(f"Nudge dispatch complete: {dispatched}/{len(users)} sent")

    except Exception as e:
        logger.error(f"Nudge dispatch job failed: {e}")


def start_scheduler():
    """Start the background scheduler with the nudge dispatch job."""
    # Run every hour, checking against each user's preferred time
    scheduler.add_job(
        _run_nudge_dispatch,
        "interval",
        hours=1,
        id="nudge_dispatch",
        replace_existing=True,
        next_run_time=None,  # Don't run immediately on startup
    )
    scheduler.start()
    logger.info("Nudge scheduler started (hourly check)")


def stop_scheduler():
    """Gracefully shut down the scheduler."""
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("Nudge scheduler stopped")
