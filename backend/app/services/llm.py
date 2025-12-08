import httpx
from typing import Optional, Dict, Any, List
from app.core.config import settings

class DeepSeekClient:
    def __init__(self):
        self.api_key = settings.DEEPSEEK_API_KEY
        self.base_url = settings.DEEPSEEK_BASE_URL
        self.model = settings.DEEPSEEK_MODEL

    async def get_intervention_advice(self, context: Dict[str, Any]) -> str:
        """
        Generate advice based on user context using DeepSeek LLM.
        """
        prompt = self._construct_prompt(context)
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": "You are MoneyGuard, a strict but helpful financial assistant. Your goal is to prevent overspending. Be concise, direct, and use the user's intervention mode (passive, balanced, aggressive) to tone your response."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 150
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(f"{self.base_url}/chat/completions", headers=headers, json=data, timeout=10.0)
                response.raise_for_status()
                result = response.json()
                return result["choices"][0]["message"]["content"].strip()
            except Exception as e:
                print(f"Error calling DeepSeek API: {e}")
                return "Warning: You are exceeding your budget. Please reconsider this purchase."

    def _construct_prompt(self, context: Dict[str, Any]) -> str:
        mode = context.get("intervention_mode", "balanced")
        amount = context.get("amount")
        category = context.get("category")
        budget_remaining = context.get("budget_remaining")
        safe_to_spend = context.get("safe_to_spend")
        
        return f"""
        User is attempting to spend {amount} on {category}.
        Intervention Mode: {mode}
        
        Financial Context:
        - Remaining Budget: {budget_remaining}
        - Safe to Spend Today: {safe_to_spend}
        
        The user is about to overspend or violate a rule. Provide a short, punchy intervention message to stop them or make them think twice.
        """
        
    async def parse_transactions(self, text: str) -> List[Dict[str, Any]]:
        """
        Parse unstructured text into a list of transactions.
        """
        prompt = f"""
        Extract financial transactions from the following text.
        Return ONLY a JSON array of objects with these fields:
        - date: ISO 8601 string (YYYY-MM-DD)
        - amount: float (positive for income, negative for expense)
        - description: string
        - category_guess: string (guess a category like 'Food', 'Transport', 'Utilities', 'Income', etc.)
        
        Text:
        {text} 
        """
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": "You are a financial data extraction assistant. Output valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.1, # Low temperature for deterministic output
            "max_tokens": 4000 # Increased for larger responses
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(f"{self.base_url}/chat/completions", headers=headers, json=data, timeout=60.0)
                response.raise_for_status()
                result = response.json()
                content = result["choices"][0]["message"]["content"].strip()
                
                # Clean up markdown code blocks if present
                if content.startswith("```json"):
                    content = content[7:]
                if content.endswith("```"):
                    content = content[:-3]
                
                import json
                return json.loads(content.strip())
            except Exception as e:
                print(f"Error parsing transactions with DeepSeek: {e}")
                return []

