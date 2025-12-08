from datetime import datetime, timedelta
import calendar
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from openai import OpenAI
import logging

from app.core.config import settings
from app.models.expense import Expense
from app.models.budget import Budget
from app.models.category import Category

class AiService:
    def __init__(self):
        self.client = OpenAI(
            api_key=settings.DEEPSEEK_API_KEY,
            base_url=settings.DEEPSEEK_BASE_URL
        )
        self.logger = logging.getLogger(__name__)

    def get_financial_advice(self, db: Session, user_id: Any, message: str) -> str:
        """
        Generates financial advice based on the user's data and query.
        """
        try:
            # 1. Gather Context
            context_data = self._gather_context(db, user_id)
            
            # 2. Build Prompt
            system_prompt = self._construct_prompt(context_data)
            
            # 3. Call LLM
            response = self.client.chat.completions.create(
                model=settings.DEEPSEEK_MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": message}
                ],
                max_tokens=1000,
                temperature=0.7
            )
            
            return response.choices[0].message.content or "I couldn't generate a response."
            
        except Exception as e:
            self.logger.error(f"Error in AiService: {str(e)}")
            return f"I apologize, but I'm having trouble accessing my financial brain right now. Error: {str(e)}"

    def _gather_context(self, db: Session, user_id: Any) -> Dict[str, Any]:
        """
        Aggregates financial data for the user.
        """
        now = datetime.now()
        # Start of current month
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        
        # 1. Budget Info
        current_budget = db.query(Budget).filter(
            Budget.user_id == user_id,
            Budget.start_date <= now,
            Budget.end_date >= now
        ).first()
        
        # 2. Expenses this month
        expenses = db.query(Expense).filter(
            Expense.user_id == user_id,
            Expense.date >= start_of_month
        ).all()
        
        total_spent = sum(e.amount for e in expenses)
        
        # 3. Calculate Burn Rate (daily average)
        days_passed = max(1, now.day)
        daily_average = total_spent / days_passed
        
        # 4. Projected Spend
        days_in_month = calendar.monthrange(now.year, now.month)[1]
        days_remaining = days_in_month - now.day
        projected_spend = total_spent + (daily_average * days_remaining)
        
        # 5. Anomalies (High value transactions)
        # Threshold: Max of $100 or 2x the average transaction size
        avg_transaction = (total_spent / len(expenses)) if expenses else 0
        anomaly_threshold = max(100.0, avg_transaction * 2)
        
        anomalies = []
        for e in expenses:
            if e.amount > anomaly_threshold:
                anomalies.append(f"{e.description or 'Unknown'}: ${e.amount:.2f}")
        
        return {
            "current_date": now.strftime("%Y-%m-%d"),
            "total_spent_month": total_spent,
            "budget_limit": current_budget.amount if current_budget else 0,
            "budget_name": current_budget.name if current_budget else "Monthly",
            "budget_remaining": (current_budget.amount - total_spent) if current_budget else 0,
            "daily_average": daily_average,
            "projected_spend": projected_spend,
            "days_remaining": days_remaining,
            "recent_anomalies": anomalies[:5], # top 5
            "currency": "$", 
            "expense_count": len(expenses)
        }

    def _construct_prompt(self, data: Dict[str, Any]) -> str:
        """
        Builds the system prompt for the LLM.
        """
        budget_status = "No active budget found."
        budget_health = "Neutral"
        
        if data["budget_limit"] > 0:
            pct_used = (data["total_spent_month"] / data["budget_limit"]) * 100
            remaining_str = f"${data['budget_remaining']:.2f}"
            
            if data["projected_spend"] > data["budget_limit"]:
                budget_health = "CRITICAL: On track to overspend"
            elif pct_used > 80:
                budget_health = "WARNING: Approaching limit"
            else:
                budget_health = "GOOD: On track"

            budget_status = (
                f"Budget: ${data['budget_limit']:.2f} ({data['budget_name']})\n"
                f"- Spent so far: ${data['total_spent_month']:.2f} ({pct_used:.1f}%)\n"
                f"- Remaining: {remaining_str}\n"
                f"- Projected Total Info: ${data['projected_spend']:.2f} (Status: {budget_health})"
            )
        else:
            budget_status = f"Total Spent this Month: ${data['total_spent_month']:.2f}"

        anomalies_text = "None detected."
        if data["recent_anomalies"]:
            anomalies_text = ", ".join(data["recent_anomalies"])
            
        return (
            f"You are MoneyGuard, an intelligent, proactive, and strictly helpful financial advisor. "
            f"You have access to the user's real-time financial data.\n\n"
            f"### CURRENT FINANCIAL CONTEXT ({data['current_date']})\n"
            f"{budget_status}\n\n"
            f"### SPENDING HABITS\n"
            f"- Daily Burn Rate: ${data['daily_average']:.2f}/day\n"
            f"- Days Remaining in Month: {data['days_remaining']}\n"
            f"- High Value Transactions (Anomalies): {anomalies_text}\n\n"
            f"### YOUR MISSION\n"
            f"1. **Analyze**: Look for patterns. If they are overspending, tell them WHY (e.g., 'Your daily average of ${data['daily_average']:.0f} is too high').\n"
            f"2. **Forecast**: Use the projected spend to warn them.\n"
            f"3. **Simulate**: If the user asks 'Can I buy this?', use the 'Remaining' budget to give a definitive Yes/No/Careful.\n"
            f"4. **Format**: Use Markdown. Use **bold** for numbers. Use lists for steps.\n"
            f"5. **Persona**: Be encouraging but firm. Like a personal trainer for money.\n"
            f"6. **Keep it short**: Mobile friendly responses."
        )

ai_service = AiService()
