import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { 
  provideHttpClient, 
  withInterceptors, 
  withXsrfConfiguration,
  HttpRequest,
  HttpHandlerFn
} from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';

import { routes } from './app.routes';

// Simplified approach - use a function to handle CSRF tokens without a separate class
const authInterceptor = (req: HttpRequest<unknown>, next: HttpHandlerFn) => {
  // Always add credentials to all requests
  const modifiedReq = req.clone({
    withCredentials: true
  });
  
  // Log the request for debugging purposes
  console.log(`${modifiedReq.method} request to ${modifiedReq.url}`);
  
  // For POST/PUT/DELETE requests, try to get the CSRF token from cookies
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method)) {
    const csrfToken = getCookie('csrftoken');
    if (csrfToken) {
      console.log('Found CSRF token, adding to request headers');
      return next(modifiedReq.clone({
        headers: modifiedReq.headers.set('X-CSRFToken', csrfToken)
      }));
    } else {
      console.log('No CSRF token found in cookies');
    }
  }
  
  return next(modifiedReq);
};

// Helper function to get cookies
function getCookie(name: string): string | null {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) {
    return parts.pop()?.split(';').shift() || null;
  }
  return null;
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(
      withXsrfConfiguration({
        cookieName: 'csrftoken',  // Django default CSRF cookie name
        headerName: 'X-CSRFToken'  // Django default CSRF header name
      }),
      withInterceptors([authInterceptor])
    ),
    provideAnimations()
  ]
};
