import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LandingPageComponent } from './core/components/landing-page/landing-page.component';
import { HomeComponent } from './core/components/home/home.component';
import { AuthGuard } from './core/guards/auth.guard';
import { LoginComponent } from './auth/components/login/login.component';
import { RegisterComponent } from './auth/components/register/register.component';
import { MyAreaComponent } from './area/components/my-area/my-area.component';
import { CreateAreaComponent } from './area/components/create-area/create-area.component';
import { OauthCallbackComponent } from './core/components/oauth-callback/oauth-callback.component';

const routes: Routes = [
  { path: '', component:  LandingPageComponent},
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'home', component: HomeComponent, canActivate: [AuthGuard] },
  { path: 'my-area', component: MyAreaComponent, canActivate: [AuthGuard] },
  { path: 'create', component: CreateAreaComponent, canActivate: [AuthGuard] },
  {path: 'callback', component: OauthCallbackComponent},
  { path: '**', redirectTo: '' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }