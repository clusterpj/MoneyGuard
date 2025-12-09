
import asyncio
import sys
import os
from unittest.mock import MagicMock, AsyncMock

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app.services.document_agent import DocumentAgentService

async def test_document_agent():
    print("Initializing DocumentAgentService...")
    agent = DocumentAgentService()
    
    # Mock LLM Client
    mock_llm = AsyncMock()
    agent.llm_client = mock_llm


    # Mock _extract_content to bypass PDF parsing
    original_extract = agent._extract_content
    agent._extract_content = AsyncMock(return_value={"text": "Derived content", "image_b64": None})

    # Test Case 1: Bank Statement
    print("\n--- Test Case 1: Bank Statement ---")
    mock_llm.analyze_document.side_effect = [
        {"document_type": "bank_statement", "confidence": 0.95}, # Classification
        { # Extraction
            "bank_name": "Mock Bank",
            "account_holder": "John Doe",
            "transactions": [
                {"date": "2023-10-27", "description": "Grocery Store", "amount": -45.50},
                {"date": "2023-10-28", "description": "Salary", "amount": 2500.00}
            ],
            "metadata": {}
        }
    ]
    
    result = await agent.process_document(b"fake pdf content", "statement.pdf", "application/pdf")
    
    # Restore or keep mocked for next test? Keep mocked but change return if needed.
    
    print(f"Document Type: {result['document_type']}")
    if 'structured_content' in result:
        print(f"Structured Content: {result['structured_content']}")
    else:
        print(f"Error: {result.get('error')}")
    
    # validation
    assert result["document_type"] == "bank_statement"
    assert result["structured_content"]["bank_name"] == "Mock Bank"
    assert len(result["structured_content"]["transactions"]) == 2
    assert "raw_text" in result["metadata"]
    print(f"Propagated Raw Text: {result['metadata']['raw_text']}")
    print("✅ Bank Statement Test Passed")

    # Test Case 2: Recipe
    print("\n--- Test Case 2: Recipe ---")
    # Reset mock for next call sequence
    mock_llm.analyze_document.side_effect = [
        {"document_type": "recipe", "confidence": 0.98},
        {
            "title": "Pancakes",
            "ingredients": [{"name": "Flour", "quantity": "1 cup"}],
            "instructions": [{"step": 1, "text": "Mix ingredients"}]
        }
    ]
    # For recipe (image), we might expect image_b64
    agent._extract_content = AsyncMock(return_value={"text": "", "image_b64": "fake_base64"})
    
    result = await agent.process_document(b"fake image content", "recipe.jpg", "image/jpeg")
    
    print(f"Document Type: {result['document_type']}")
    print(f"Recipe Title: {result['structured_content'].get('title')}")
    
    assert result["document_type"] == "recipe"
    assert result["structured_content"]["title"] == "Pancakes"
    print("✅ Recipe Test Passed")

    print("\n🎉 All Tests Passed!")

if __name__ == "__main__":
    asyncio.run(test_document_agent())
