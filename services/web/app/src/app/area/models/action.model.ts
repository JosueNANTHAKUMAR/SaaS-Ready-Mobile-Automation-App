import { Param } from './param.model';
export class Action {
    id!: number;
    name!: string;
    description!: string;
    parameters!: Param[];
    service_id!: number;
    outputs!: string[];
}