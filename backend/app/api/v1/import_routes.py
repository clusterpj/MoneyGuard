from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from typing import List, Any
from app.services.statement_parser import statement_parser
from app.models.expense import Expense, ExpenseSource
from app.api.deps import get_db
from sqlalchemy.orm import Session
from app.models.user import User
from app.api.deps import get_current_user
from datetime import datetime

router = APIRouter()

@router.post("/upload", response_model=List[Any])
async def upload_statement(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Upload a bank statement (PDF) or PayPal log (CSV) and parse it into transactions.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    content = await file.read()
    
    try:
        if file.filename.lower().endswith('.pdf'):
            transactions = await statement_parser.parse_pdf(content)
        elif file.filename.lower().endswith('.csv'):
            transactions = await statement_parser.parse_csv(content)
        else:
            raise HTTPException(status_code=400, detail="Unsupported file format. Please upload PDF or CSV.")
            
        return transactions
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        print(f"Error processing file: {e}")
        raise HTTPException(status_code=500, detail="Failed to process file")

@router.post("/confirm", response_model=List[Any])
async def confirm_import(
    transactions: List[dict],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Confirm and save imported transactions.
    """
    saved_expenses = []
    for tx in transactions:
        try:
            # Basic validation and conversion
            amount = float(tx.get("amount", 0))
            date_str = tx.get("date")
            date = datetime.now()
            
            if date_str:
                try:
                    # Try ISO format
                    date = datetime.fromisoformat(date_str)
                except ValueError:
                    try:
                         # Try common formats like DD/MM/YYYY or YYYY/MM/DD
                         from dateutil import parser
                         date = parser.parse(date_str)
                    except:
                        print(f"Failed to parse date: {date_str}, using now()")
                        date = datetime.now()
                
            print(f"DEBUG: Creating expense. Source: 'import'")
            
            expense = Expense(
                amount=abs(amount), # Store as positive expense, handle income logic if needed later
                description=tx.get("description", "Imported Transaction"),
                date=date,
                source=ExpenseSource.IMPORT,
                user_id=current_user.id,
                # category_id could be matched here if we had logic, for now leave null or default
            )
            # print(f"DEBUG: Expense object created. Source attribute: {expense.source}")
            db.add(expense)
            saved_expenses.append(expense)
        except Exception as e:
            print(f"Skipping invalid transaction: {tx}, error: {e}")
            continue
            
    db.commit()
    return [{"id": str(e.id), "description": e.description, "amount": e.amount} for e in saved_expenses]
