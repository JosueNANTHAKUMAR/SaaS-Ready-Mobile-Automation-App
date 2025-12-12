import { Action } from "../../area/models/action.model";
import { Reaction } from "../../area/models/reaction.model";

export class Service {
    id!: number;
    name!: string;
    description!: string;
    icon!: string;
    subscribable!: boolean;
    actions!: Action[];
    reactions!: Reaction[];
    color!: string;
}