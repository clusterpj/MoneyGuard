from datetime import date
from typing import Optional
from pydantic import BaseModel, UUID4
from app.models.budget import BudgetPeriod
from app.schemas.category import Category

class BudgetBase(BaseModel):
    name: Optional[str] = None
    amount: float
    period: Optional[BudgetPeriod] = BudgetPeriod.MONTHLY
    start_date: date
    end_date: date
    category_id: Optional[UUID4] = None

class BudgetCreate(BudgetBase):
    pass

class BudgetUpdate(BaseModel):
    name: Optional[str] = None
    amount: Optional[float] = None
    period: Optional[BudgetPeriod] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    category_id: Optional[UUID4] = None

class Budget(BudgetBase):
    id: UUID4
    user_id: UUID4
    category: Optional[Category] = None

    class Config:
        from_attributes = True

class BudgetWithSpending(Budget):
    spent: float
    remaining: float
    percentage_used: float
