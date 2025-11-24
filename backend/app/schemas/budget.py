from datetime import date
from typing import Optional
from pydantic import BaseModel, UUID4
from app.models.budget import BudgetPeriod

class BudgetBase(BaseModel):
    amount: float
    period: Optional[BudgetPeriod] = BudgetPeriod.MONTHLY
    start_date: date
    end_date: date

class BudgetCreate(BudgetBase):
    pass

class Budget(BudgetBase):
    id: UUID4
    user_id: UUID4

    class Config:
        from_attributes = True
