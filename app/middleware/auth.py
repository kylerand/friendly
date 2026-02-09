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

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt

from app.config import Settings, get_settings

security = HTTPBearer()


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    settings: Settings = Depends(get_settings),
) -> str:
    """
    Decode the Supabase JWT and return the user's UUID (`sub` claim).

    Supabase JWTs use HS256 with the project's JWT secret.
    The `sub` claim contains the user's UUID from auth.users.
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
        )
    except jwt.InvalidTokenError:
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
