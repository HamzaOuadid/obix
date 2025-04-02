import { Component, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';
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
  
  constructor(private titleService: Title) {}

  ngOnInit() {
    console.log('App initialized');
    this.titleService.setTitle(this.title);
    // No authentication checks or auto-login logic
  }
}

