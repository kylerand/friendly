# ============================================================================
# Friendly Backend — Dockerfile
# ============================================================================
# Minimal Python image. No build tools needed (no compiled deps for pilot).
# Railway auto-detects this Dockerfile and builds from it.
# ============================================================================

FROM python:3.12-slim

# Prevent Python from writing .pyc files and enable unbuffered stdout
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first (cache layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Railway sets PORT automatically; default to 8000 for local Docker
ENV PORT=8000

# Health check for Railway
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT}/health')"

# Run with uvicorn — Railway passes PORT via env
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
