from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import base64
import json

from app.config import get_settings

router = APIRouter(prefix="/debug")


class TokenPayload(BaseModel):
    token: str


@router.post('/token')
def decode_token(payload: TokenPayload):
    settings = get_settings()
    if settings.environment == 'production':
        raise HTTPException(status_code=404, detail='Not found')

    token = payload.token.strip()
    parts = token.split('.')
    if len(parts) < 2:
        raise HTTPException(status_code=400, detail='Invalid token format')

    def _b64_decode(s: str):
        # base64 urlsafe padding fix
        s += '=' * (-len(s) % 4)
        return base64.urlsafe_b64decode(s.encode('utf-8'))

    try:
        header = json.loads(_b64_decode(parts[0]))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f'Header decode error: {e}')

    try:
        payload = json.loads(_b64_decode(parts[1]))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f'Payload decode error: {e}')

    return {"header": header, "payload": payload}
