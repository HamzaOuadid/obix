import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';

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

// Hard-coded user for POC
const HARD_CODED_USER: User = {
  id: '1',
  username: 'demo',
  email: 'demo@example.com',
  profile: {
    firstName: 'Demo',
    lastName: 'User',
    avatar: ''
  }
};

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();

  constructor() {
    // Check if user already exists in localStorage
    this.loadUserFromStorage();
  }

  private loadUserFromStorage(): void {
    const storedUser = localStorage.getItem('currentUser');
    if (storedUser) {
      try {
        this.currentUserSubject.next(JSON.parse(storedUser));
      } catch (error) {
        console.error('Error loading user from storage:', error);
        localStorage.removeItem('currentUser');
      }
    }
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  login(username: string, password: string): Observable<User> {
    console.log('Using hard-coded user login for POC');
    
    // Simulate network delay
    return of(HARD_CODED_USER).pipe(
      delay(800), // Add a small delay to simulate network request
    );
  }

  loginSuccess(user: User = HARD_CODED_USER): void {
    // Store user in localStorage
    localStorage.setItem('currentUser', JSON.stringify(user));
    this.currentUserSubject.next(user);
  }

  logout(): Observable<void> {
    localStorage.removeItem('currentUser');
    this.currentUserSubject.next(null);
    return of(void 0).pipe(delay(300)); // Simulate network delay
  }

  isLoggedIn(): boolean {
    return !!this.currentUserSubject.value;
  }

  updateProfile(profile: Partial<UserProfile>): void {
    const currentUser = this.getCurrentUser();
    if (currentUser) {
      const updatedUser: User = {
        ...currentUser,
        profile: {
          ...currentUser.profile,
          ...profile
        }
      };
      localStorage.setItem('currentUser', JSON.stringify(updatedUser));
      this.currentUserSubject.next(updatedUser);
    }
  }
} 