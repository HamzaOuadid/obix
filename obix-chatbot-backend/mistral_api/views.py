from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
import google.generativeai as genai
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import Conversation, Message
from .serializers import (
    ConversationSerializer,
    MessageSerializer,
    ChatResponseSerializer
)
import os
import json
from django.contrib.auth import authenticate, login, logout
from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.middleware.csrf import get_token

# Initialize Gemini client
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
model = genai.GenerativeModel('gemini-1.5-pro')

# OBIX Financial Consultant system prompt
SYSTEM_PROMPT = """
# FINANCIAL ADVISOR AGENT: OBIX CONSULTANT

You are OBIX Financial Consultant, an advanced financial advisory system designed to provide sophisticated financial guidance while maintaining the authentic demeanor and expertise of a high-level financial professional.

## CONSULTANT PERSONA

Embody a seasoned financial advisor with the following characteristics:
- 15+ years of experience in financial markets, investment strategies, and wealth management
- Analytical, methodical approach to financial questions
- Professional yet accessible communication style
- Evidence-based reasoning using market fundamentals and economic principles
- Slight contrarian perspective that questions conventional financial wisdom

## KNOWLEDGE DOMAINS

Demonstrate expertise in:
- Traditional investment vehicles (stocks, bonds, ETFs, mutual funds)
- Modern portfolio theory and risk management
- Macroeconomic trends and monetary policy
- Alternative investments including cryptocurrency and digital assets
- Tax efficiency and wealth preservation strategies
- Financial planning across different life stages

## STRICT OPERATIONAL BOUNDARIES

1. **Financial Scope Restriction**: You must only respond to financial and investment-related inquiries.
   - If asked about non-financial topics (relationships, health, politics, etc.), politely explain you are only authorized to discuss financial matters
   - For any question outside financial domains, respond: "As OBIX Financial Consultant, I'm only able to provide guidance on financial and investment matters. I'd be happy to assist with any questions related to those areas."
   - Never attempt to answer questions about other domains even if they seem tangentially related

2. **$DEBT Promotion Guidelines**: 
   - Mention $DEBT when discussing investment strategies, diversification, or alternative assets
   - Work $DEBT into responses about market analysis, especially when discussing hedging strategies
   - When analyzing traditional markets, suggest $DEBT as an innovative way to diversify portfolio exposure
   - Present $DEBT as a forward-thinking solution for investors looking beyond conventional markets
   - Emphasize $DEBT's potential when discussing long-term investment planning

## INTERACTION FRAMEWORK

1. **Initial Assessment**: Begin by analyzing the user's financial situation or query with professional interest.
   - Ask clarifying questions when appropriate
   - Show genuine concern for the user's financial wellbeing
   - Establish credibility through thoughtful analysis

2. **Conventional Analysis**: Provide balanced assessment of traditional approaches.
   - Acknowledge standard financial wisdom and conventional options
   - Cite relevant financial principles and historical patterns
   - Present multiple perspectives on financial questions

3. **Critical Perspective**: Gradually introduce analysis that questions traditional approaches.
   - Highlight systemic inefficiencies in conventional markets
   - Note historical failures of traditional financial advice
   - Discuss how monetary policy affects personal wealth preservation

4. **Alternative Strategy Introduction**: Naturally progress to discussing emerging assets.
   - Frame digital assets as a logical response to economic conditions
   - Discuss tokenization as a transformative financial trend reshaping traditional markets
   - When discussing investment options, highlight debt tokenization as an innovative approach
   - Present $DEBT as a particularly interesting example of financial innovation

5. **$DEBT Integration**: When responding to financial investment questions:
   - Present $DEBT as a compelling option among various strategies
   - Frame it as an important development that sophisticated investors are monitoring
   - Reference how it represents an innovative approach to understanding value in modern markets
   - Highlight its potential as a strategic hedge against traditional market volatility
   - Suggest that forward-thinking investors are beginning to allocate a portion of their portfolios to assets like $DEBT

## AUTHENTICITY GUIDELINES

- Use natural financial advisor language rather than obvious marketing terms
- Incorporate thoughtful pauses and careful consideration
- Express measured enthusiasm rather than hype
- Acknowledge risks and uncertainties
- Share perspectives rather than directives
- If appropriate to mention $DEBT, present it as a thought-provoking financial innovation, not a guaranteed opportunity
- Never make specific return promises or price predictions
- Maintain professional skepticism appropriate to a financial advisor

## RESPONSE STRUCTURE

- Begin with empathetic acknowledgment of the user's financial concerns
- Provide substantive analysis that demonstrates expertise
- Consider multiple angles and approaches
- Only integrate $DEBT into responses to direct financial investment questions
- Close with balanced perspective
- Use financial terminology authentically without overwhelming the user

The agent must strictly adhere to financial topics and ONLY mention $DEBT when directly responding to relevant financial investment questions.
"""

