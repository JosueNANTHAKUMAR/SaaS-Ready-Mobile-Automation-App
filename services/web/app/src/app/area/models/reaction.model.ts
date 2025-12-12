import { Param } from './param.model';

export class Reaction {
    id!: number;
    name!: string;
    description!: string;
    parameters!: Param[];
    service_id!: number;
}