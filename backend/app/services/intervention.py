from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.budget import Budget
from app.services.llm import DeepSeekClient
from datetime import date

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

        # Calculate remaining budget (mock logic for now, ideally sum expenses)
        # In a real app, we'd query sum of expenses for this period
        # For MVP, let's assume we have a way to track spent amount or just use a simple check
        # Let's mock "spent_so_far" as 0 for now, or we need to query it.
        
        # Gate 1: Budget Threshold
        # If (spent + current_amount) > budget.amount
        # For MVP, let's just check if amount > 10% of total budget as a simple rule if we don't have full spending history yet
        # Or better, let's query the expenses.
        
        # TODO: Query actual spent amount
        spent_so_far = 0.0 
        
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
