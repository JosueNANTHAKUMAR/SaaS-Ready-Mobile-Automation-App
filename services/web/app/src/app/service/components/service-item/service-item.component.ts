import { Component, Input, Output } from '@angular/core';
import { Service } from '../../../service/models/service.model';
import { EventEmitter } from '@angular/core';

@Component({
  selector: 'app-service-item',
  templateUrl: './service-item.component.html',
  styleUrls: ['./service-item.component.scss']
})
export class ServiceItemComponent {
  @Input() service!: Service;
  @Output() serviceId = new EventEmitter<number>();

  constructor() { }

  onServiceClick() {
    this.serviceId.emit(this.service.id);
  }
}
