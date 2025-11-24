from typing import Optional
from pydantic import BaseModel, UUID4

class CategoryBase(BaseModel):
    name: str
    icon: Optional[str] = None
    is_default: Optional[bool] = False

class CategoryCreate(CategoryBase):
    pass

class Category(CategoryBase):
    id: UUID4
    user_id: Optional[UUID4] = None

    class Config:
        from_attributes = True
