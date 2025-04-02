class ContentSecurityPolicyMiddleware:
    """
    Middleware to add Content Security Policy headers to responses.
    This helps mitigate XSS attacks.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        
        # Add CSP header
        csp_directives = [
            "default-src 'self'",
            "img-src 'self' data:",
            "script-src 'self'",
            "style-src 'self' 'unsafe-inline'",  # Allow inline styles for simplicity
            "font-src 'self'",
            "frame-src 'none'",
            "object-src 'none'",
            "base-uri 'self'",
            "form-action 'self'",
        ]
        
        response['Content-Security-Policy'] = '; '.join(csp_directives)
        return response 