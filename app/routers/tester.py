"""
Tester Router

Endpoints for pilot/tester feedback submissions.
"""

from fastapi import APIRouter, Depends, HTTPException

from app.db.repository import Repository
from app.dependencies import get_repository
from app.middleware.admin import require_admin_user
from app.middleware.portal import require_portal_user
from app.schemas.models import (
    PortalMeResponse,
    TesterReportCreate,
    TesterReportResponse,
    TesterReportStatusUpdate,
)

router = APIRouter(prefix="/tester", tags=["tester"])


@router.get("/me", response_model=PortalMeResponse)
def get_portal_me(portal=Depends(require_portal_user)):
    return portal


@router.post("/reports", response_model=TesterReportResponse)
def create_report(
    body: TesterReportCreate,
    portal=Depends(require_portal_user),
    repo: Repository = Depends(get_repository),
):
    payload = body.model_dump()
    payload["user_id"] = portal["user_id"]
    return repo.create_tester_report(payload)


@router.get("/reports", response_model=list[TesterReportResponse])
def list_reports(
    status: str | None = None,
    report_type: str | None = None,
    limit: int = 100,
    portal=Depends(require_portal_user),
    repo: Repository = Depends(get_repository),
):
    if limit > 200:
        raise HTTPException(status_code=400, detail="Limit too large")
    user_id = None if portal.get("is_admin") else portal["user_id"]
    return repo.list_tester_reports(
        user_id=user_id,
        status=status,
        report_type=report_type,
        limit=limit,
    )


@router.patch("/reports/{report_id}/status", response_model=TesterReportResponse)
def update_report_status(
    report_id: str,
    body: TesterReportStatusUpdate,
    admin=Depends(require_admin_user),
    repo: Repository = Depends(get_repository),
):
    if body.status not in {"new", "triage", "in_progress", "resolved", "closed"}:
        raise HTTPException(status_code=400, detail="Invalid status")
    return repo.update_tester_report_status(report_id, body.status)
