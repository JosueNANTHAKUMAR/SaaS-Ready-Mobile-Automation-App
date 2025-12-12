import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { Area } from '../../models/area.model';
import { AreaService } from '../../services/area.service';


@Component({
    selector: 'app-my-area',
    templateUrl: './my-area.component.html',
    styleUrls: ['./my-area.component.scss']
})
export class MyAreaComponent implements OnInit {

    areas$!: Observable<Area[]>;

    constructor(private areaService: AreaService) { }

    ngOnInit(): void {
        this.areas$ = this.areaService.getAreas();
    }

    toggleArea(area: Area) {
        this.areaService.toggleArea(area).subscribe();
    }

}
