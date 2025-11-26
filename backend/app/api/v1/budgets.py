from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from app.api import deps
from app.models.budget import Budget
from app.models.expense import Expense
from app.schemas.budget import (
    Budget as BudgetSchema,
    BudgetCreate,
    BudgetUpdate,
    BudgetWithSpending
)
from app.models.user import User
from datetime import date

router = APIRouter()

@router.post("/", response_model=BudgetSchema, status_code=201)
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

@router.get("/", response_model=List[BudgetSchema])
def read_budgets(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Retrieve all budgets for the current user.
    """
    budgets = db.query(Budget).filter(
        Budget.user_id == current_user.id
    ).offset(skip).limit(limit).all()
    return budgets

@router.get("/current", response_model=BudgetWithSpending)
def read_current_budget(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    category_id: str = None,
) -> Any:
    """
    Get current active budget with spending information.
    """
    today = date.today()
    query = db.query(Budget).filter(
        Budget.user_id == current_user.id,
        Budget.start_date <= today,
        Budget.end_date >= today
    )
    
    if category_id:
        query = query.filter(Budget.category_id == category_id)
    else:
        query = query.filter(Budget.category_id.is_(None))
    
    budget = query.first()
    
    if not budget:
        raise HTTPException(status_code=404, detail="No active budget found")
    
    # Calculate spending
    expense_query = db.query(func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        Expense.date >= budget.start_date,
        Expense.date <= budget.end_date
    )
    
    if budget.category_id:
        expense_query = expense_query.filter(Expense.category_id == budget.category_id)
    
    spent = expense_query.scalar() or 0.0
    remaining = budget.amount - spent
    percentage_used = (spent / budget.amount * 100) if budget.amount > 0 else 0
    
    return BudgetWithSpending(
        **budget.__dict__,
        spent=spent,
        remaining=remaining,
        percentage_used=percentage_used
    )

@router.get("/analytics", response_model=List[BudgetWithSpending])
def get_budget_analytics(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Get all active budgets with spending analytics.
    """
    today = date.today()
    budgets = db.query(Budget).filter(
        Budget.user_id == current_user.id,
        Budget.start_date <= today,
        Budget.end_date >= today
    ).all()
    
    result = []
    for budget in budgets:
        # Calculate spending for this budget
        expense_query = db.query(func.sum(Expense.amount)).filter(
            Expense.user_id == current_user.id,
            Expense.date >= budget.start_date,
            Expense.date <= budget.end_date
        )
        
        if budget.category_id:
            expense_query = expense_query.filter(Expense.category_id == budget.category_id)
        
        spent = expense_query.scalar() or 0.0
        remaining = budget.amount - spent
        percentage_used = (spent / budget.amount * 100) if budget.amount > 0 else 0
        
        result.append(BudgetWithSpending(
            **budget.__dict__,
            spent=spent,
            remaining=remaining,
            percentage_used=percentage_used
        ))
    
    return result

@router.get("/{budget_id}", response_model=BudgetSchema)
def read_budget(
    *,
    db: Session = Depends(deps.get_db),
    budget_id: str,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Get budget by ID.
    """
    budget = db.query(Budget).filter(
        Budget.id == budget_id,
        Budget.user_id == current_user.id
    ).first()
    
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    return budget

@router.put("/{budget_id}", response_model=BudgetSchema)
def update_budget(
    *,
    db: Session = Depends(deps.get_db),
    budget_id: str,
    budget_in: BudgetUpdate,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Update budget.
    """
    budget = db.query(Budget).filter(
        Budget.id == budget_id,
        Budget.user_id == current_user.id
    ).first()
    
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    update_data = budget_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(budget, field, value)
    
    db.commit()
    db.refresh(budget)
    return budget

@router.delete("/{budget_id}", status_code=204)
def delete_budget(
    *,
    db: Session = Depends(deps.get_db),
    budget_id: str,
    current_user: User = Depends(deps.get_current_user),
) -> None:
    """
    Delete budget.
    """
    budget = db.query(Budget).filter(
        Budget.id == budget_id,
        Budget.user_id == current_user.id
    ).first()
    
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    db.delete(budget)
    db.commit()
    return None
