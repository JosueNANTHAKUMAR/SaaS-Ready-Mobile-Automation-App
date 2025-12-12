import { Component, EventEmitter, OnInit, Output } from '@angular/core';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../environments/environment';
import { MatIconRegistry } from '@angular/material/icon';
import { DomSanitizer } from '@angular/platform-browser';
import { Inject } from '@angular/core';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatDialog } from '@angular/material/dialog';
import { OauthService } from '../../../core/services/oauth.service';
import { map } from 'rxjs/operators';
import { ServiceService } from '../../../service/services/service.service';
import { Service } from '../../../service/models/service.model';


@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent {
    $services!: Observable<Service[]>;

    constructor(
        private serviceService: ServiceService,
        private http: HttpClient,
        private iconRegistry: MatIconRegistry,
        private sanitizer: DomSanitizer,
        public dialog: MatDialog
    ) {}

    ngOnInit(): void {
        this.$services = this.serviceService.getServices();
        this.http.get(environment.apiUrl + '/services/icons').subscribe((data: any) => {
            const entries = Object.entries(data);
            entries.forEach((entry) => {
                const [key, value] = entry;
                this.iconRegistry.addSvgIconLiteral(
                    key,
                    this.sanitizer.bypassSecurityTrustHtml(value as string)
                );
            });
        });
    }

    openDialog(id: number) {
        this.dialog.open(ListServicesDialogComponent, {
            data: {
                serviceId: id
            }
        });
    }
}


@Component({
    selector: 'app-list-services',
    templateUrl: './list-services-dialog.component.html',
    styleUrls: ['./list-services-dialog.component.scss']
})
export class ListServicesDialogComponent {
    $service!: Observable<Service>;
    isSubscribed: boolean = false;
    constructor(
        public dialogRef: MatDialogRef<ListServicesDialogComponent>,
        @Inject(MAT_DIALOG_DATA) public data: { serviceId: number },
        public serviceService: ServiceService,
        private oauth: OauthService,
        public dialog: MatDialog
    ) { }

    ngOnInit(): void {
        this.$service = this.serviceService.getService(this.data.serviceId);
        this.serviceService.getSubscribedServices(this.data.serviceId).subscribe(data => {
            if (data) {
                this.isSubscribed = true;
            }
        });
    }

    closeDialog() {
        this.dialogRef.close();
    }

    subscribeToService() {
        this.oauth.getAuthUrl(this.data.serviceId).pipe(
            map((result: any) => {
                const popup = window.open(result.url, 'authorization', 'width=500,height=500');
                if (popup) {
                    popup.focus();
                    window.addEventListener("message", (event) => {
                        if (event.data) {
                            this.oauth.postAuthCode(this.data.serviceId, event.data).subscribe(result => {
                                this.isSubscribed = true;
                                popup.close();
                            });
                        }
                    });
                }
            }
        )).subscribe();
    }

    unsubscribeFromService() {
        this.serviceService.unsubscribeFromService(this.data.serviceId).subscribe(result => {
            this.isSubscribed = false;
        });
    }

    noActions() {
        this.dialogRef.close();
    }
}

