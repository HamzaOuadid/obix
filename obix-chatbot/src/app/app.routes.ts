import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { ChatComponent } from './components/chat/chat.component';
import { TermsOfServiceComponent } from './components/terms-of-service/terms-of-service.component';
import { inject } from '@angular/core';
import { AuthService } from './services/auth.service';
import { Router } from '@angular/router';

// Auth guard function
const isAuthenticated = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isLoggedIn()) {
    console.log('Auth guard: User is authenticated');
    return true;
  } else {
    console.log('Auth guard: Redirecting to login');
    return router.parseUrl('/login');
  }
};

// Login guard to prevent accessing login when already authenticated
const isNotAuthenticated = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (!authService.isLoggedIn()) {
    console.log('Login guard: User is not authenticated');
    return true;
  } else {
    console.log('Login guard: Redirecting to chat');
    return router.parseUrl('/chat');
  }
};

export const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { 
    path: 'login', 
    component: LoginComponent,
    canActivate: [() => isNotAuthenticated()]
  },
  { 
    path: 'chat', 
    component: ChatComponent,
    canActivate: [() => isAuthenticated()]
  },
  {
    path: 'terms',
    component: TermsOfServiceComponent
  },
  { path: '**', redirectTo: '/login' } // Catch-all route
];