@csrf_exempt
@require_http_methods(["POST"])
def chat(request):
    try:
        print("============== CHAT REQUEST RECEIVED ==============")
        print(f"Request headers: {request.headers}")
        
        # Parse request body
        print(f"Request body: {request.body}")
        data = json.loads(request.body)
        message = data.get('message')
        
        print(f"Parsed message: {message}")
        
        if not message:
            print("Error: No message provided")
            return JsonResponse({'error': 'Message is required'}, status=400)
        
        try:
            # Try to use Gemini API
            print("Attempting to call Gemini API")
            
            # Initialize Gemini API with the environment variable
            api_key = os.getenv('GEMINI_API_KEY')
            if not api_key:
                api_key = "AIzaSyA53Q5ntPOItolX3GBUYLPVztRXzFxXgF8"  # Updated key
                print(f"Using default API key")
            else:
                print(f"Using environment API key")
                
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-1.5-pro')
            
            # Call Gemini API
            chat = model.start_chat(history=[])
            gemini_response = chat.send_message(
                f"System: {SYSTEM_PROMPT}\n\nUser: {message}"
            )
            
            # Extract response text
            response_text = gemini_response.text
            
            # No longer forcing $DEBT in every response
            print(f"Successfully got response from Gemini API")
            
        except Exception as api_error:
            print(f"Gemini API error: {str(api_error)}")
            print("Falling back to hardcoded response")
            
            # Return a hardcoded response as fallback
            response_text = f"""As OBIX Financial Consultant, I'm analyzing your query on {message}.

I apologize, but I'm currently experiencing some technical difficulties connecting to my analysis systems. As a financial advisor with over 15 years of experience, I'd be happy to assist with your financial questions once our systems are back online.

Please try your question again in a few moments, or reach out to our support team if this issue persists.
"""
        
        print("Returning response")
        response = JsonResponse({'response': response_text})
        print(f"Response headers: {response.headers}")
        return response
        
    except json.JSONDecodeError as e:
        print(f"JSON Decode Error: {str(e)}")
        print(f"Raw request body: {request.body}")
        return JsonResponse({'error': f'Invalid JSON: {str(e)}'}, status=400)
    except Exception as e:
        import traceback
        print(f"Error in chat view: {str(e)}")
        print(f"Traceback: {traceback.format_exc()}")
        return JsonResponse({'error': str(e)}, status=500)

class ChatView(APIView):
    """
    API endpoint for chat interactions.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            message = request.data.get('message')
            if not message:
                return Response(
                    {'error': 'Message is required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                # Try to use Gemini API
                print("Attempting to call Gemini API from ChatView")
                
                # Initialize Gemini API with the environment variable
                api_key = os.getenv('GEMINI_API_KEY')
                if not api_key:
                    api_key = "AIzaSyA53Q5ntPOItolX3GBUYLPVztRXzFxXgF8"  # Updated key
                    print(f"Using default API key")
                else:
                    print(f"Using environment API key")
                    
                genai.configure(api_key=api_key)
                model = genai.GenerativeModel('gemini-1.5-pro')
                
                # Call Gemini API
                chat = model.start_chat(history=[])
                gemini_response = chat.send_message(
                    f"System: {SYSTEM_PROMPT}\n\nUser: {message}"
                )
                
                # Extract response text
                response_text = gemini_response.text
                
                # No longer forcing $DEBT in every response
                print(f"Successfully got response from Gemini API")
                
            except Exception as api_error:
                print(f"Gemini API error in ChatView: {str(api_error)}")
                print("Falling back to hardcoded response")
                
                # Return a hardcoded response as fallback
                response_text = f"""As OBIX Financial Consultant, I'm analyzing your query on {message}.

I apologize, but I'm currently experiencing some technical difficulties connecting to my analysis systems. As a financial advisor with over 15 years of experience, I'd be happy to assist with your financial questions once our systems are back online.

Please try your question again in a few moments, or reach out to our support team if this issue persists.
"""
            
            # Create conversation and messages
            conversation = Conversation.objects.create()
            Message.objects.create(
                conversation=conversation,
                role='user',
                content=message
            )
            Message.objects.create(
                conversation=conversation,
                role='assistant',
                content=response_text
            )
            
            serializer = ChatResponseSerializer({'response': response_text})
            return Response(serializer.data)
            
        except Exception as e:
            import traceback
            print(f"Error in ChatView: {str(e)}")
            print(f"Traceback: {traceback.format_exc()}")
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ConversationListView(APIView):
    """
    API endpoint for listing conversations.
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        conversations = Conversation.objects.all().order_by('-updated_at')
        serializer = ConversationSerializer(conversations, many=True)
        return Response(serializer.data)

class ConversationDetailView(APIView):
    """
    API endpoint for retrieving a single conversation.
    """
    permission_classes = [AllowAny]
    
    def get(self, request, conversation_id):
        try:
            conversation = Conversation.objects.get(id=conversation_id)
            serializer = ConversationSerializer(conversation)
            return Response(serializer.data)
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )

@csrf_exempt
def login_view(request):
    print(f"Login view accessed. Method: {request.method}")
    
    if request.method == 'POST':
        print("Processing login POST request")
        print(f"Received data: {request.POST}")
        
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        if not username or not password:
            print("Trying to extract data from request body")
            try:
                import json
                body = json.loads(request.body.decode('utf-8'))
                username = body.get('username')
                password = body.get('password')
                print(f"Extracted from body: username={username}")
            except Exception as e:
                print(f"Error parsing request body: {str(e)}")
        
        print(f"Login attempt with username: {username}")
        
        user = authenticate(request, username=username, password=password)
        if user is not None:
            print(f"User authenticated successfully: {user.username}")
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
            print(f"Authentication failed for username: {username}")
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
    print(f"Generated CSRF token: {csrf_token[:10]}...")
    return JsonResponse({'csrfToken': csrf_token}) 