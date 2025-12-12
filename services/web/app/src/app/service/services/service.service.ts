import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Observable, map, switchMap, tap } from 'rxjs';
import { Service } from '../models/service.model';

@Injectable({
    providedIn: 'root'
    })
export class ServiceService {

    constructor(private http: HttpClient) { }
    getServices():Observable<Service[]> {
        return this.http.get<Service[]>(environment.apiUrl + '/services');
    }

    getService(id: number):Observable<Service> {
        return this.http.get<Service>(environment.apiUrl + '/services/' + id);
    }

    getSubscribedServices(id: number):Observable<Service> {
        return this.getServices().pipe(
            map(services => services.filter(service => service.id === id)),
            map(services => services[0]),
            map(service => service.name),
            switchMap(name => this.http.get<Service[]>(environment.apiUrl + '/user/services').pipe(
                map(services => services.filter(service => service.name === name)),
                map(services => services[0]),
                map(service => service as Service)
            ))
        );
    }

    unsubscribeFromService(id: number):Observable<Service> {
        return this.http.delete<Service>(environment.apiUrl + '/user/services/unsubscribe/' + id);
    }
}