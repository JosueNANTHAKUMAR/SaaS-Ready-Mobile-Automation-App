import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Router } from '@angular/router';
import { map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  authToken = '';

  constructor(private http: HttpClient, private router: Router) { }

  login(email: string, password: string) {
    this.http.post(environment.apiUrl + '/login', {email: email, password: password}).subscribe((res: any) => {
      this.authToken = res['access_token'];
      this.router.navigateByUrl('/home');
    });
  }

  isAuthenticated() : boolean {
    return this.authToken.length > 0;
  }

  getAuthToken(): string {
    return this.authToken;
  }

  register(email: string, password: string) {
    this.http.post(environment.apiUrl + '/register', {email: email, password: password}).subscribe((res: any) => {
      this.authToken = res['access_token'];
      this.router.navigateByUrl('/home');
    });
  }

  getGoogleRedirectionURL() {
    return this.http.get(environment.apiUrl + '/auth/register/url');
  }

  loginWithGoogle(code: string) {
    return this.http.post(environment.apiUrl + '/auth/register', {code: code}).pipe(
        map((res: any) => {
            this.authToken = res['access_token'];
        })
    );
  }

  logout() {
    this.authToken = '';
    this.router.navigateByUrl('/login');
  }
}
