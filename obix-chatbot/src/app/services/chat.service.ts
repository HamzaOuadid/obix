import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject, catchError, throwError } from 'rxjs';
import { map, tap } from 'rxjs/operators';

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
  private apiUrl = 'http://localhost:8000/api';
  private messagesSubject = new BehaviorSubject<Message[]>([]);
  messages$ = this.messagesSubject.asObservable();

  constructor(private http: HttpClient) {}

  sendMessage(content: string): Observable<string> {
    // Add user message to the messages array
    console.log('Sending user message:', content);
    this.addMessage(content, 'user');

    // Send message to backend with credentials
    return this.http.post<ChatResponse>(
      `${this.apiUrl}/chat/`, 
      { message: content },
      { withCredentials: true }
    )
    .pipe(
      tap(response => {
        console.log('Received response type:', typeof response);
        console.log('Received raw response:', response);
        
        // Validate response
        if (!response) {
          console.warn('Received null response from server');
          throw new Error('Empty response received');
        }
        
        // Ensure response has the response property
        let responseText = '';
        if (typeof response === 'object' && response.response) {
          responseText = response.response;
        } else if (typeof response === 'string') {
          responseText = response;
        } else {
          responseText = JSON.stringify(response);
        }
        
        console.log('Processed response text:', responseText.substring(0, 50) + '...');
        
        // Add assistant's response to messages
        this.addMessage(responseText, 'assistant');
      }),
      map(response => {
        if (typeof response === 'object' && response.response) {
          return response.response;
        }
        return JSON.stringify(response);
      }),
      catchError(error => {
        console.error('Error sending message:', error);
        
        // Add a system error message to indicate the problem
        if (error.status === 0) {
          this.addSystemMessage("Network error. Please check your connection.");
        } else if (error.status === 401 || error.status === 403) {
          this.addSystemMessage("Authentication error. Please log in again.");
        } else {
          this.addSystemMessage("Sorry, I couldn't process your request. Please try again.");
        }
        
        return throwError(() => new Error('Failed to send message: ' + (error.message || 'Unknown error')));
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
    
    // Create a new array to ensure change detection
    const newMessages = [...currentMessages, message];
    console.log(`Adding ${role} message. Message count: ${newMessages.length}`);
    this.messagesSubject.next(newMessages);
  }
  
  addSystemMessage(content: string): void {
    this.addMessage(content, 'assistant');
  }

  clearMessages(): void {
    this.messagesSubject.next([]);
  }
}
