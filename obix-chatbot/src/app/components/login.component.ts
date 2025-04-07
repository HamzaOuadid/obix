import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormGroup, FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
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
    // No need to check for logged-in status
  }

  onSubmit(): void {
    // Directly navigate to the chat page without authentication
    this.router.navigate(['/chat']);
  }
}
