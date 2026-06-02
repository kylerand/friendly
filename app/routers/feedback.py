"""
Feedback Router

Small app-facing feedback endpoint used by the mobile client for error reports.
It writes into tester_reports so pilot feedback and automatic app reports share
the same review queue.
"""

from fastapi import APIRouter, Depends

from app.db.repository import Repository
from app.dependencies import get_current_user_id, get_repository
from app.schemas.models import FeedbackCreate, TesterReportResponse

router = APIRouter(prefix="/feedback", tags=["feedback"])


@router.post("", response_model=TesterReportResponse)
def create_feedback(
    body: FeedbackCreate,
    user_id: str = Depends(get_current_user_id),
    repo: Repository = Depends(get_repository),
):
    title = body.title or body.source or "App feedback"
    description_parts = [
        body.description or body.message or "",
        f"Source: {body.source}" if body.source else "",
        f"Stack trace:\n{body.stack_trace}" if body.stack_trace else "",
    ]
    description = "\n\n".join(part for part in description_parts if part).strip()

    payload = {
        "user_id": user_id,
        "type": body.type,
        "title": title,
        "description": description or title,
        "severity": body.severity,
        "screenshots": body.screenshots,
        "device": body.device,
        "app_version": body.app_version,
        "contact": body.contact,
    }
    return repo.create_tester_report(payload)
