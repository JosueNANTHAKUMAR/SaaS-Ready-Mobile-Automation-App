import { Component, Input, OnInit } from '@angular/core';
import { MatDialog, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Inject } from '@angular/core';
import { Area } from '../../models/area.model';
import { ServiceService } from '../../../service/services/service.service';
import { Service } from '../../../service/models/service.model';
import { Action } from '../../models/action.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Observable, map } from 'rxjs';
import { Param } from '../../models/param.model';
import { Reaction } from '../../models/reaction.model';
import { AreaService } from '../../services/area.service';
import { Router } from '@angular/router';
import { OauthService } from '../../../core/services/oauth.service';


@Component({
  selector: 'app-create-area',
  templateUrl: './create-area.component.html',
  styleUrls: ['./create-area.component.scss']
})
export class CreateAreaComponent {

  area!: Area
  submitAreaForm!: FormGroup;

  constructor(public dialog: MatDialog, private formBuilder: FormBuilder, private areaService: AreaService, private router: Router) {
    this.area = new Area();
    this.area.name = "";
    this.area.description = "";
    this.area.actions = [];
    this.area.reactions = [];
    this.area.id = 0;
    this.submitAreaForm = this.formBuilder.group({
      name: [null, [Validators.required, Validators.minLength(3)]],
      description: [null, [Validators.required, Validators.minLength(3)]],
      area: [this.area, [Validators.required]],
    });
  }

  openDialog(isAction: 'action' | 'reaction'): void {
    if (isAction === 'action') {
      if (this.area.actions.length > 0)
        this.area.actions.pop();
      this.dialog.open(CreateAreaDialogListServiceComponent, {
        data: {area: this.area, isReaction: false}
      });
    } else {
      if (this.area.reactions.length > 0)
        this.area.reactions.pop();
      this.dialog.open(CreateAreaDialogListServiceComponent, {
        data: {area: this.area, isReaction: true}
      });
    }
    this.dialog.afterAllClosed.subscribe(result => {
    });
  }

  submitArea() {
    if (this.submitAreaForm.invalid) {
      return;
    }
    this.area.name = this.submitAreaForm.get('name')?.value;
    this.area.description = this.submitAreaForm.get('description')?.value;
    this.areaService.postArea(this.area).subscribe(result => {
      this.router.navigate(['/my-area']);
    }
    );
    this.dialog.closeAll();
  }
}

// ************************************************************
// ------------------- list service dialog -------------------
// ************************************************************
@Component({
  selector: 'app-create-area-dialog-list-services',
  templateUrl: './create-area-dialog.component.html',
  styleUrls: ['./create-area-dialog.component.scss']
})
export class CreateAreaDialogListServiceComponent {

  constructor(
    public dialogRef: MatDialogRef<CreateAreaDialogListServiceComponent>,
    @Inject(MAT_DIALOG_DATA) public data: {area: Area, isReaction: boolean},
    public dialog2: MatDialog) {}

  onNoClick(): void {
    this.dialogRef.close();
  }

  openDialog2(id: number): void {
    if (!this.data.isReaction) {
      this.dialog2.open(CreateAreaDialogChooseActionComponent, {
        data: {area: this.data.area, id: id, isReaction: this.data.isReaction}
      });
    } else {
      this.dialog2.open(CreateAreaDialogChooseReactionComponent, {
        data: {area: this.data.area, id: id, isReaction: this.data.isReaction}
      });
    }
  }

  onServiceClick(id: number) {
    this.openDialog2(id);
    this.dialogRef.close();
  }
}

// ************************************************************
// ------------------- choose action dialog ------------------
// ************************************************************

@Component({
  selector: 'app-create-area-dialog-choose-action',
  templateUrl: './create-area-dialog-choose-action.component.html',
  styleUrls: ['./create-area-dialog-choose-action.component.scss']
})
export class CreateAreaDialogChooseActionComponent implements OnInit {

  service$!: Observable<Service>;
  isSubscribed: boolean = false;

  constructor(
    public dialogRef: MatDialogRef<CreateAreaDialogChooseActionComponent>,
    @Inject(MAT_DIALOG_DATA) public data: {area: Area, id: number, isReaction: boolean},
    private serviceService: ServiceService, private oauth: OauthService, public dialog3: MatDialog) {}

  ngOnInit() {
    this.service$ = this.serviceService.getService(this.data.id);
    this.serviceService.getSubscribedServices(this.data.id).subscribe(result => {
      if (result) {
        this.isSubscribed = true;
      }
    });
  }

  subscribeToService() {
    this.oauth.getAuthUrl(this.data.id).pipe(
      map((result: any) => {
        const popup = window.open(result.url, 'authorization', 'width=500,height=500');
        if (popup) {
          popup.focus();
          window.addEventListener("message", (event) => {
            if (event.data) {
              this.oauth.postAuthCode(this.data.id, event.data).subscribe(result => {
                this.isSubscribed = true;
                popup.close();
              });
            }
          });
        }
      }
    )).subscribe();
  }

  openDialog3(): void {
    const dialogRef = this.dialog3.open(CreateAreaDialogChooseParameterComponent, {
      data: {area: this.data.area, service: this.service$, isReaction: this.data.isReaction}
    });

    dialogRef.afterClosed().subscribe(result => {
    });
  }

