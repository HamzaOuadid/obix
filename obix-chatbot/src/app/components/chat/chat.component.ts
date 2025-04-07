import { Component, OnInit, AfterViewChecked, OnDestroy, ViewChild, ElementRef, ChangeDetectorRef } from '@angular/core';
import { FormGroup, FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { ChatService } from '../../services/chat.service';
import { Subscription } from 'rxjs';
import { NewlineToBrPipe } from '../../pipes/newline-to-br.pipe';

// Import the actual Message type from wherever it's defined in your project
// If you can't locate it, we'll work with what we have
interface Message {
  content: string;
  role: string;
  timestamp: Date;
  // Note: Removed id as it appears this doesn't exist in your actual Message type
}

interface DisplayMessage extends Message {
  id: string; // Add id here instead of expecting it from Message
  displayContent: string;
  isTyping: boolean;
}

@Component({
  selector: 'app-chat',
  templateUrl: './chat.component.html',
  styleUrls: ['./chat.component.scss'],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    NewlineToBrPipe
  ],
  standalone: true
})
export class ChatComponent implements OnInit, AfterViewChecked, OnDestroy {
  @ViewChild('messagesContainer') messagesContainer!: ElementRef;
  chatForm: FormGroup;
  isLoading = false;
  messages: DisplayMessage[] = [];
  private subscriptions: Subscription[] = [];
  private shouldScroll = false;
  username: string = 'User';

  constructor(
    private chatService: ChatService,
    private fb: FormBuilder,
    private cdRef: ChangeDetectorRef,
    private router: Router
  ) {
    this.chatForm = this.fb.group({
      messageInput: ['']
    });
  }

  ngOnInit(): void {
    console.log('Chat component initializing');
    // Check if user is logged in
    const authToken = localStorage.getItem('obixAuthToken');
    if (!authToken) {
      console.log('No auth token found, redirecting to login');
      // Not logged in, redirect to login
      window.location.href = './login';
      return;
    }
    console.log('Auth token found, proceeding to chat');

    // Get username
    const storedUsername = localStorage.getItem('obixUsername');
    if (storedUsername) {
      console.log('Username found:', storedUsername);
      this.username = storedUsername;
    }

    console.log('Subscribing to chat service messages');
    this.subscriptions.push(this.chatService.messages$.subscribe(messages => {
      console.log('Received messages update:', messages);
      // Generate ID for each message since it's not provided by the original Message type
      this.messages = messages.map(msg => ({
        ...msg,
        id: `msg-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
        displayContent: msg.content,
        isTyping: false
      }));
      
      this.shouldScroll = true;
      this.cdRef.detectChanges(); // Force update the view
    }));
  }

  ngAfterViewChecked(): void {
    if (this.shouldScroll) {
      this.scrollToBottom();
      this.shouldScroll = false;
    }
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
  }

  sendMessage(): void {
    if (this.chatForm.valid && this.chatForm.get('messageInput')?.value?.trim()) {
      this.isLoading = true;
      const messageContent = this.chatForm.get('messageInput')?.value;
      console.log('Sending message:', messageContent);
      
      this.chatForm.reset(); // Clear input immediately after sending
      
      this.chatService.sendMessage(messageContent).subscribe({
        next: (response) => {
          console.log('Received response:', response);
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Error in chat component:', error);
          this.isLoading = false;
        }
      });
    }
  }

  private scrollToBottom(): void {
    try {
      if (this.messagesContainer && this.messagesContainer.nativeElement) {
        this.messagesContainer.nativeElement.scrollTop = this.messagesContainer.nativeElement.scrollHeight;
      }
    } catch (err) {
      console.error('Error scrolling to bottom:', err);
    }
  }

  logout(): void {
    console.log('Logging out user');
    // Clear local storage
    localStorage.removeItem('obixAuthToken');
    localStorage.removeItem('obixUsername');
    
    // Navigate to login using direct URL
    console.log('Redirecting to login page');
    window.location.href = './login';
  }
}
