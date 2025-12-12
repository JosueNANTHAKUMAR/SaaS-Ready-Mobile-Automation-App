from flask import jsonify, Blueprint, request
from . import Area, ActionWithValues, REActionWithValues, ParameterWithValues, Output
from .model import AreaOutOfDb
from . import db, scheduler
from .triggers import actions
from .token import token_required

areaManagement = Blueprint('areaManagement', __name__)

@areaManagement.route('/areas', methods=['GET'])
@token_required
def get_areas(current_user):
    areas = db.session.query(Area).filter_by(user_id=current_user.id).all()
    return jsonify([area.serialize() for area in areas]), 200

@areaManagement.route('/area', methods=['POST'])
@token_required
def create_area(current_user):
    if not request.is_json:
        return jsonify({"error": "Missing JSON in request"}), 400
    data = request.get_json()
    name = data.get('name')
    description = data.get('description')
    actions_data = data.get('actions')
    reactions = data.get('reactions')

    area_actions = []
    for action in actions_data:
        actionWithValues = ActionWithValues(name=action['name'], description=action['description'], service_id=action['service_id'])
        for parameter in action['parameters']:
            actionWithValues.parameters.append(ParameterWithValues(name=parameter['name'], type=parameter['type'], value=parameter['value']))
        for output in action['outputs']:
            actionWithValues.outputs.append(Output(name=output['name'], type=output['type']))
        area_actions.append(actionWithValues)

    area_reactions = []
    for reaction in reactions:
        reactionWithValues = REActionWithValues(name=reaction['name'], description=reaction['description'], service_id=reaction['service_id'])
        for parameter in reaction['parameters']:
            reactionWithValues.parameters.append(ParameterWithValues(name=parameter['name'], type=parameter['type'], value=parameter['value']))
        area_reactions.append(reactionWithValues)

    area = db.session.query(Area).filter_by(name=name, user_id=current_user.id).first()
    if area:
        return jsonify({"error": "Area already exists"}), 400
    area = Area(name=name, description=description, user_id=current_user.id)
    area.add_action_array(area_actions)
    area.add_reaction_array(area_reactions)
    db.session.add(area)
    db.session.commit()
    print("###############################")
    print(area.serialize())
    print("###############################")
    area.serialize()
    areaOutOfDb = AreaOutOfDb(area)
    scheduler.add_job(
        func=actions[areaOutOfDb.actions[0].name],
        id=str(areaOutOfDb.id),
        trigger='interval',
        seconds=5,
        args=[areaOutOfDb]
    )
    return jsonify(area.serialize()), 200

@areaManagement.route('/delete_area/<int:area_id>', methods=['DELETE'])
@token_required
def delete_area(current_user, area_id):
    area = db.session.query(Area).filter_by(id=area_id, user_id=current_user.id).first()
    if not area:
        return jsonify({"error": "Area not found"}), 404
    for action in area.actions:
        for parameter in action.parameters:
            db.session.delete(parameter)
        for output in action.outputs:
            db.session.delete(output)
        db.session.delete(action)
    for reaction in area.reactions:
        for parameter in reaction.parameters:
            db.session.delete(parameter)
        db.session.delete(reaction)
    db.session.delete(area)
    db.session.commit()
    return jsonify({"message": "Area deleted"}), 200

@areaManagement.route('/area/toggle/<int:area_id>', methods=['PUT'])
@token_required
def toggle_area(current_user, area_id):
    area = db.session.query(Area).filter_by(id=area_id, user_id=current_user.id).first()
    if not area:
        return jsonify({"error": "Area not found"}), 404
    if area.enabled:
        area.enabled = False
        scheduler.remove_job(str(area.id))
        db.session.commit()
        return jsonify({"message": "Area disabled"}), 200
    area.enabled = True
    area.serialize()
    areaOutOfDb = AreaOutOfDb(area)
    scheduler.add_job(
        func=actions[areaOutOfDb.actions[0].name],
        trigger='interval',
        seconds=5,
        id=str(areaOutOfDb.id),
        args=[areaOutOfDb]
    )
    db.session.commit()
    return jsonify({"message": "Area enabled"}), 200

@areaManagement.route('/area/disable/<int:area_id>', methods=['PUT'])
@token_required
def disable_area(current_user, area_id):
    area = db.session.query(Area).filter_by(id=area_id, user_id=current_user.id).first()
    if not area:
        return jsonify({"error": "Area not found"}), 404
    if not area.enabled:
        return jsonify({"message": "Area already disabled"}), 200
    area.enabled = False
    db.session.commit()
    return jsonify({"message": "Area disabled"}), 200

@areaManagement.route('/area/enable/<int:area_id>', methods=['PUT'])
@token_required
def enable_area(current_user, area_id):
    area = db.session.query(Area).filter_by(id=area_id, user_id=current_user.id).first()
    if not area:
        return jsonify({"error": "Area not found"}), 404
    if area.enabled:
        return jsonify({"message": "Area already enabled"}), 200
    area.enabled = True
    area.serialize()
    areaOutOfDb = AreaOutOfDb(area)
    scheduler.add_job(
        func=actions[areaOutOfDb.actions[0].name],
        trigger='interval',
        seconds=5,
        id=str(areaOutOfDb.id),
        args=[areaOutOfDb]
    )
    db.session.commit()
    return jsonify({"message": "Area enabled"}), 200