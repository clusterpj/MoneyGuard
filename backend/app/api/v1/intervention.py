from typing import Any
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.models.user import User
from app.services.intervention import InterventionService

router = APIRouter()

class InterventionCheckRequest(BaseModel):
    amount: float
    category: str

class InterventionCheckResponse(BaseModel):
    should_intervene: bool
    message: str | None = None
    reasons: list[str] | None = None

@router.post("/check", response_model=InterventionCheckResponse)
async def check_intervention(
    request: InterventionCheckRequest,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Check if an expense triggers an intervention.
    """
    service = InterventionService(db)
    result = await service.check_intervention(
        user=current_user,
        amount=request.amount,
        category_name=request.category
    )
    return result
