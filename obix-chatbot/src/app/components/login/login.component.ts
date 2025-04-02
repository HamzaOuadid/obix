import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormGroup, FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';
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
    
    // Check for logo image
    this.checkImageExists('./assets/logo.png');
  }
  
  private checkImageExists(path: string): void {
    this.http.get(path, { responseType: 'blob' })
      .subscribe({
        next: () => this.logoPath = path,
        error: () => this.logoPath = './assets/obix.png'
      });
  }
  
  ngOnInit(): void {
    if (this.authService.isLoggedIn()) {
      this.router.navigate(['/chat']);
    }
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