"""
Friendly Backend — Application Entry Point

FastAPI app with:
- CORS for mobile app access
- Health check endpoint with DB connectivity test
- All routers mounted under their prefixes
- No authentication on /health (so Railway can probe it)
"""

from fastapi import FastAPI
import logging
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import admin, ambient, auth, check_ins, friendships, interactions, profiles
from app.routers.debug_token import router as debug_router
from app.routers import nudges

settings = get_settings()

app = FastAPI(
    title="Friendly Backend",
    version="0.1.0-pilot",
    docs_url="/docs" if not settings.is_pilot else None,   # disable Swagger in pilot
    redoc_url=None,
)

# Enable debug logging for authentication middleware
logging.basicConfig(level=logging.INFO)
logging.getLogger("friendly.auth").setLevel(logging.DEBUG)

# -- CORS --
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -- Routers --
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(profiles.router)
app.include_router(friendships.router)
app.include_router(interactions.router)
app.include_router(ambient.router)
app.include_router(check_ins.router)
app.include_router(nudges.router)
app.include_router(debug_router)


# -- Health check (unauthenticated — Railway needs this) --
@app.get("/health")
def health():
    from app.db.repository import Repository

    repo = Repository()
    db_ok = repo.health_check()
    return {
        "status": "ok" if db_ok else "degraded",
        "environment": settings.environment,
        "database": "connected" if db_ok else "unreachable",
    }
