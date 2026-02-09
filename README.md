# 🎯 Friendly Backend

FastAPI backend for the Friendly app — deployed to **Railway**, backed by **Supabase Postgres** with Row Level Security.

## Quick Start (Local Development)

```bash
# 1. Create virtual environment
python -m venv .venv
source .venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Copy and fill in environment variables
cp .env.example .env
# Edit .env with your Supabase credentials

# 4. Run the dev server
uvicorn app.main:app --reload
```

The API runs at `http://localhost:8000`. Health check: `GET /health`.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | ✅ | Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anon/public key |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | Supabase service role key (server-only) |
| `DATABASE_URL` | ✅ | Postgres connection string |
| `SUPABASE_JWT_SECRET` | ✅ | JWT secret for token verification |
| `ENVIRONMENT` | | `development` (default), `pilot`, or `production` |
| `ALLOWED_ORIGINS` | | Comma-separated CORS origins (default `*`) |
| `LOG_LEVEL` | | `debug`, `info` (default), `warning`, `error` |

## API Routes

All routes (except `/health`) require `Authorization: Bearer <supabase-jwt>`.

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check (unauthenticated) |
| `GET` | `/auth/me` | Get current user profile |
| `PATCH` | `/auth/me` | Update display name / avatar |
| `POST` | `/friendships` | Send a friendship request |
| `GET` | `/friendships` | List friendships with drift & nudge data |
| `PATCH` | `/friendships/{id}` | Update friendship status |
| `POST` | `/check-ins` | Record a daily check-in |
| `GET` | `/check-ins` | List check-in history |
| `POST` | `/interactions` | Log an interaction |
| `GET` | `/interactions` | List interactions |
| `POST` | `/ambient/signals` | Record an ambient signal |
| `GET` | `/ambient/signals` | List ambient signals |

## Architecture

```
app/
  config.py          ← Settings via pydantic-settings (env vars)
  main.py            ← FastAPI app, CORS, router mounts
  dependencies.py    ← Dependency injection (Repository, auth)
  db/
    __init__.py      ← Supabase client factory (admin + anon)
    repository.py    ← Data access layer (all CRUD)
  middleware/
    auth.py          ← JWT verification → user UUID
  routers/
    auth.py          ← Profile endpoints
    friendships.py   ← Friendship CRUD + drift/nudge computation
    interactions.py  ← Interaction logging
    ambient.py       ← Ambient signal endpoints
    check_ins.py     ← Check-in endpoints
  schemas/
    models.py        ← Pydantic request/response models
  services/
    connection.py    ← Connection drift & nudge eligibility (pure functions)
    connection_mutual.py  ← Mutual signal confirmation
    ambient.py       ← Signal summarization
    ...              ← Other service modules
```

## Deployment (Railway)

```bash
# Install Railway CLI, then:
cd backend
railway login
railway init
railway link
railway up
```

See `railway.toml` for deployment config. The Dockerfile builds a slim Python 3.12 image. Health check at `/health` is configured for Railway's monitoring.

## Data Model

All tables live in Supabase Postgres with RLS policies. See `supabase/migrations/001_initial_schema.sql`.

- **profiles** — extends `auth.users`, auto-created on signup
- **friendships** — bidirectional pairs with status enum
- **check_ins** — daily self-reflection scores (1–5)
- **interactions** — logged contact events
- **ambient_signals** — passive context data
- **device_state** — future device context

## Ethical Notes

- Services document drift, nudge, and mutual signal logic with traceability.
- Push dispatching respects opt-in enforcement and consent.
- Friendship lists expose only derived metrics — no implicit relationship value assumptions.
- RLS ensures users can only access their own data, even if backend code has bugs.
- No protected attributes are inferred, stored, or used in decision logic.
