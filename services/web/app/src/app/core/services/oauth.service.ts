import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class OauthService {

  constructor(private http: HttpClient) { }


  getAuthUrl(serviceId: number)  {
    return this.http.get(`${environment.apiUrl}/auth/services/${serviceId}`);
  }

  postAuthCode(serviceId: number, code: string) {
    const body = { id: serviceId, code: code };
    return this.http.post(`${environment.apiUrl}/auth/services`, body);
  }
}
