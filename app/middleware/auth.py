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
    # Determine token algorithm from the header and verify accordingly.
    try:
        unverified_header = jwt.get_unverified_header(token)
        alg = unverified_header.get("alg", "")
    except jwt.InvalidTokenError:
        logger.warning("Invalid token header for request %s token=%s", request.url.path, masked)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
        )

    # Use shared secret for HMAC-signed tokens (HS*). For asymmetric tokens
    # (ES*, RS*) fetch the JWKS from the Supabase project's well-known URL
    # and use the corresponding public key for verification.
    verification_key = None
    verification_algorithms = [alg] if alg else ["HS256"]

    if alg.startswith("HS"):
        if not settings.supabase_jwt_secret:
            logger.error(
                "HS-signed token received but SUPABASE_JWT_SECRET is not configured"
            )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Server misconfiguration: SUPABASE_JWT_SECRET required for HS-signed tokens",
            )
        verification_key = settings.supabase_jwt_secret
    else:
        # Fetch JWKS from Supabase and resolve the signing key.
        # Supabase exposes JWKS under the auth v1 path
        jwks_url = settings.supabase_url.rstrip("/") + "/auth/v1/.well-known/jwks.json"
        try:
            jwk_client = jwt.PyJWKClient(jwks_url)
            signing_key = jwk_client.get_signing_key_from_jwt(token)
            verification_key = signing_key.key
        except Exception as exc:  # network error or kid not found
            logger.warning(
                "Failed to resolve JWKS key for request %s token=%s error=%s",
                request.url.path,
                masked,
                str(exc),
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
            )

    try:
        payload = jwt.decode(
            token,
            verification_key,
            algorithms=verification_algorithms,
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
