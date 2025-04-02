import { Component, OnInit, AfterViewChecked, OnDestroy, ViewChild, ElementRef } from '@angular/core';
import { FormGroup, FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ChatService } from '../../services/chat.service';
import { Subscription } from 'rxjs';

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
    ReactiveFormsModule
  ],
  standalone: true
})
export class ChatComponent implements OnInit, AfterViewChecked, OnDestroy {
  @ViewChild('messagesContainer') messagesContainer!: ElementRef;
  chatForm: FormGroup;
  isLoading = false;
  messages: DisplayMessage[] = [];
  private subscriptions: Subscription[] = [];

  constructor(
    private chatService: ChatService,
    private fb: FormBuilder
  ) {
    this.chatForm = this.fb.group({
      messageInput: ['']
    });
  }

  ngOnInit(): void {
    this.subscriptions.push(this.chatService.messages$.subscribe(messages => {
      // Generate ID for each message since it's not provided by the original Message type
      this.messages = messages.map(msg => ({
        ...msg,
        id: `msg-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
        displayContent: msg.content,
        isTyping: false
      }));
    }));
  }

  ngAfterViewChecked(): void {
    this.scrollToBottom();
  }

  ngOnDestroy(): void {
    this.subscriptions.forEach(sub => sub.unsubscribe());
  }

  sendMessage(): void {
    if (this.chatForm.valid) {
      this.isLoading = true;
      const messageContent = this.chatForm.get('messageInput')?.value;
      this.chatService.sendMessage(messageContent).subscribe({
        next: () => {
          this.isLoading = false;
          this.chatForm.reset();
        },
        error: () => {
          this.isLoading = false;
        }
      });
    }
  }

  private scrollToBottom(): void {
    setTimeout(() => {
      this.messagesContainer.nativeElement.scrollTop = this.messagesContainer.nativeElement.scrollHeight;
    }, 100);
  }
}
