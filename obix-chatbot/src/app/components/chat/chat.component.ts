import { Component, OnInit, ViewChild, ElementRef, AfterViewChecked, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormGroup, FormBuilder } from '@angular/forms';
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';
import { AuthService } from '../../services/auth.service';
import { ChatService, Message } from '../../services/chat.service';

interface DisplayMessage extends Message {
  displayContent: string;
  isTyping: boolean;
}

@Component({
  selector: 'app-chat',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './chat.component.html',
  styleUrls: ['./chat.component.scss']
})
export class ChatComponent implements OnInit, AfterViewChecked, OnDestroy {
  @ViewChild('messagesContainer') messagesContainer!: ElementRef;
  
  chatForm: FormGroup;
  isLoading = false;
  username = '';
  messages: DisplayMessage[] = [];
  private typingSpeed = 1; // Super fast animation (was 10ms)
  
  private subscriptions: Subscription[] = [];

  constructor(
    private chatService: ChatService,
    private authService: AuthService,
    private router: Router,
    private fb: FormBuilder
  ) {
    this.chatForm = this.fb.group({
      messageInput: [{ value: '', disabled: false }]
    });
  }

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
        console.log('Received messages update, count:', messages.length);
        
        // Process all messages
        const displayMessages = messages.map((msg, index) => {
          // For user messages or existing assistant messages, keep the current display content
          const existingMsgIndex = this.messages.findIndex(m => 
            m.timestamp?.getTime() === msg.timestamp?.getTime() && m.role === msg.role
          );
          
          // If this is an existing message, keep its current display state
          if (existingMsgIndex >= 0) {
            return {
              ...msg,
              displayContent: this.messages[existingMsgIndex].displayContent,
              isTyping: this.messages[existingMsgIndex].isTyping
            };
          }
          
          // This is a new message
          // For user messages, show content immediately
          // For assistant messages, prepare for animation
          return {
            ...msg,
            displayContent: msg.role === 'user' ? msg.content : '',
            isTyping: msg.role === 'assistant'
          };
        });
        
        // Update messages array
        this.messages = displayMessages;
        
        // Find the last assistant message that needs animation
        const lastAssistantIndex = this.messages.findIndex(msg => 
          msg.role === 'assistant' && msg.isTyping
        );
        
        if (lastAssistantIndex >= 0) {
          console.log('Animating message at index:', lastAssistantIndex);
          // Use a small timeout to ensure the DOM is updated
          setTimeout(() => {
            this.animateText(lastAssistantIndex, messages[lastAssistantIndex].content);
          }, 50);
        }
        
        this.scrollToBottom();
      })
    );
    
    // Clear messages on component init
    this.chatService.clearMessages();
    
    // Set responsive behavior for mobile
    this.handleResponsiveLayout();
  }

  ngAfterViewChecked(): void {
    this.scrollToBottom();
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
  }

  sendMessage(): void {
    const message = this.chatForm.get('messageInput')?.value?.trim();
    if (!message || this.isLoading) return;
    
    this.isLoading = true;
    this.chatForm.get('messageInput')?.disable();
    
    // Send to API
    this.chatService.sendMessage(message).subscribe({
      next: (response) => {
        console.log('Received response:', response);
        this.chatForm.get('messageInput')?.setValue('');
        this.chatForm.get('messageInput')?.enable();
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
        
        this.chatForm.get('messageInput')?.enable();
        this.isLoading = false;
      }
    });
  }

  onEnterKey(event: Event): void {
    const keyboardEvent = event as KeyboardEvent;
    if (keyboardEvent.key === 'Enter' && !keyboardEvent.shiftKey) {
      event.preventDefault();
      this.sendMessage();
    }
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => {
        console.log('Logged out successfully');
        this.router.navigate(['/login']);
      },
      error: (error) => {
        console.error('Error logging out:', error);
        // Navigate to login anyway
        this.router.navigate(['/login']);
      }
    });
  }

  private scrollToBottom(): void {
    if (this.messagesContainer) {
      this.messagesContainer.nativeElement.scrollTop = this.messagesContainer.nativeElement.scrollHeight;
    }
  }

  private handleResponsiveLayout(): void {
    const handleResize = () => {
      // Add any responsive layout logic here if needed
    };

    window.addEventListener('resize', handleResize);
    this.subscriptions.push(new Subscription(() => window.removeEventListener('resize', handleResize)));
  }

  private async animateText(messageIndex: number, fullText: string) {
    try {
      const message = this.messages[messageIndex];
      if (!message) return;
      
      // Skip animation if text is empty
      if (!fullText) {
        message.displayContent = fullText;
        message.isTyping = false;
        return;
      }
      
      message.isTyping = true;
      message.displayContent = ''; // Start with empty content
      
      let charIndex = 0;
      const charsPerInterval = 15; // Process more characters at once for faster animation
      
      // Use setInterval for more reliable animation
      const intervalId = setInterval(() => {
        // Check if message still exists
        if (!this.messages[messageIndex]) {
          clearInterval(intervalId);
          return;
        }
        
        // Add next batch of characters
        const nextChunk = fullText.slice(charIndex, charIndex + charsPerInterval);
        message.displayContent += nextChunk;
        charIndex += charsPerInterval;
        
        // Force change detection
        this.messages = [...this.messages];
        
        // Check if we've reached the end of the text
        if (charIndex >= fullText.length) {
          clearInterval(intervalId);
          message.displayContent = fullText; // Ensure full content is shown
          message.isTyping = false;
          this.messages = [...this.messages];
          this.scrollToBottom();
        }
      }, 10); // Very fast interval for quick typing effect
      
      // Safety timeout to ensure animation completes
      setTimeout(() => {
        clearInterval(intervalId);
        if (this.messages[messageIndex]) {
          this.messages[messageIndex].displayContent = fullText;
          this.messages[messageIndex].isTyping = false;
          this.messages = [...this.messages];
          this.scrollToBottom();
        }
      }, 5000); // Fallback after 5 seconds
    } catch (error) {
      console.error('Animation error:', error);
      // Fallback to immediate display if there's an error
      if (this.messages[messageIndex]) {
        this.messages[messageIndex].displayContent = fullText;
        this.messages[messageIndex].isTyping = false;
        this.messages = [...this.messages];
        this.scrollToBottom();
      }
    }
  }
}
