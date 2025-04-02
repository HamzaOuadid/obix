import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormGroup, FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService, User } from '../../services/auth.service';
import { HttpClient, HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, HttpClientModule, RouterModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  errorMessage: string = '';
  isLoading: boolean = false;
  logoPath = './assets/logo.png';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private http: HttpClient
  ) {
    this.loginForm = this.fb.group({
      username: ['', [Validators.required]],
      password: ['', [Validators.required]]
    });
    
    console.log('Login component constructed');
    
    // Try multiple image paths to find one that works
    this.checkImageExists('./assets/logo.png');
    this.checkImageExists('/assets/logo.png');
    this.checkImageExists('assets/logo.png');
    this.checkImageExists('assets/obix.png');
    this.checkImageExists('/assets/obix.png');
  }
  
  // Debug function to check if image exists
  checkImageExists(path: string): void {
    this.http.get(path, { responseType: 'blob' })
      .subscribe({
        next: () => {
          console.log(`Image exists at path: ${path}`);
          this.logoPath = path; // Use the first working path
        },
        error: (err) => console.error(`Failed to load image at ${path}:`, err)
      });
  }
  
  ngOnInit(): void {
    // Check if user is already logged in
    if (this.authService.isLoggedIn()) {
      console.log('User is already logged in, redirecting to chat');
      this.router.navigate(['/chat']);
    } else {
      console.log('No active session found, showing login page');
      
      // Prefill with demo credentials for POC
      this.loginForm.patchValue({
        username: 'demo',
        password: 'password'
      });
      
      // Optional: Auto-login for POC
      // this.autoLogin();
    }
  }
  
  // Automatically log in with hard-coded credentials
  autoLogin(): void {
    this.onSubmit();
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading = true;
      this.errorMessage = '';
      
      const { username, password } = this.loginForm.value;
      
      this.authService.login(username, password).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.router.navigate(['/chat']);
        },
        error: (error) => {
          this.isLoading = false;
          this.errorMessage = error.error?.message || 'Login failed. Please try again.';
        }
      });
    }
  }
} 