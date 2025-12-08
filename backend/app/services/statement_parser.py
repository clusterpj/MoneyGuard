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
        Handles large files by chunking pages.
        """
        all_transactions = []
        try:
            pdf_file = io.BytesIO(file_content)
            pdf_reader = pypdf.PdfReader(pdf_file)
            
            # Process in chunks of pages to avoid token limits
            chunk_size = 2 # Process 2 pages at a time
            num_pages = len(pdf_reader.pages)
            
            tasks = []
            for i in range(0, num_pages, chunk_size):
                chunk_text = ""
                for j in range(i, min(i + chunk_size, num_pages)):
                    page = pdf_reader.pages[j]
                    chunk_text += page.extract_text() + "\n"
                
                if chunk_text.strip():
                    print(f"Queueing chunk {i//chunk_size + 1}...")
                    tasks.append(self.llm_client.parse_transactions(chunk_text))
            
            if tasks:
                print(f"Processing {len(tasks)} chunks in parallel...")
                import asyncio
                results = await asyncio.gather(*tasks)
                for tx_list in results:
                    all_transactions.extend(tx_list)
                    
        except Exception as e:
            print(f"Error reading PDF: {e}")
            raise ValueError("Invalid PDF file")

        return all_transactions

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
