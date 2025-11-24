from typing import Optional
from pydantic import BaseModel, EmailStr, UUID4
from app.models.user import InterventionMode

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    is_active: Optional[bool] = True
    intervention_mode: Optional[InterventionMode] = InterventionMode.BALANCED

class UserCreate(UserBase):
    password: str

class UserUpdate(UserBase):
    password: Optional[str] = None

class UserInDBBase(UserBase):
    id: UUID4
    
    class Config:
        from_attributes = True

class User(UserInDBBase):
    pass

class UserInDB(UserInDBBase):
    hashed_password: str
