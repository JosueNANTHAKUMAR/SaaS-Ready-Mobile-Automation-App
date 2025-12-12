import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { Observable, map, switchMap } from 'rxjs';
import { Area } from '../models/area.model';

@Injectable({
    providedIn: 'root'
    })
export class AreaService {

    constructor(private http: HttpClient) { }

    getAreas():Observable<Area[]> {
        return this.http.get<Area[]>(environment.apiUrl + '/areas');
    }

    postArea(area: Area) {
        return this.http.post(environment.apiUrl + '/area', area);
    }

    deleteArea(id: number){
        return this.http.delete(environment.apiUrl + '/area/' + id);
    }

    toggleArea(area: Area) {
        return this.http.put(environment.apiUrl + '/area/toggle/' + area.id, area);
    }
}