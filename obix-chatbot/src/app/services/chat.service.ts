import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, BehaviorSubject, throwError, of } from 'rxjs';
import { tap, map, catchError, timeout, finalize } from 'rxjs/operators';

// Define the window with env property
declare global {
  interface Window {
    env: {
      apiUrl: string;
      [key: string]: any;
    };
  }
}

export interface Message {
  content: string;
  role: 'user' | 'assistant';
  timestamp: Date;
}

export interface ChatResponse {
  response: string;
}

@Injectable({
  providedIn: 'root'
})
export class ChatService {
  // Use environment variable if available, otherwise fall back to default
  private apiUrl = window.env?.apiUrl || 'http://localhost:8000/api';
    
  private messagesSubject = new BehaviorSubject<Message[]>([]);
  messages$ = this.messagesSubject.asObservable();

  constructor(private http: HttpClient) {
    console.log('API URL:', this.apiUrl);
  }

  sendMessage(content: string): Observable<string> {
    console.log('Sending user message:', content);
    this.addMessage(content, 'user');

    // Send message to backend
    return this.http.post<ChatResponse>(
      `${this.apiUrl}/chat/`, // Ensure the endpoint is correct
      { message: content }
    ).pipe(
      timeout(60000), // 60 second timeout for long responses
      tap(response => {
        console.log('Response received:', response);
        if (response && response.response) {
          // Clean up the response - trim extra whitespace, ensure proper newlines
          const cleanedResponse = this.cleanResponseText(response.response);
          this.addMessage(cleanedResponse, 'assistant');
        }
      }),
      map(response => response.response || ''),
      catchError((error: HttpErrorResponse) => {
        console.error('Error sending message:', error);
        let errorMessage = "Sorry, I couldn't process your request. Please try again.";
        
        if (error.status === 0) {
          errorMessage = "Cannot connect to the server. Please check your internet connection.";
        } else if (error.status === 500) {
          errorMessage = "The server encountered an error. Our team has been notified.";
        } else if (error.status === 429) {
          errorMessage = "You've sent too many messages. Please wait a moment and try again.";
        }
        
        this.addSystemMessage(errorMessage);
        return throwError(() => new Error('Failed to send message: ' + (error.message || 'Unknown error')));
      }),
      finalize(() => {
        console.log('Request finished');
      })
    );
  }

  addMessage(content: string, role: 'user' | 'assistant'): void {
    const message: Message = {
      content,
      role,
      timestamp: new Date()
    };
    const currentMessages = this.messagesSubject.value;
    this.messagesSubject.next([...currentMessages, message]);
  }

  addSystemMessage(content: string): void {
    this.addMessage(content, 'assistant');
  }

  clearMessages(): void {
    this.messagesSubject.next([]);
  }
  
  // Helper to clean up response text
  private cleanResponseText(text: string): string {
    // Remove excessive whitespace
    let cleaned = text.trim().replace(/\s+\n/g, '\n').replace(/\n\s+/g, '\n');
    
    // Make sure TOKENIZE is properly formatted
    if (cleaned.indexOf('TOKENIZE($DEBT)') > -1) {
      // Create proper spacing before TOKENIZE
      cleaned = cleaned.replace(/TOKENIZE\(\$DEBT\)/g, '\n\nTOKENIZE($DEBT)');
    }
    
    return cleaned;
  }
}
