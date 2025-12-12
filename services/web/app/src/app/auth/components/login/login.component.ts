import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { Router, ActivatedRoute } from '@angular/router';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit{

  loginForm!: FormGroup;

  constructor(private formBuilder: FormBuilder, private authService: AuthService, private router: Router) { }

  ngOnInit() {
    this.loginForm = this.formBuilder.group({
      email: ['', Validators.compose([Validators.required, Validators.email])],
      password: ['', Validators.required]
    })
  }

  onLogin() {
    if (this.loginForm.invalid) {
      return;
    }
    this.authService.login(this.loginForm.value.email, this.loginForm.value.password);
  }

  onGoogleLogin() {
    this.authService.getGoogleRedirectionURL().subscribe((res: any) => {
        const popup = window.open(res.url, '_blank', 'width=500,height=600');
        if (popup) {
            popup.focus();
            window.addEventListener("message", (event) => {
              if (event.data) {
                this.authService.loginWithGoogle(event.data).subscribe(() => {
                  popup.close();
                  this.router.navigateByUrl('/home');
                });
              }
            });
          }
    });
  }
}
