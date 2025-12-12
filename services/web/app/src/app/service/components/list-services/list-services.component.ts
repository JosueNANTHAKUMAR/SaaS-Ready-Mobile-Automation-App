import { Component, EventEmitter, OnInit, Output } from '@angular/core';
import { Observable } from 'rxjs';
import { Service } from '../../models/service.model';
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

@Component({
    selector: 'app-list-services',
    templateUrl: './list-services.component.html',
    styleUrls: ['./list-services.component.scss']
})
export class ListServicesComponent implements OnInit {
    $services!: Observable<Service[]>;
    @Output() serviceIdClicked = new EventEmitter<number>();

    constructor(private serviceService: ServiceService, private http: HttpClient, private iconRegistry: MatIconRegistry, private sanitizer: DomSanitizer, public dialog: MatDialog) {
    }

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

    onServiceClick(id: number) {
        this.serviceIdClicked.emit(id);
    }
}