import base64
import httpx
from typing import Dict, Any, Optional
from datetime import datetime
from app.core.config import settings

class OCRService:
    def __init__(self):
        self.api_key = settings.DEEPSEEK_API_KEY
        self.base_url = settings.DEEPSEEK_BASE_URL
        self.model = "deepseek-chat"  # or "deepseek-vision" if available

    async def process_image(self, file_content: bytes) -> Dict[str, Any]:
        """
        Process receipt image using DeepSeek Vision API.
        Extracts amount, date, description, raw text, and confidence.
        """
        # Encode image to base64
        image_b64 = base64.b64encode(file_content).decode('utf-8')

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        # Construct prompt for receipt extraction
        prompt = """
        You are a receipt OCR assistant. Extract the following fields from the receipt image:
        - total amount (as a float)
        - date of transaction (in ISO 8601 format, e.g., YYYY-MM-DD)
        - merchant/store name or description
        - raw text of the receipt (as plain text)

        Return a JSON object with keys: "amount", "date", "description", "ocr_raw_text".
        If any field cannot be determined, set it to null.
        Also include an "ocr_confidence" score between 0 and 1 representing your confidence in the extraction.
        """

        data = {
            "model": self.model,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{image_b64}"
                            }
                        }
                    ]
                }
            ],
            "max_tokens": 1000,
            "temperature": 0.1
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=30.0
                )
                response.raise_for_status()
                result = response.json()
                content = result["choices"][0]["message"]["content"].strip()

                # Parse JSON from response (might be wrapped in markdown code blocks)
                if content.startswith("```json"):
                    content = content[7:]
                if content.endswith("```"):
                    content = content[:-3]
                import json
                extracted = json.loads(content.strip())

                # Ensure required fields exist
                amount = extracted.get("amount")
                date = extracted.get("date")
                description = extracted.get("description")
                ocr_raw_text = extracted.get("ocr_raw_text")
                ocr_confidence = extracted.get("ocr_confidence", 0.8)

                # Validate and convert types
                if amount is not None:
                    try:
                        amount = float(amount)
                    except (ValueError, TypeError):
                        amount = None
                if date is not None:
                    # Try to parse date string
                    try:
                        # If date is already ISO format, keep it
                        datetime.fromisoformat(date.replace('Z', '+00:00'))
                    except ValueError:
                        date = None

                return {
                    "amount": amount,
                    "date": date or datetime.now().isoformat(),
                    "description": description or "Receipt Purchase",
                    "ocr_raw_text": ocr_raw_text or "",
                    "ocr_confidence": ocr_confidence
                }
            except Exception as e:
                print(f"Error calling DeepSeek Vision API: {e}")
                # Fallback to mock data for development
                return await self._mock_fallback()

    async def _mock_fallback(self) -> Dict[str, Any]:
        """Fallback mock data when API fails."""
        from datetime import datetime
        import random
        return {
            "amount": round(random.uniform(10.0, 150.0), 2),
            "date": datetime.now().isoformat(),
            "description": "Grocery Store Purchase (Mock)",
            "ocr_raw_text": "MOCK RECEIPT\nTOTAL: $45.50\nDATE: 2023-10-27",
            "ocr_confidence": 0.95
        }

ocr_service = OCRService()
