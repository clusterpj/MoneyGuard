import io
import csv
from typing import List, Dict, Any
import pypdf
from app.services.llm import DeepSeekClient

class StatementParserService:
    def __init__(self):
        self.llm_client = DeepSeekClient()

    async def parse_pdf(self, file_content: bytes) -> List[Dict[str, Any]]:
        """
        Extract text from PDF and use LLM to parse transactions.
        """
        text = ""
        try:
            pdf_file = io.BytesIO(file_content)
            pdf_reader = pypdf.PdfReader(pdf_file)
            for page in pdf_reader.pages:
                text += page.extract_text() + "\n"
        except Exception as e:
            print(f"Error reading PDF: {e}")
            raise ValueError("Invalid PDF file")

        return await self.llm_client.parse_transactions(text)

    async def parse_csv(self, file_content: bytes) -> List[Dict[str, Any]]:
        """
        Parse CSV file. Tries to identify columns heuristically or via LLM if complex.
        For now, let's convert CSV to text and let LLM handle it for consistency,
        or we could map columns manually.
        Given the requirement for "smart parsing", sending a snippet to LLM is safer.
        """
        try:
            # Decode bytes to string
            content_str = file_content.decode('utf-8')
            # We can just pass the raw CSV text to the LLM as well
            return await self.llm_client.parse_transactions(content_str)
        except Exception as e:
             print(f"Error reading CSV: {e}")
             raise ValueError("Invalid CSV file")

statement_parser = StatementParserService()
