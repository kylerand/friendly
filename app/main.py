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
from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import admin, ambient, auth, check_ins, friendships, interactions, profiles, tester
from app.routers.debug_token import router as debug_router
from app.routers import nudges
from app.routers import signals
from app.routers import friend_notes
from app.routers import friend_reminders

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: start the nudge scheduler
    try:
        from app.services.nudge_scheduler import start_scheduler
        start_scheduler()
    except Exception as e:
        logging.getLogger("friendly").warning(f"Scheduler start failed: {e}")
    yield
    # Shutdown: stop the scheduler
    try:
        from app.services.nudge_scheduler import stop_scheduler
        stop_scheduler()
    except Exception:
        pass


app = FastAPI(
    title="Friendly Backend",
    version="0.2.0-nudge",
    docs_url="/docs" if not settings.is_pilot else None,
    redoc_url=None,
    lifespan=lifespan,
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
app.include_router(tester.router)
app.include_router(profiles.router)
app.include_router(friendships.router)
app.include_router(interactions.router)
app.include_router(ambient.router)
app.include_router(check_ins.router)
app.include_router(nudges.router)
app.include_router(signals.router)
app.include_router(friend_notes.router)
app.include_router(friend_reminders.router)
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
