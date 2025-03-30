import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, from, throwError, switchMap } from 'rxjs';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { catchError, tap, map } from 'rxjs/operators';

export interface UserProfile {
  firstName: string;
  lastName: string;
  avatar: string;
}

export interface User {
  id: string;
  username: string;
  email: string;
  profile: UserProfile;
}

const DEFAULT_USER: User = {
  id: '',
  username: 'guest',
  email: '',
  profile: {
    firstName: '',
    lastName: '',
    avatar: ''
  }
};

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = 'http://localhost:8000/api';
  private currentUserSubject = new BehaviorSubject<User>(DEFAULT_USER);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    // Initialize with default user to ensure profile always exists
    this.loadUserFromStorage();
  }

  private loadUserFromStorage(): void {
    try {
      const storedUser = localStorage.getItem('currentUser');
      if (storedUser) {
        const parsedUser = JSON.parse(storedUser);
        // Ensure all required properties exist
        const user: User = {
          ...DEFAULT_USER,
          ...parsedUser,
          profile: {
            ...DEFAULT_USER.profile,
            ...(parsedUser.profile || {})
          }
        };
        this.currentUserSubject.next(user);
      } else {
        // If no stored user, use default user
        this.currentUserSubject.next(DEFAULT_USER);
      }
    } catch (error) {
      console.error('Error loading user from storage:', error);
      this.resetUserState();
    }
  }

  private resetUserState(): void {
    localStorage.removeItem('currentUser');
    this.currentUserSubject.next(DEFAULT_USER);
  }

  getCurrentUser(): User {
    const user = this.currentUserSubject.value;
    // Always return a valid user with profile
    return {
      ...DEFAULT_USER,
      ...user,
      profile: {
        ...DEFAULT_USER.profile,
        ...(user.profile || {})
      }
    };
  }

  login(username: string, password: string): Observable<User> {
    console.log('Attempting login with:', username);
    
    // First get CSRF token, then attempt login
    return this.getCSRFToken().pipe(
      switchMap(token => {
        console.log('Obtained CSRF token, proceeding with login');
        
        // For API login, send JSON instead of FormData
        const loginData = {
          username: username,
          password: password
        };

        // Set up headers for JSON content
        const headers = new HttpHeaders({
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRFToken': token
        });

        // Make a POST request to the Django login endpoint
        return this.http.post<any>(`${this.apiUrl}/`, loginData, {
          headers,
          withCredentials: true
        });
      }),
      tap(response => {
        console.log('Login response:', response);
        
        // Create a user object based on successful login
        const user: User = {
          ...DEFAULT_USER,
          id: '1', 
          username: username,
          email: username,
          profile: {
            ...DEFAULT_USER.profile
          }
        };
        
        // Store the user
        this.setCurrentUser(user);
      }),
      catchError(error => {
        console.error('Login error:', error);
        return throwError(() => new Error('Invalid credentials'));
      }),
      // Map the response to return a User object
      map(() => this.getCurrentUser())
    );
  }

  logout(): Observable<any> {
    return this.http.get(`${this.apiUrl}/logout/`, {
      withCredentials: true
    }).pipe(
      tap(() => {
        this.resetUserState();
      }),
      catchError(error => {
        console.error('Logout error:', error);
        // Still reset the user state even if the server request fails
        this.resetUserState();
        return throwError(() => new Error('Error during logout'));
      })
    );
  }

  private setCurrentUser(user: User): void {
    // Ensure profile exists with all required properties
    const safeUser: User = {
      ...DEFAULT_USER,
      ...user,
      profile: {
        ...DEFAULT_USER.profile,
        ...(user.profile || {})
      }
    };
    
    localStorage.setItem('currentUser', JSON.stringify(safeUser));
    this.currentUserSubject.next(safeUser);
  }

  isLoggedIn(): boolean {
    const user = this.currentUserSubject.value;
    return user.id !== DEFAULT_USER.id;
  }

  updateProfile(profile: Partial<UserProfile>): void {
    const currentUser = this.getCurrentUser();
    const updatedUser: User = {
      ...currentUser,
      profile: {
        ...currentUser.profile,
        ...profile
      }
    };
    this.setCurrentUser(updatedUser);
  }

  /**
   * Fetches CSRF token from the server
   */
  private getCSRFToken(): Observable<string> {
    return this.http.get<{csrfToken: string}>(`${this.apiUrl}/get-csrf-token/`, {
      withCredentials: true
    }).pipe(
      tap(response => console.log('CSRF token response received')),
      map(response => response.csrfToken),
      catchError(error => {
        console.error('Error fetching CSRF token:', error);
        return throwError(() => new Error('Failed to fetch CSRF token'));
      })
    );
  }
} 