  returnToServiceList() {
    this.dialogRef.close();
    this.dialog3.open(CreateAreaDialogListServiceComponent, {
      data: {area: this.data.area, isReaction: this.data.isReaction}
    });
  }

  onNoClick(): void {
    this.dialogRef.close();
  }

  onActionClick(action: Action) {
    this.data.area.actions.push(action);
    this.openDialog3();
    this.dialogRef.close();
  }
}

// ************************************************************
// ------------------- choose reaction dialog -------------------
// ************************************************************

@Component({
  selector: 'app-create-area-dialog-choose-reaction',
  templateUrl: './create-area-dialog-choose-reaction.component.html',
  styleUrls: ['./create-area-dialog-choose-reaction.component.scss']
})
export class CreateAreaDialogChooseReactionComponent implements OnInit {

  service$!: Observable<Service>;
  isSubscribed: boolean = false;

  constructor(
    public dialogRef: MatDialogRef<CreateAreaDialogChooseReactionComponent>,
    @Inject(MAT_DIALOG_DATA) public data: {area: Area, id: number, isReaction: boolean},
    private serviceService: ServiceService, public dialog3: MatDialog, private oauth: OauthService) {}

  ngOnInit() {
    this.service$ = this.serviceService.getService(this.data.id);
    this.serviceService.getSubscribedServices(this.data.id).subscribe(result => {
      if (result) {
        this.isSubscribed = true;
      }
    });
  }

  openDialog3(): void {
    const dialogRef = this.dialog3.open(CreateAreaDialogChooseParameterComponent, {
      data: {area: this.data.area, service: this.service$, isReaction: this.data.isReaction}
    });

    dialogRef.afterClosed().subscribe(result => {
    });
  }

  subscribeToService() {
    this.oauth.getAuthUrl(this.data.id).pipe(
      map((result: any) => {
        const popup = window.open(result.url, 'authorization', 'width=500,height=500');
        if (popup) {
          popup.focus();
          window.addEventListener("message", (event) => {
            if (event.data) {
              this.oauth.postAuthCode(this.data.id, event.data).subscribe(result => {
                this.isSubscribed = true;
                popup.close();
              });
            }
          });
        }
      }
    )).subscribe();
  }

  returnToServiceList() {
    this.dialogRef.close();
    this.dialog3.open(CreateAreaDialogListServiceComponent, {
      data: {area: this.data.area, isReaction: this.data.isReaction}
    });
  }

  onNoClick(): void {
    this.dialogRef.close();
  }

  onReactionClick(reaction: Reaction) {
    this.data.area.reactions.push(reaction);
    this.openDialog3();
    this.dialogRef.close();
  }
}

// ******************************************************
// ------------------ parameter dialog ------------------
// ******************************************************

@Component({
  selector: 'app-create-area-dialog-choose-parameter',
  templateUrl: './create-area-dialog-choose-parameter.component.html',
  styleUrls: ['./create-area-dialog-choose-parameter.component.scss']
})
export class CreateAreaDialogChooseParameterComponent implements OnInit {

  paramForm!: FormGroup;
  params!: Param[]
  

  constructor(
    public dialogRef: MatDialogRef<CreateAreaDialogChooseParameterComponent>,
    @Inject(MAT_DIALOG_DATA) public data: {area: Area, service: Service, isReaction: boolean},
    private formBuilder: FormBuilder, public dialog: MatDialog) {}

  ngOnInit() {

    this.paramForm = this.formBuilder.group({});
    if (!this.data.isReaction) {
      this.params = this.data.area.actions[0].parameters;
    } else {
      this.params = this.data.area.reactions[0].parameters;
    }
    this.params.forEach(param => {
      if (param.required === true)
        this.paramForm.addControl(param.name, this.formBuilder.control('', Validators.required));
      else
        this.paramForm.addControl(param.name, this.formBuilder.control(''));
    });
  }

  onNoClick(): void {
    this.dialogRef.close();
  }

  returnToActionList() {
    this.dialogRef.close();
    if (!this.data.isReaction) {
      this.data.area.actions.pop();
      this.dialogRef.close();
    //   this.dialog.open(CreateAreaDialogChooseActionComponent, {
    //     data: {area: this.data.area, id: this.data.service.id, isReaction: this.data.isReaction}
    //   });
    } else {
      this.data.area.reactions.pop();
      this.dialogRef.close();
    //   this.dialog.open(CreateAreaDialogChooseReactionComponent, {
    //     data: {area: this.data.area, id: this.data.service.id, isReaction: this.data.isReaction}
    //   });
    }
  }

  onSaveClick() {
    if (this.paramForm.invalid) {
      return;
    }
    if (!this.data.isReaction) {
      this.data.area.actions[0].parameters.forEach(param => {
        if (param.type === 'number')
          param.value = String(this.paramForm.get(param.name)?.value);
        else
          param.value = this.paramForm.get(param.name)?.value;
      });
      this.data.isReaction = true;
    } else {
      this.data.area.reactions[0].parameters.forEach(param => {
        if (param.type === 'number')
          param.value = String(this.paramForm.get(param.name)?.value);
        else
          param.value = this.paramForm.get(param.name)?.value;
      });
    }
    this.dialogRef.close();
  }
}