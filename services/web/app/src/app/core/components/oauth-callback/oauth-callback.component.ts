import { Component, OnInit } from '@angular/core';
import { OauthService } from '../../services/oauth.service';

@Component({
  selector: 'app-oauth-test-callback',
  templateUrl: './oauth-callback.component.html',
  styleUrls: ['./oauth-callback.component.scss']
})
export class OauthCallbackComponent implements OnInit {
  
    constructor(private oauth: OauthService) { }

    ngOnInit(): void {
      window.opener.postMessage(window.location.href.split('=')[1], '*');
    }
}
