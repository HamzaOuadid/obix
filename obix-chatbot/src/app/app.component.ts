import { Component, OnInit } from '@angular/core';
import { RouterOutlet, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from './services/auth.service';
import { Title } from '@angular/platform-browser';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, CommonModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  title = 'OBIX Chat';
  
  constructor(
    private authService: AuthService, 
    private titleService: Title,
    private router: Router
  ) {}
  
  ngOnInit() {
    console.log('App initialized');
    this.titleService.setTitle(this.title);
    
    // For POC only - auto login with demo user
    const isLoggedIn = this.authService.isLoggedIn();
    console.log('User authentication status:', isLoggedIn ? 'Authenticated' : 'Not authenticated');
    
    // Uncomment the next line to enable automatic login
    // this.autoLoginForDemo();
  }
  
  // Auto-login functionality for demo
  private autoLoginForDemo(): void {
    if (!this.authService.isLoggedIn()) {
      console.log('Auto-logging in demo user');
      this.authService.login('demo', 'password').subscribe({
        next: (user) => {
          this.authService.loginSuccess(user);
          this.router.navigate(['/chat']);
        },
        error: (error) => {
          console.error('Auto-login error:', error);
        }
      });
    }
  }
}
