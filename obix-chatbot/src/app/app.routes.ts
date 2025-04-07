import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { ChatComponent } from './components/chat/chat.component';
import { TermsOfServiceComponent } from './components/terms-of-service/terms-of-service.component';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { 
    path: 'login', 
    component: LoginComponent // No guard applied
  },
  { 
    path: 'chat', 
    component: ChatComponent // No guard applied
  },
  {
    path: 'terms',
    component: TermsOfServiceComponent
  },
  { path: '**', redirectTo: 'login' } // Catch-all route
];
