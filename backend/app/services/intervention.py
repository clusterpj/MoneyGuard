from typing import Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.user import User
from app.models.budget import Budget
from app.models.expense import Expense
from app.services.llm import DeepSeekClient
from datetime import date, datetime

class InterventionService:
    def __init__(self, db: Session):
        self.db = db
        self.llm_client = DeepSeekClient()

    async def check_intervention(self, user: User, amount: float, category_name: str) -> Dict[str, Any]:
        """
        Check if an intervention is needed based on 3-gate logic.
        """
        # 1. Get current budget
        today = date.today()
        budget = self.db.query(Budget).filter(
            Budget.user_id == user.id,
            Budget.start_date <= today,
            Budget.end_date >= today
        ).first()
        
        if not budget:
            # No budget, no intervention (or maybe warn about no budget?)
            return {"should_intervene": False, "message": None}

        # Query actual spent amount for this budget period
        query = self.db.query(func.sum(Expense.amount)).filter(
            Expense.user_id == user.id,
            Expense.date >= budget.start_date,
            Expense.date <= budget.end_date,
        )
        if budget.category_id is not None:
            query = query.filter(Expense.category_id == budget.category_id)
        
        spent_so_far = query.scalar() or 0.0
        
        remaining = budget.amount - spent_so_far
        
        should_intervene = False
        reasons = []
        
        # Rule 1: Overspending Budget
        if amount > remaining:
            should_intervene = True
            reasons.append("exceeds_remaining_budget")
            
        # Rule 2: Large Purchase (> 20% of budget)
        if amount > (budget.amount * 0.2):
            should_intervene = True
            reasons.append("large_purchase")
            
        if should_intervene:
            context = {
                "amount": amount,
                "category": category_name,
                "budget_remaining": remaining,
                "safe_to_spend": remaining / 30, # Mock daily safe spend
                "intervention_mode": user.intervention_mode.value
            }
            
            # Call LLM
            message = await self.llm_client.get_intervention_advice(context)
            
            return {
                "should_intervene": True,
                "message": message,
                "reasons": reasons
            }
            
        return {"should_intervene": False, "message": None}
