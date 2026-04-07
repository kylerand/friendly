"""
Friendly Backend — GitHub Service

Creates GitHub issues from tester feedback reports via the GitHub REST API.
"""

import httpx

GITHUB_API = "https://api.github.com"


def _label_for_type(report_type: str) -> str:
    return {"bug": "bug", "ui": "ui", "feature": "enhancement"}.get(report_type, report_type)


def _label_for_severity(severity: str) -> str:
    return f"severity:{severity}"


def _build_issue_body(report: dict) -> str:
    lines = [report.get("description", "")]
    lines.append("")

    meta = []
    if report.get("device"):
        meta.append(f"- **Device:** {report['device']}")
    if report.get("app_version"):
        meta.append(f"- **App version:** {report['app_version']}")
    if report.get("contact"):
        meta.append(f"- **Contact:** {report['contact']}")
    meta.append(f"- **Severity:** {report.get('severity', 'medium')}")
    meta.append(f"- **Report ID:** `{report.get('id', 'unknown')}`")
    if meta:
        lines.append("### Details")
        lines.extend(meta)
        lines.append("")

    screenshots = report.get("screenshots") or []
    if screenshots:
        lines.append("### Screenshots / Links")
        for url in screenshots:
            lines.append(f"- {url}")
        lines.append("")

    return "\n".join(lines)


async def create_github_issue(
    token: str,
    repo: str,
    report: dict,
) -> dict:
    """Create a GitHub issue from a tester report. Returns {'url': ..., 'number': ...}."""
    title = f"[{report.get('type', 'bug').upper()}] {report.get('title', 'Untitled report')}"
    body = _build_issue_body(report)
    labels = [_label_for_type(report.get("type", "bug")), _label_for_severity(report.get("severity", "medium"))]

    async with httpx.AsyncClient() as client:
        headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        # Try with labels and assignee; fall back to title+body only on 422
        payload: dict = {"title": title, "body": body, "labels": labels, "assignees": ["copilot"]}
        resp = await client.post(
            f"{GITHUB_API}/repos/{repo}/issues",
            headers=headers,
            json=payload,
            timeout=15,
        )
        if resp.status_code == 422:
            payload = {"title": title, "body": body}
            resp = await client.post(
                f"{GITHUB_API}/repos/{repo}/issues",
                headers=headers,
                json=payload,
                timeout=15,
            )
        resp.raise_for_status()
        data = resp.json()
        return {"url": data["html_url"], "number": data["number"]}
