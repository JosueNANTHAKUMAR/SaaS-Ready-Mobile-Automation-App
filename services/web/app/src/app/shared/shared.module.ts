import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ShortenPipe } from './pipes/shorten.pipe';
import { TimeAgoPipe } from './pipes/time-ago.pipe';
import { UsernamePipe } from './pipes/username.pipe';
import { MaterialModule } from './material.module';
import { serviceColorDirective } from './directives/service-color.directive';



@NgModule({
  declarations: [
    ShortenPipe,
    TimeAgoPipe,
    UsernamePipe,
    serviceColorDirective
  ],
  imports: [
    CommonModule,
    MaterialModule
  ],
  exports: [
    MaterialModule,
    ShortenPipe,
    TimeAgoPipe,
    UsernamePipe,
    serviceColorDirective
  ]
})
export class SharedModule { }
