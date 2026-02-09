"""
Friendly Backend — JWT Authentication Middleware

Verifies Supabase JWTs on incoming requests. The backend trusts Supabase
as the auth authority and never stores passwords.

Flow:
1. Client sends `Authorization: Bearer <supabase_access_token>`.
2. This dependency decodes the JWT using the Supabase JWT secret.
3. Returns the authenticated user's UUID.
4. Routers use this UUID to scope all database operations.

If the token is missing, expired, or invalid → 401 Unauthorized.
"""

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
import logging

from app.config import Settings, get_settings

security = HTTPBearer(auto_error=False)
logger = logging.getLogger("friendly.auth")


def get_current_user_id(
    request: Request,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    settings: Settings = Depends(get_settings),
) -> str:
    """
    Decode the Supabase JWT and return the user's UUID (`sub` claim).

    Supabase JWTs use HS256 with the project's JWT secret.
    The `sub` claim contains the user's UUID from auth.users.
    """
    # If credentials were not provided the HTTPBearer dependency will
    # return None (we set auto_error=False). Log request info for
    # debugging and return a 403 to match previous behaviour.
    if not credentials:
        auth_header = request.headers.get("authorization")
        ua = request.headers.get("user-agent")
        client_ip = None
        try:
            client_ip = request.client.host
        except Exception:
            client_ip = "unknown"
        logger.warning(
            "Missing credentials for request %s from %s UA=%s auth_header=%s",
            request.url.path,
            client_ip,
            ua,
            (auth_header[:32] + "...") if auth_header else None,
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authenticated",
        )

    token = credentials.credentials
    masked = (token[:12] + "...") if token else None
    logger.debug("Decoding token for request %s from %s — token=%s",
                 request.url.path,
                 getattr(request.client, "host", "unknown"),
                 masked)

    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.ExpiredSignatureError:
        logger.info("Expired token for request %s token=%s", request.url.path, masked)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
        )
    except jwt.InvalidTokenError:
        logger.warning("Invalid token for request %s token=%s", request.url.path, masked)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
        )

    user_id: str | None = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing user identity",
        )
    return user_id
