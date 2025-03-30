import { Component, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
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
  
  constructor(private authService: AuthService, private titleService: Title) {}
  
  ngOnInit() {
    console.log('App initialized');
    const isLoggedIn = this.authService.isLoggedIn();
    console.log('User authentication status:', isLoggedIn ? 'Authenticated' : 'Not authenticated');
    this.titleService.setTitle(this.title);
  }
}
