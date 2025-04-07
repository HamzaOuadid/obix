import { Component, OnInit, ViewChild, ElementRef, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormGroup, FormBuilder } from '@angular/forms';
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { AuthService } from '../../services/auth.service';
import { ChatService, Message } from '../../services/chat.service';

@Component({
  selector: 'app-simple-chat',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './simple-chat.component.html',
  styleUrls: ['./simple-chat.component.scss']
})
export class SimpleChatComponent implements OnInit, OnDestroy {
  @ViewChild('messagesContainer') messagesContainer!: ElementRef;
  
  messageInput = '';
  isLoading = false;
  username = '';
  messages: Message[] = [];
  
  private subscriptions: Subscription[] = [];

  constructor(
    private chatService: ChatService,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Check if user is logged in
    const user = this.authService.getCurrentUser();
    if (!user || !this.authService.isLoggedIn()) {
      console.log('User not logged in, redirecting to login page');
      this.router.navigate(['/login']);
      return;
    }
    
    console.log('User logged in:', user.username);
    this.username = user.username || user.email || 'User';
    
    // Subscribe to messages
    this.subscriptions.push(
      this.chatService.messages$.subscribe(messages => {
        this.messages = messages;
        this.scrollToBottom();
      })
    );
    
    // Clear messages on component init
    this.chatService.clearMessages();
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
  }

  sendMessage(): void {
    const message = this.messageInput.trim();
    if (!message || this.isLoading) return;
    
    this.isLoading = true;
    this.messageInput = '';
    
    // Send to API
    this.chatService.sendMessage(message).subscribe({
      next: () => {
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error sending message:', error);
        
        // Check if it's an authentication error
        if (error.status === 401 || error.status === 403) {
          console.log('Authentication error, redirecting to login');
          this.router.navigate(['/login']);
          return;
        }
        
        this.isLoading = false;
      }
    });
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => {
        console.log('Logged out successfully');
        this.router.navigate(['/login']);
      },
      error: () => {
        // Navigate to login anyway
        this.router.navigate(['/login']);
      }
    });
  }

  private scrollToBottom(): void {
    setTimeout(() => {
      if (this.messagesContainer) {
        this.messagesContainer.nativeElement.scrollTop = this.messagesContainer.nativeElement.scrollHeight;
      }
    }, 100);
  }
}
