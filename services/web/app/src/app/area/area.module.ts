import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { 
  CreateAreaComponent,
  CreateAreaDialogListServiceComponent,
  CreateAreaDialogChooseActionComponent,
  CreateAreaDialogChooseParameterComponent,
  CreateAreaDialogChooseReactionComponent
} from './components/create-area/create-area.component';
import { MyAreaComponent } from './components/my-area/my-area.component';
import { SharedModule } from '../shared/shared.module';
import { ReactiveFormsModule } from '@angular/forms';
import { ServiceModule } from '../service/service.module';



@NgModule({
  declarations: [
    MyAreaComponent,
    CreateAreaComponent,
    CreateAreaDialogListServiceComponent,
    CreateAreaDialogChooseActionComponent,
    CreateAreaDialogChooseParameterComponent,
    CreateAreaDialogChooseReactionComponent,
  ],
  imports: [
    CommonModule,
    SharedModule,
    ReactiveFormsModule,
    ServiceModule
  ]
})
export class AreaModule { }
