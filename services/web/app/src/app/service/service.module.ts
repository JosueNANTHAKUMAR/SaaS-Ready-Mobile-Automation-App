import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ListServicesComponent } from './components/list-services/list-services.component';
import { ServiceItemComponent } from './components/service-item/service-item.component';
import { SharedModule } from '../shared/shared.module';



@NgModule({
  declarations: [
    ListServicesComponent,
    ServiceItemComponent,
  ],
  imports: [
    CommonModule,
    SharedModule
  ],
  exports: [
    ListServicesComponent,
    ServiceItemComponent
  ]
})
export class ServiceModule { }
