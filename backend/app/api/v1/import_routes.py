from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from typing import List, Any, Dict
from app.services.statement_parser import statement_parser
from app.models.expense import Expense, ExpenseSource
from app.api.deps import get_db
from sqlalchemy.orm import Session
from app.models.user import User
from app.api.deps import get_current_user
from datetime import datetime

from app.services.document_agent import DocumentAgentService

router = APIRouter()
document_agent = DocumentAgentService()

@router.post("/analyze", response_model=Dict[str, Any])
async def analyze_document_endpoint(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Analyze any document and return structured data with classification.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    content = await file.read()
    try:
        result = await document_agent.process_document(
            content, 
            file.filename, 
            file.content_type or "application/octet-stream"
        )
        return result
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error analyzing document: {e!r}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/upload", response_model=List[Any])
async def upload_statement(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Upload a bank statement (PDF) or generic file and parse it into transactions.
    Now uses the advanced Document Agent.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    content = await file.read()
    
    try:
        # Use new agent
        result = await document_agent.process_document(
            content,
            file.filename, 
            file.content_type or "application/octet-stream"
        )
        
        structured = result.get("structured_content", {})
        metadata = result.get("metadata", {})
        quality = result.get("quality", {})
        
        ocr_raw_text = metadata.get("raw_text")
        ocr_confidence = quality.get("confidence_overall")

        transactions = []
        
        # Strategy 1: Explicit transactions (Bank Statements, Credit Card)
        if "transactions" in structured:
            transactions = structured["transactions"]
        # Strategy 2: Line items (Invoices, Receipts) - IF the user wants detail
        elif "line_items" in structured and structured["line_items"]:
            transactions = structured["line_items"]
            # Inject date if missing from line items but present in top-level
            top_level_date = structured.get("date") or structured.get("invoice_date") or structured.get("receipt_date")
            if top_level_date:
                for tx in transactions:
                    if not tx.get("date"):
                        tx["date"] = top_level_date
        # Strategy 3: Single Receipt Fallback
        # If no transactions/line_items found, but we have a total amount (typical for a receipt)
        # Create a single transaction representing the whole document.
        if not transactions and (structured.get("total_amount") or structured.get("amount")):
             # Determine amount
            amount = structured.get("total_amount") or structured.get("amount") or 0
            
            # Determine date
            date = structured.get("date") or structured.get("statement_date") or structured.get("period_end")
            
            # Determine description
            description = structured.get("vendor_name") or structured.get("merchant_name") or structured.get("title") or "Unknown Receipt"
            
            transactions.append({
                "description": description,
                "amount": amount,
                "date": date
            })
            
        # Inject metadata into every transaction item so it can be saved
        for tx in transactions:
            tx["ocr_raw_text"] = ocr_raw_text
            tx["ocr_confidence"] = ocr_confidence
            # Ensure amount is absolute float for consistency if not already
            if "amount" not in tx and "total" in tx:
                 tx["amount"] = tx["total"] # Handle invoice line item case
        
        return transactions

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error processing file: {e!r}")
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
    from app.models.category import Category # Import here to avoid circular or early import

    saved_expenses = []
    # Pre-fetch user categories to minimize queries
    user_categories = db.query(Category).filter(
        (Category.user_id == current_user.id) | (Category.is_default == True)
    ).all()
    
    # Map name -> id (lowercase for fuzzy match)
    category_map = {c.name.lower(): c.id for c in user_categories}

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
            
            # Category linking
            category_id = None
            category_name = tx.get("category")
            if category_name:
                category_id = category_map.get(category_name.lower())
                # specific checks for "Uncategorized" or "Other" mapped to defaults if possible
                if not category_id and category_name.lower() in ["other", "uncategorized", "general"]:
                     category_id = category_map.get("other")

            # Determine Amount Sign based on Type
            # If explicit type is "credit" or "income", valid mapping would be negative amount (if Expense model) OR positive Income model
            # For MoneyGuard (Expense Tracker), we assume positive = Expense. 
            # If user explicitly says "credit", maybe we should skip or invert?
            # Current behavior: We store everything as Expense (positive). 
            # To support "Income", we would need an Income model or negative expenses.
            # Assuming User manually verifies in Step 2, we respect the absolute amount for now.
            
            expense = Expense(
                amount=abs(amount), 
                description=tx.get("description", "Imported Transaction"),
                date=date,
                source=ExpenseSource.IMPORT,
                ocr_raw_text=tx.get("ocr_raw_text"),
                ocr_confidence=tx.get("ocr_confidence"),
                user_id=current_user.id,
                category_id=category_id
            )
            db.add(expense)
            saved_expenses.append(expense)
        except Exception as e:
            print(f"Skipping invalid transaction: {tx}, error: {e}")
            continue
            
    db.commit()
    return [{"id": str(e.id), "description": e.description, "amount": e.amount} for e in saved_expenses]
