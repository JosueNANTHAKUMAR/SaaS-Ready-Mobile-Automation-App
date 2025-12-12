from flask import request, jsonify, Blueprint, current_app
from . import User, Service, Area, Action, REAction, ParameterWithValues, ActionWithValues, REActionWithValues, ServiceWithToken
from . import db, scheduler
from .model import AreaOutOfDb
from .triggers import actions
from time import time
from jwt import encode as jwt_encode
from .token import token_required

userManagement = Blueprint('userManagement', __name__)

@userManagement.route('/user/<int:user_id>', methods=['GET'])
@token_required
def get_user(current_user, user_id):
    user = db.session.query(User).filter_by(id=user_id).first()
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user.serialize()), 200

@userManagement.route('/user', methods=['GET'])
@token_required
def get_current_user(current_user):
    return jsonify(current_user.serialize()), 200

@userManagement.route('/register', methods=['POST'])
def register():
    if not request.is_json:
        return jsonify({"error": "Missing JSON in request"}), 400
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    user = db.session.query(User).filter_by(email=email).first()
    if user:
        return jsonify({"error": "Email already linked to an account"}), 400

    new_user = User(email=email)
    new_user.set_password(password)
    # add default services
    print(new_user.serialize())
    db.session.add(new_user)
    db.session.commit()
    services = db.session.query(Service).all()
    for service in services:
        if service.subscribable == False:
            serviceWithToken = ServiceWithToken(service, new_user.id)
            new_user.services.append(serviceWithToken)
    db.session.commit()
    baseArea = Area(name='New year Area', description='New year Area', user_id=new_user.id)
    action = db.session.query(Action).filter_by(name='Jour et heure').first()
    actionWithValues = ActionWithValues(name=action.name, description=action.description, service_id=action.service_id)
    date_param = ParameterWithValues(name='date', type='date', value='2023-12-31')
    time_param = ParameterWithValues(name='time', type='time', value='23:59')
    message_param = ParameterWithValues(name='message', type='string', value='Happy new year!')
    actionWithValues.add_parameter_array([date_param, time_param, message_param])
    baseArea.actions.append(actionWithValues)
    reaction = db.session.query(REAction).filter_by(name='Envoyer un mail').first()
    reactionWithValues = REActionWithValues(name=reaction.name, description=reaction.description, service_id=reaction.service_id)
    to_param = ParameterWithValues(name='to', type='string', value=new_user.email)
    subject_param = ParameterWithValues(name='subject', type='string', value='Happy new year!')
    body_param = ParameterWithValues(name='body', type='string', value='Happy new year!')
    reactionWithValues.add_parameter_array([to_param, subject_param, body_param])
    baseArea.reactions.append(reactionWithValues)
    db.session.add(baseArea)
    db.session.commit()
    baseArea.serialize()
    areaOutOfDb = AreaOutOfDb(baseArea)
    scheduler.add_job(
        func=actions[areaOutOfDb.actions[0].name],
        trigger='interval',
        args=[areaOutOfDb],
        id=str(areaOutOfDb.id),
        seconds=5
    )
    access_token = jwt_encode({'email': new_user.email, 'exp': time() + 86400}, current_app.config['SECRET_KEY'], algorithm="HS256")
    return jsonify({"access_token": access_token}), 200

@userManagement.route('/login', methods=['POST'])
def login():
    if not request.is_json:
        return jsonify({"error": "Missing JSON in request"}), 400
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    user = db.session.query(User).filter_by(email=email).first()
    if not user:
        return jsonify({"error": "Email is not linked to an account"}), 400
    if not user.check_password(password):
        return jsonify({"error": "Incorrect password"}), 400
    access_token = jwt_encode({'email': user.email, 'exp': time() + 86400}, current_app.config['SECRET_KEY'], algorithm="HS256")
    return jsonify({"access_token": access_token}), 200

@userManagement.route('/about.json', methods=['GET'])
def about():
    services = db.session.query(Service).all()

    json = {
        "client": {
            "host": request.remote_addr
        },
        "server": {
            "current_time": round(time()),
            "services": [service.about() for service in services]
        }
    }
    return jsonify(json)

@userManagement.route('/user/services', methods=['GET'])
@token_required
def get_services(current_user):
    services = db.session.query(User).filter_by(id=current_user.id).first().services
    return jsonify([service.serialize() for service in services]), 200

@userManagement.route('/user/services/unsubscribe/<int:service_id>', methods=['DELETE'])
@token_required
def unsubscribe(current_user, service_id):
    service = db.session.query(ServiceWithToken).filter_by(user_id=current_user.id, service_id=service_id).first()
    if not service:
        return jsonify({"error": "Service not found"}), 404
    db.session.delete(service)
    db.session.commit()
    return jsonify({"message": "Service unsubscribed"}), 200
