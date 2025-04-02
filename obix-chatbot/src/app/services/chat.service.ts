import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject, throwError } from 'rxjs';
import { tap, map, catchError } from 'rxjs/operators';

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
  private apiUrl = 'http://157.230.65.142/api'; // Corrected API URL
  private messagesSubject = new BehaviorSubject<Message[]>([]);
  messages$ = this.messagesSubject.asObservable();

  constructor(private http: HttpClient) {}

  sendMessage(content: string): Observable<string> {
    console.log('Sending user message:', content);
    this.addMessage(content, 'user');

    // Send message to backend
    return this.http.post<ChatResponse>(
      `${this.apiUrl}/chat/`, // Ensure the endpoint is correct
      { message: content }
    ).pipe(
      tap(response => {
        if (response && response.response) {
          this.addMessage(response.response, 'assistant');
        }
      }),
      map(response => response.response),
      catchError(error => {
        console.error('Error sending message:', error);
        this.addSystemMessage("Sorry, I couldn't process your request. Please try again.");
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
    this.messagesSubject.next([...currentMessages, message]);
  }

  addSystemMessage(content: string): void {
    this.addMessage(content, 'assistant');
  }

  clearMessages(): void {
    this.messagesSubject.next([]);
  }
}
