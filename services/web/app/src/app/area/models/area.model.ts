import { Action } from "./action.model";
import { Reaction } from "./reaction.model";

export class Area {
    id!: number;
    name!: string;
    description!: string;
    actions!: Action[];
    reactions!: Reaction[];
    enabled!: boolean;
}