from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.budget import Budget
from app.schemas.budget import Budget as BudgetSchema, BudgetCreate
from app.models.user import User
from datetime import date

router = APIRouter()

@router.post("/", response_model=BudgetSchema)
def create_budget(
    *,
    db: Session = Depends(deps.get_db),
    budget_in: BudgetCreate,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Create new budget.
    """
    budget = Budget(
        **budget_in.model_dump(),
        user_id=current_user.id
    )
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget

@router.get("/current", response_model=BudgetSchema)
def read_current_budget(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Get current active budget.
    """
    today = date.today()
    budget = db.query(Budget).filter(
        Budget.user_id == current_user.id,
        Budget.start_date <= today,
        Budget.end_date >= today
    ).first()
    
    if not budget:
        raise HTTPException(status_code=404, detail="No active budget found")
    return budget
