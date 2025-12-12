import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators , FormControl} from '@angular/forms';
import { AuthService } from '../../services/auth.service';
import { Router, ActivatedRoute } from '@angular/router';
import { AbstractControl, ValidatorFn } from '@angular/forms';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.scss']
})
export class RegisterComponent implements OnInit{

  registerForm!: FormGroup;

  constructor(private formBuilder: FormBuilder, private auth: AuthService, private router: Router) { }

  ngOnInit() {
    this.registerForm = this.formBuilder.group({
      email: ['', Validators.compose([Validators.required, Validators.email])],
      password: ['', Validators.required],
      confirmPassword: ['', Validators.required]
    }, {
      validators: this.matchValidator('password', 'confirmPassword'),
      updateOn: 'submit'
    }
    )
  }

  matchValidator(controlName: string, matchingControlName: string): ValidatorFn {
    return (abstractControl: AbstractControl) => {
        const control = abstractControl.get(controlName);
        const matchingControl = abstractControl.get(matchingControlName);

        if (matchingControl!.errors && !matchingControl!.errors?.['confirmedValidator']) {
            return null;
        }

        if (control!.value !== matchingControl!.value) {
          const error = { confirmedValidator: 'Passwords do not match.' };
          matchingControl!.setErrors(error);
          return error;
        } else {
          matchingControl!.setErrors(null);
          return null;
        }
    }
  }

  onRegister() {
    if (this.registerForm.invalid) {
      
      return;
    }
    this.auth.register(this.registerForm.value.email, this.registerForm.value.password);
  }

  onGoogleLogin() {
    this.auth.getGoogleRedirectionURL().subscribe((res: any) => {
        const popup = window.open(res.url, '_blank', 'width=500,height=600');
        if (popup) {
            popup.focus();
            window.addEventListener("message", (event) => {
              if (event.data) {
                this.auth.loginWithGoogle(event.data).subscribe(() => {
                  popup.close();
                  this.router.navigateByUrl('/home');
                });
              }
            });
          }
    });
  }

}
