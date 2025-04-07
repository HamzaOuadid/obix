import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormGroup, FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HttpClient, HttpClientModule } from '@angular/common/http';

interface LoginCredentials {
  username: string;
  displayName: string;
  password: string;
}

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, HttpClientModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  errorMessage: string = '';
  isLoading: boolean = false;
  logoPath = './assets/logo.png';
  
  // Demo credentials - in a real app, this would be validated by a server
  private validCredentials: LoginCredentials[] = [
    { username: 'trader', displayName: 'Wall Street Trader', password: 'trader123' },
    { username: 'investor', displayName: 'Smart Investor', password: 'invest123' },
    { username: 'admin', displayName: 'OBIX Admin', password: 'admin123' },
    { username: 'demo', displayName: 'Demo User', password: 'demo123' }
  ];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private http: HttpClient
  ) {
    console.log('Login component initialized');
    this.loginForm = this.fb.group({
      username: ['', [Validators.required]],
      password: ['', [Validators.required]]
    });
    
    // Check for logo image
    this.checkImageExists('./assets/obix.svg');
  }
  
  private checkImageExists(path: string): void {
    this.http.get(path, { responseType: 'blob' })
      .subscribe({
        next: () => this.logoPath = path,
        error: () => this.logoPath = './assets/obix.png'
      });
  }
  
  ngOnInit(): void {
    console.log('Login component ngOnInit');
    // Check if user is already logged in
    const fakeAuthToken = localStorage.getItem('obixAuthToken');
    if (fakeAuthToken) {
      console.log('User is already logged in, redirecting to chat');
      // User is already logged in, redirect to chat
      window.location.href = './chat';
    }
  }

  onSubmit(): void {
    console.log('Login form submitted', this.loginForm.value);
    if (this.loginForm.valid) {
      const username = this.loginForm.get('username')?.value;
      const password = this.loginForm.get('password')?.value;
      
      console.log(`Attempting login with username: ${username}, password: ${password}`);
      
      // Show loading indicator
      this.isLoading = true;
      this.errorMessage = '';
      
      // Simulate API call with a timeout
      setTimeout(() => {
        // Log all valid credentials for debugging
        console.log('Valid credentials:', this.validCredentials.map(cred => ({ 
          username: cred.username, 
          password: cred.password 
        })));
        
        // Find if username exists
        const userExists = this.validCredentials.find(
          cred => cred.username.toLowerCase() === username.toLowerCase()
        );
        
        // Find exact match
        const matchedUser = this.validCredentials.find(
          cred => cred.username.toLowerCase() === username.toLowerCase() && 
                 cred.password === password
        );
        
        console.log('Matched user:', matchedUser);
        
        if (matchedUser) {
          console.log('Login successful for user:', matchedUser.displayName);
          // Generate a fake JWT token
          const fakeToken = this.generateFakeJWT(matchedUser.username);
          
          // Store auth data
          localStorage.setItem('obixAuthToken', fakeToken);
          localStorage.setItem('obixUsername', matchedUser.displayName);
          
          // Navigate to chat with full URL redirect
          console.log('Redirecting to chat page');
          window.location.href = './chat';
        } else {
          // Provide more specific error message
          if (userExists) {
            console.log('Login failed: Password incorrect');
            this.errorMessage = `Incorrect password. Did you mean to type "${userExists.password}"?`;
          } else {
            console.log('Login failed: Username not found');
            this.errorMessage = 'Invalid username or password';
          }
        }
        
        this.isLoading = false;
      }, 1200); // Simulate network delay
    } else {
      console.log('Form is invalid', this.loginForm.errors);
      this.errorMessage = 'Please fill in all required fields';
    }
  }
  
  // Generate a fake JWT token for demo purposes
  private generateFakeJWT(username: string): string {
    const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const payload = btoa(JSON.stringify({ 
      sub: username, 
      name: username,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + (60 * 60) // 1 hour expiry
    }));
    const signature = btoa('fake-signature-for-demo-only');
    
    return `${header}.${payload}.${signature}`;
  }

  // Direct login method that bypasses validation for debugging
  directLogin(): void {
    console.log('Direct login triggered');
    
    // Use the trader credentials for direct login
    const traderUser = this.validCredentials.find(cred => cred.username === 'trader');
    
    if (traderUser) {
      // Generate a token for trader
      const fakeToken = this.generateFakeJWT(traderUser.username);
      
      // Store auth data
      localStorage.setItem('obixAuthToken', fakeToken);
      localStorage.setItem('obixUsername', traderUser.displayName);
      
      // Navigate using direct URL
      console.log('Directly redirecting to chat page as', traderUser.displayName);
      window.location.href = './chat';
    } else {
      console.error('Trader credentials not found');
      this.errorMessage = 'Error with auto-login. Please use manual login.';
    }
  }
}
