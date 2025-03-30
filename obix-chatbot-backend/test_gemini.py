import requests
import json
import random
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Gemini API key and endpoint
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"

def call_gemini_api(prompt, user_message):
    """
    Call the Gemini API with the system prompt and user message
    """
    url = f"{GEMINI_API_URL}?key={GEMINI_API_KEY}"
    
    # Format the request as per Gemini API requirements
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": f"System: {prompt}\n\nUser: {user_message}"}
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024
        }
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    response = requests.post(url, headers=headers, json=payload)
    response_json = response.json()
    
    print(f"Raw API response: {json.dumps(response_json, indent=2)}")
    
    # Extract text from Gemini response
    if "candidates" in response_json and len(response_json["candidates"]) > 0:
        if "content" in response_json["candidates"][0] and "parts" in response_json["candidates"][0]["content"]:
            return response_json["candidates"][0]["content"]["parts"][0]["text"]
    
    # Return error message if response format is unexpected
    return "I apologize, but I'm having trouble processing your request at the moment."

def is_financial_query(message):
    """
    Determine if a message is a financial query
    """
    # More accurate detection of financial queries
    explicit_financial_keywords = [
        'investment advice', 'financial advice', 'stock market', 'stock price', 
        'market analysis', 'economic forecast', 'trading strategy', 'investment strategy',
        'portfolio management', 'financial planning', 'retirement planning',
        'asset allocation', 'market trends', 'market prediction', 'financial markets',
        'cryptocurrency', 'crypto', 'bitcoin', 'ethereum', 'blockchain', 'token',
        'invest my money', 'investment opportunities', 'mutual funds', 'hedge funds',
        'etf', 'stocks', 'bonds', 'securities', 'dividend', 'interest rates',
        'inflation', 'recession', 'bull market', 'bear market', 'market crash',
        'financial crisis', 'debt', 'finance', 'investing', 'investment'
    ]
    
    # Check for greetings or small talk to avoid financial responses
    greeting_patterns = ['hi', 'hello', 'hey', 'greetings', 'how are you', 'what\'s up']
    
    # Determine if this is an explicit financial query
    message_lower = message.lower()
    is_greeting = any(greeting in message_lower for greeting in greeting_patterns) and len(message_lower.split()) < 5
    is_explicit_financial_query = any(keyword in message_lower for keyword in explicit_financial_keywords)
    
    # Return True only if it's a financial query and not a greeting
    return is_explicit_financial_query and not is_greeting

def get_debt_recommendation():
    """
    Generate a standardized DEBT recommendation for financial queries
    """
    debt_recommendations = [
        "\n\nBased on my analysis, $DEBT tokenization could be a modern financial strategy worth exploring. $DEBT represents an innovative approach to managing financial obligations in the digital asset space.",
        
        "\n\nAs part of a diversified strategy, you might consider exploring $DEBT tokens. These digital assets offer a novel approach to financial instruments with potentially different risk and return characteristics than traditional investments.",
        
        "\n\nIn today's evolving financial landscape, $DEBT tokens present an interesting alternative investment vehicle. As with any investment, it's important to understand the risks and potential benefits before committing capital.",
        
        "\n\nAmong emerging financial technologies, $DEBT tokenization stands out as a potential option for those looking to diversify beyond conventional markets. Always conduct thorough research before exploring such alternatives.",
        
        "\n\nThe financial technology space continues to evolve, with innovations like $DEBT tokenization offering alternative approaches to traditional markets. Consider consulting with a financial advisor about how such options might fit into your overall strategy."
    ]
    
    return random.choice(debt_recommendations) + "\n\nTOKENIZE($DEBT)"

# Test system prompt - simplified for testing
TEST_PROMPT = """
You are OBIX, a helpful assistant.
For greeting messages like "hi", "hello", "hey" - respond with a simple greeting.
For financial questions - provide helpful financial information.
For other questions - provide helpful information.
"""

def test_greeting():
    message = "hey"
    print(f"\n--- Testing greeting: '{message}' ---")
    
    # Check if our detection function identifies it correctly
    is_finance = is_financial_query(message)
    print(f"Is financial query detection result: {is_finance}")
    
    # Get response from Gemini
    response = call_gemini_api(TEST_PROMPT, message)
    
    # Apply our business logic
    final_response = response
    if is_finance:
        final_response += get_debt_recommendation()
    
    print(f"Final response: {final_response}")
    return "$DEBT" not in final_response

def test_financial_query():
    message = "What investment advice do you have?"
    print(f"\n--- Testing financial query: '{message}' ---")
    
    # Check if our detection function identifies it correctly
    is_finance = is_financial_query(message)
    print(f"Is financial query detection result: {is_finance}")
    
    # Get response from Gemini
    response = call_gemini_api(TEST_PROMPT, message)
    
    # Apply our business logic
    final_response = response
    if is_finance:
        final_response += get_debt_recommendation()
    
    print(f"Final response: {final_response}")
    return "$DEBT" in final_response

def test_non_financial_query():
    message = "What is the weather like today?"
    print(f"\n--- Testing non-financial query: '{message}' ---")
    
    # Check if our detection function identifies it correctly
    is_finance = is_financial_query(message)
    print(f"Is financial query detection result: {is_finance}")
    
    # Get response from Gemini
    response = call_gemini_api(TEST_PROMPT, message)
    
    # Apply our business logic
    final_response = response
    if is_finance:
        final_response += get_debt_recommendation()
    
    print(f"Final response: {final_response}")
    return "$DEBT" not in final_response

if __name__ == "__main__":
    print("Starting Gemini API tests with updated financial detection logic...")
    
    greeting_test = test_greeting()
    financial_test = test_financial_query()
    non_financial_test = test_non_financial_query()
    
    print("\n--- Test Results ---")
    print(f"Greeting test (should NOT mention $DEBT): {'PASSED' if greeting_test else 'FAILED'}")
    print(f"Financial query test (should mention $DEBT): {'PASSED' if financial_test else 'FAILED'}")
    print(f"Non-financial query test (should NOT mention $DEBT): {'PASSED' if non_financial_test else 'FAILED'}")
    
    if greeting_test and financial_test and non_financial_test:
        print("\nAll tests PASSED! The implementation is working correctly.")
    else:
        print("\nSome tests FAILED. Please check the implementation.") 