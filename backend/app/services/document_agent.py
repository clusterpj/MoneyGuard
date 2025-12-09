
import base64
import json
from typing import Dict, Any, Optional, List
import pypdf
import io
from app.services.llm import DeepSeekClient
from app.services.ocr import OCRService

class DocumentAgentService:
    def __init__(self):
        self.llm_client = DeepSeekClient()
        self.ocr_service = OCRService()

    async def process_document(self, file_content: bytes, filename: str, mime_type: str) -> Dict[str, Any]:
        """
        Main entry point for document processing.
        1. Extract text/layout (OCR or PDF text).
        2. Classify document type.
        3. Extract structured data based on type.
        """
        # 1. Extraction
        extraction_result = await self._extract_content(file_content, mime_type)
        text_content = extraction_result.get("text", "")
        # For image-based docs, we might have an image_b64 for the LLM to see directly
        image_data = extraction_result.get("image_b64")

        if not text_content and not image_data:
            return {
                "document_type": "unknown",
                "error": "Could not extract content from file."
            }

        # 2. Classification
        classification = await self._classify_document(text_content, image_data)
        doc_type = classification.get("document_type", "generic_document")

        # 3. Structured Extraction
        if doc_type == "bank_statement":
            structured_data = await self._extract_bank_statement(text_content, image_data)
        elif doc_type == "credit_card_statement":
            structured_data = await self._extract_credit_card_statement(text_content, image_data)
        elif doc_type == "invoice" or doc_type == "receipt":
            structured_data = await self._extract_invoice_receipt(text_content, image_data, doc_type)
        elif doc_type == "recipe":
            structured_data = await self._extract_recipe(text_content, image_data)
        else:
            structured_data = await self._extract_generic(text_content, image_data)

        # 4. Construct Final Output
        return {
            "document_type": doc_type,
            "metadata": {
                "filename": filename,
                "mime_type": mime_type,
                "page_count": extraction_result.get("page_count", 1),
                "raw_text": text_content # Include extracted text for storage
            },
            "structured_content": structured_data,
            "quality": {
                "confidence_overall": classification.get("confidence", 0.0), # Placeholder
                "issues": [],
                "comments": "Processed by MoneyGuard Document Agent"
            }
        }

    async def _extract_content(self, file_content: bytes, mime_type: str) -> Dict[str, Any]:
        """
        Extracts raw text and/or prepares image data.
        """
        result = {"text": "", "image_b64": None, "page_count": 1}

        if mime_type == "application/pdf":
            try:
                # Try simple text extraction first
                pdf_file = io.BytesIO(file_content)
                pdf_reader = pypdf.PdfReader(pdf_file)
                result["page_count"] = len(pdf_reader.pages)
                text = ""
                for page in pdf_reader.pages:
                    text += page.extract_text() + "\n"
                
                result["text"] = text.strip()
                
                # If text is sparse, it might be a scanned PDF. 
                # (Future improvement: Convert PDF page to image for OCR if text is empty)
                if len(result["text"]) < 50: 
                     # Placeholder: Handle scanned PDFs by converting to image (requires poppler/pdf2image)
                     # For now, we assume text-based or rely on what we got.
                     pass

            except Exception as e:
                print(f"PDF extraction error: {e}")
        
        elif mime_type.startswith("image/"):
            # Encode for Vision API
            result["image_b64"] = base64.b64encode(file_content).decode('utf-8')
            # Also get OCR text from our OCR service as a backup/context
            # Note: The OCRService.process_image is tailored for receipts, 
            # but we can use implicit knowledge that DeepSeek Vision handles the image directly 
            # in the LLM calls if we pass the image_url. 
            pass
        
        return result

    async def _classify_document(self, text: str, image_data: Optional[str]) -> Dict[str, Any]:
        prompt = """
        Analyze this document and classify it into one of the following types:
        - "bank_statement"
        - "credit_card_statement"
        - "invoice"
        - "receipt"
        - "recipe"
        - "generic_document"
        
        Return JSON: {"document_type": "...", "confidence": 0.0-1.0}
        """
        if text:
            prompt += f"\n\nDocument Text Preview:\n{text[:2000]}"
            
        return await self.llm_client.analyze_document(prompt, image_data)

    async def _extract_bank_statement(self, text: str, image_data: Optional[str]) -> Dict[str, Any]:
        prompt = """
        Extract structure for BANK STATEMENT.
        Return JSON matching this schema:
        {
          "bank_name": string | null,
          "account_holder": string | null,
          "account_number": string | null,
          "period_start": "YYYY-MM-DD" | null,
          "period_end": "YYYY-MM-DD" | null,
          "opening_balance": number | null,
          "closing_balance": number | null,
          "transactions": [
            {
              "date": "YYYY-MM-DD",
              "description": string,
              "amount": number,
              "type": "debit" | "credit" | "other"
            }
          ]
        }
        """
        if text:
            prompt += f"\n\nDocument Text:\n{text}"
            
        return await self.llm_client.analyze_document(prompt, image_data)

    async def _extract_credit_card_statement(self, text: str, image_data: Optional[str]) -> Dict[str, Any]:
         # Similar to bank statement but with credit fields
        prompt = """
        Extract structure for CREDIT CARD STATEMENT.
        Return JSON matching this schema:
        {
          "institution_name": string | null,
          "account_holder": string | null,
          "credit_limit": number | null,
          "payment_due_date": "YYYY-MM-DD" | null,
          "minimum_payment": number | null,
          "transactions": [
             {
              "date": "YYYY-MM-DD",
              "description": string,
              "amount": number
            }
          ]
        }
        """
        if text:
             prompt += f"\n\nDocument Text:\n{text}"
        return await self.llm_client.analyze_document(prompt, image_data)

    async def _extract_invoice_receipt(self, text: str, image_data: Optional[str], type_name: str) -> Dict[str, Any]:
        prompt = f"""
        Extract structure for {type_name.upper()}.
        Return JSON matching this schema:
        {{
          "vendor_name": string | null,
          "date": "YYYY-MM-DD" | null,
          "total_amount": number | null,
          "tax_amount": number | null,
          "line_items": [
            {{
              "description": string,
              "quantity": number,
              "unit_price": number,
              "total": number
            }}
          ]
        }}
        """
        if text:
             prompt += f"\n\nDocument Text:\n{text}"
        return await self.llm_client.analyze_document(prompt, image_data)
        
    async def _extract_recipe(self, text: str, image_data: Optional[str]) -> Dict[str, Any]:
        prompt = """
        Extract structure for RECIPE.
        Return JSON matching this schema:
        {
          "title": string | null,
          "ingredients": [{"name": string, "quantity": string, "unit": string | null}],
          "instructions": [{"step": number, "text": string}],
          "prep_time_minutes": number | null,
          "cook_time_minutes": number | null
        }
        """
        if text:
             prompt += f"\n\nDocument Text:\n{text}"
        return await self.llm_client.analyze_document(prompt, image_data)

    async def _extract_generic(self, text: str, image_data: Optional[str]) -> Dict[str, Any]:
        prompt = """
        Extract key information from this document.
        Return generic JSON with:
        {
            "summary": string,
            "key_entities": [string],
            "dates": [string],
            "monetary_amounts": [number]
        }
        """
        if text:
             prompt += f"\n\nDocument Text:\n{text}"
        return await self.llm_client.analyze_document(prompt, image_data)
