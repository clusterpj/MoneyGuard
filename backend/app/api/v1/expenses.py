from typing import Any, List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session
from app.api import deps
from app.models.expense import Expense, ExpenseSource
from app.schemas.expense import Expense as ExpenseSchema, ExpenseCreate
from app.models.user import User
from app.services.ocr import ocr_service

router = APIRouter()

@router.post("/", response_model=ExpenseSchema)
def create_expense(
    *,
    db: Session = Depends(deps.get_db),
    expense_in: ExpenseCreate,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Create new expense.
    """
    # Handle category lookup/creation
    if expense_in.category_name:
        from app.models.category import Category
        category = db.query(Category).filter(
            Category.name == expense_in.category_name,
            Category.user_id == current_user.id
        ).first()
        if not category:
            category = Category(name=expense_in.category_name, user_id=current_user.id)
            db.add(category)
            db.commit()
            db.refresh(category)
        expense_in.category_id = category.id

    expense = Expense(
        **expense_in.model_dump(exclude={"category_name"}),
        user_id=current_user.id
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense

@router.get("/", response_model=List[ExpenseSchema])
def read_expenses(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    category_id: Optional[str] = None,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Retrieve expenses with optional filtering.
    """
    query = db.query(Expense).filter(Expense.user_id == current_user.id)
    
    if start_date:
        query = query.filter(Expense.date >= start_date)
    if end_date:
        query = query.filter(Expense.date <= end_date)
    if category_id:
        query = query.filter(Expense.category_id == category_id)
        
    expenses = query.order_by(Expense.date.desc()).offset(skip).limit(limit).all()
    return expenses

@router.get("/{id}", response_model=ExpenseSchema)
def read_expense(
    *,
    db: Session = Depends(deps.get_db),
    id: str,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Get expense by ID.
    """
    expense = db.query(Expense).filter(
        Expense.id == id,
        Expense.user_id == current_user.id
    ).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    return expense

@router.put("/{id}", response_model=ExpenseSchema)
def update_expense(
    *,
    db: Session = Depends(deps.get_db),
    id: str,
    expense_in: ExpenseCreate,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Update an expense.
    """
    expense = db.query(Expense).filter(
        Expense.id == id,
        Expense.user_id == current_user.id
    ).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    
    # Handle category lookup/creation (similar to create)
    if expense_in.category_name:
        from app.models.category import Category
        category = db.query(Category).filter(
            Category.name == expense_in.category_name,
            Category.user_id == current_user.id
        ).first()
        if not category:
            category = Category(name=expense_in.category_name, user_id=current_user.id)
            db.add(category)
            db.commit()
            db.refresh(category)
        expense_in.category_id = category.id
    
    update_data = expense_in.model_dump(exclude_unset=True, exclude={"category_name"})
    for field, value in update_data.items():
        setattr(expense, field, value)
        
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense

@router.delete("/{id}", response_model=ExpenseSchema)
def delete_expense(
    *,
    db: Session = Depends(deps.get_db),
    id: str,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Delete an expense.
    """
    expense = db.query(Expense).filter(
        Expense.id == id,
        Expense.user_id == current_user.id
    ).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    db.delete(expense)
    db.commit()
    return expense

@router.post("/upload-receipt", response_model=ExpenseCreate)
async def upload_receipt(
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Upload a receipt image for OCR processing.
    Returns extracted expense data.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image"
        )
    
    content = await file.read()
    extracted_data = await ocr_service.process_image(content)
    
    # Map extracted data to ExpenseCreate schema
    # Note: category_id is not guessed by mock OCR, so it remains None
    return ExpenseCreate(
        amount=extracted_data.get("amount", 0.0),
        description=extracted_data.get("description"),
        date=extracted_data.get("date"),
        source=ExpenseSource.OCR,
        ocr_raw_text=extracted_data.get("ocr_raw_text"),
        ocr_confidence=extracted_data.get("ocr_confidence")
    )
