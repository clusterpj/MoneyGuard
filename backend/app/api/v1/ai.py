from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.services.ai_service import ai_service
from app.models.user import User

router = APIRouter()

class AiChatRequest(BaseModel):
    message: str

class AiChatResponse(BaseModel):
    response: str

@router.post("/chat", response_model=AiChatResponse)
def chat_with_ai(
    chat_request: AiChatRequest,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
) -> Any:
    """
    Get financial advice from the AI agent.
    """
    try:
        response_text = ai_service.get_financial_advice(
            db=db,
            user_id=current_user.id,
            message=chat_request.message
        )
        return AiChatResponse(response=response_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
