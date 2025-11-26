from typing import Dict, Any, Optional
import random
from datetime import datetime

class OCRService:
    def __init__(self):
        pass

    async def process_image(self, file_content: bytes) -> Dict[str, Any]:
        """
        Mock OCR processing of an image.
        In a real implementation, this would call an external OCR API (e.g., Google Cloud Vision).
        """
        # Simulate processing delay
        # await asyncio.sleep(1)
        
        # Mock extracted data
        return {
            "amount": round(random.uniform(10.0, 150.0), 2),
            "date": datetime.now().isoformat(),
            "description": "Grocery Store Purchase (Mock)",
            "ocr_raw_text": "MOCK RECEIPT\nTOTAL: $45.50\nDATE: 2023-10-27",
            "ocr_confidence": 0.95
        }

ocr_service = OCRService()
