import { Injectable } from '@angular/core';
import { Resolve } from '@angular/router';
import { Observable } from 'rxjs';
import { Service } from '../../service/models/service.model';
import { ServiceService } from '../../service/services/service.service';

@Injectable({
  providedIn: 'root'
})
export class ServicesResolver implements Resolve<Observable<Service[]>> {

  constructor(private serviceService: ServiceService) { }

  resolve(): Observable<Service[]> {
    return this.serviceService.getServices();
  }
}