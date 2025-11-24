from datetime import datetime
from typing import Optional
from pydantic import BaseModel, UUID4
from app.models.expense import ExpenseSource
from app.schemas.category import Category

class ExpenseBase(BaseModel):
    amount: float
    description: Optional[str] = None
    date: Optional[datetime] = None
    category_id: Optional[UUID4] = None
    source: Optional[ExpenseSource] = ExpenseSource.MANUAL
    ocr_raw_text: Optional[str] = None
    ocr_confidence: Optional[float] = None

class ExpenseCreate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    id: UUID4
    user_id: UUID4
    category: Optional[Category] = None

    class Config:
        from_attributes = True
