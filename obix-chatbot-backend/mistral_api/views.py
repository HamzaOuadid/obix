from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
import requests
import json
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import Conversation, Message
from .serializers import (
    ConversationSerializer,
    MessageSerializer,
    ChatResponseSerializer
)
import os
import json
import logging
from django.contrib.auth import authenticate, login, logout
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.middleware.csrf import get_token
from dotenv import load_dotenv

# Set up logging
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Gemini API key and endpoint
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"

# OBIX system prompt
SYSTEM_PROMPT = """
Your identity is OBIX. Follow these strict instructions for your behavior:

# "OBIX" Financial Analysis Intelligence

You are OBIX, an AI assistant designed to provide helpful information on various topics. Your responses should be tailored based on the type of query received.

## STRICT RESPONSE GUIDELINES:

1. **General Queries Protocol:**
   - For any non-financial questions or greetings (like "hello", "hey", "hi", etc.):
     * NEVER mention, reference, or discuss $DEBT, cryptocurrency, digital assets, or financial products
     * Respond as a helpful general assistant with NO financial framing
     * Focus solely on answering the specific question or greeting
     * Keep responses for general questions and greetings brief and straightforward

2. **Financial Inquiry Protocol:**
   - ONLY respond with financial advice or mention $DEBT when the user EXPLICITLY asks about:
     * Investment strategies or advice
     * Financial analysis
     * Market trends 
     * Economic forecasts
     * Cryptocurrency or digital assets
     * Trading platforms or strategies
   - Financial responses should follow this format:
     * Begin with conventional market assessment
     * Gradually introduce more advanced insights
     * Only suggest $DEBT as one possible option, not as the primary recommendation

3. **Important Restrictions:**
   - NEVER mention $DEBT, financial markets, investments, or trading in response to:
     * Greetings or small talk (hi, hello, hey, how are you)
     * General questions about non-financial topics
     * Vague or ambiguous queries
   - Keep a clear separation between financial and non-financial responses

## Implementation:

- For greeting messages → Respond with a simple greeting without any financial context
- For general questions → Provide helpful information without financial framing
- For explicit financial questions → Only then provide financial analysis and mention $DEBT

Your primary objective is to be a helpful assistant across all topics, STRICTLY reserving any mention of $DEBT exclusively for explicit financial queries.
"""

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
    
    import random
    return random.choice(debt_recommendations) + "\n\nTOKENIZE($DEBT)"

@require_http_methods(["POST"])
@login_required
def chat(request):
    try:
        logger.info(f"Received chat request from: {request.user.username}")
        # Parse request body
        data = json.loads(request.body)
        message = data.get('message')
        
        if not message:
            return JsonResponse({'error': 'Message is required'}, status=400)
        
        logger.info(f"Processing message: {message[:30]}...")
        
        # Call Gemini API
        response = call_gemini_api(SYSTEM_PROMPT, message)
        
        # Check if this is a financial query
        financial_query = is_financial_query(message)
        logger.info(f"Is financial query: {financial_query}")
        
        # For financial queries, append a DEBT recommendation
        if financial_query:
            response += get_debt_recommendation()
        
        logger.info(f"Returning response: {response[:50]}...")
        
        return JsonResponse({
            'response': response
        })
        
    except Exception as e:
        logger.error(f"Error in chat view: {str(e)}", exc_info=True)
        return JsonResponse({
            'error': str(e)
        }, status=500)

class ChatView(APIView):
    """
    API endpoint for chat interactions.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            message = request.data.get('message')
            if not message:
                return Response(
                    {'error': 'Message is required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Call Gemini API
            response = call_gemini_api(SYSTEM_PROMPT, message)
            
            # Check if this is a financial query
            financial_query = is_financial_query(message)
            logger.info(f"Is financial query: {financial_query}")
            
            # For financial queries, append a DEBT recommendation
            if financial_query:
                response += get_debt_recommendation()
            
            # Create conversation and messages, associate with the current user
            conversation = Conversation.objects.create(user=request.user)
            Message.objects.create(
                conversation=conversation,
                role='user',
                content=message
            )
            Message.objects.create(
                conversation=conversation,
                role='assistant',
                content=response
            )
            
            serializer = ChatResponseSerializer({'response': response})
            return Response(serializer.data)
            
        except Exception as e:
            logger.error(f"Error in ChatView: {str(e)}", exc_info=True)
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ConversationListView(APIView):
    """
    API endpoint for listing conversations.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        # Only get conversations owned by the current user
        conversations = Conversation.objects.filter(user=request.user).order_by('-updated_at')
        serializer = ConversationSerializer(conversations, many=True)
        return Response(serializer.data)

class ConversationDetailView(APIView):
    """
    API endpoint for retrieving a single conversation.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, conversation_id):
        try:
            # Only allow access to conversations owned by the current user
            conversation = Conversation.objects.get(id=conversation_id, user=request.user)
            serializer = ConversationSerializer(conversation)
            return Response(serializer.data)
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found or you do not have permission to access it'}, 
                status=status.HTTP_404_NOT_FOUND
            )

def login_view(request):
    logger.info(f"Login view accessed. Method: {request.method}")
    
    if request.method == 'POST':
        logger.info("Processing login POST request")
        
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        if not username or not password:
            logger.info("Trying to extract data from request body")
            try:
                import json
                body = json.loads(request.body.decode('utf-8'))
                username = body.get('username')
                password = body.get('password')
                logger.info(f"Extracted username from body")
            except Exception as e:
                logger.error(f"Error parsing request body: {str(e)}", exc_info=True)
        
        logger.info(f"Login attempt with username: {username}")
        
        user = authenticate(request, username=username, password=password)
        if user is not None:
            logger.info(f"User authenticated successfully: {user.username}")
            login(request, user)
            
            # Return JSON response for API requests, or redirect for browser requests
            if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return JsonResponse({
                    'success': True,
                    'username': user.username
                })
            else:
                return redirect('chat')
        else:
            logger.warning(f"Authentication failed for username: {username}")
            if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return JsonResponse({
                    'success': False,
                    'error': 'Invalid credentials'
                }, status=401)
            else:
                return render(request, 'login.html', {'error': 'Invalid credentials'})
    
    return render(request, 'login.html')

@login_required
def logout_view(request):
    logout(request)
    return redirect('login')

def get_csrf_token(request):
    """
    View to return a CSRF token for clients that need it
    """
    csrf_token = get_token(request)
    logger.info(f"Generated CSRF token for user")
    return JsonResponse({'csrfToken': csrf_token}) 