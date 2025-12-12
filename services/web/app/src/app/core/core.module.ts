import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ReactiveFormsModule } from '@angular/forms';
import { HeaderComponent } from './components/header/header.component';
import { SharedModule } from '../shared/shared.module';
import { LandingPageComponent } from './components/landing-page/landing-page.component';
import { HomeComponent, ListServicesDialogComponent } from './components/home/home.component';

import { httpInterceptorProviders } from './interceptors';
import { OauthCallbackComponent } from './components/oauth-callback/oauth-callback.component';
import { ServiceModule } from '../service/service.module';



@NgModule({
  declarations: [
    HeaderComponent,
    LandingPageComponent,
    HomeComponent,
    OauthCallbackComponent,
    ListServicesDialogComponent
  ],
  imports: [
    CommonModule,
    RouterModule,
    SharedModule,
    ServiceModule,
    ReactiveFormsModule
  ],
  exports: [
    HeaderComponent
  ],
  providers: [
    httpInterceptorProviders
  ]
})
export class CoreModule { }
