from flask_apscheduler import APScheduler
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_session import Session
from flask_cors import CORS
from .config import DevConfig, ProdConfig
from .model import AreaOutOfDb
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from os import environ
import requests

db = SQLAlchemy()
sess = Session()
scheduler = APScheduler()

def create_app():
    global db, sess, scheduler
    app = Flask(__name__, instance_relative_config=True)
    CORS(app)
    config = environ.get('FLASK_ENV')
    if config == 'production':
        app.config.from_object(ProdConfig())
    elif config == 'development':
        app.config.from_object(DevConfig())
    else:
        app.logger.error(f"FLASK_ENV is not set to 'production' or 'development'.")
    db.init_app(app)
    scheduler.init_app(app)
    with app.app_context():
        scheduler.start()
        db.create_all()
    sess.init_app(app)
    
    #-----Blueprint registration-----#
    from .users import userManagement
    app.register_blueprint(userManagement)
    from .services import serviceManagement
    app.register_blueprint(serviceManagement)
    from .area import areaManagement
    app.register_blueprint(areaManagement)
    #--------------------------------#
    
    setup_db(app)
    return app

def setup_db(app):
    global db, scheduler
    with app.app_context():
        from .triggers import actions
        if db.session.query(Action).first():
            areas = db.session.query(Area).all()
            for area in areas:
                if area.enabled:
                    actions[area.actions[0].name](area)
                    areaOutOfDb = AreaOutOfDb(area)
                    scheduler.add_job(
                        func=actions[areaOutOfDb.actions[0].name],
                        trigger='interval',
                        args=[areaOutOfDb],
                        id=str(areaOutOfDb.id),
                        seconds=5
                    )
            return

        # mail actions/reactions setup
        mail = db.session.query(Service).filter_by(name='Mail').first()
        mailActions = [
        ]
        mailReactions = [
            REAction(name='Envoyer un mail', description='Envoyer un mail à une adresse mail', service_id=mail.id).add_parameter_array([
                Parameter(name='to', type='string', required=True),
                Parameter(name='subject', type='string', required=True),
                Parameter(name='body', type='string')
            ])
        ]
        for action in mailActions:
            mail.actions.append(action)
        for reaction in mailReactions:
            mail.reactions.append(reaction)
        db.session.commit()
        ######################
        
        # date and time actions/reactions setup
        dateTime = db.session.query(Service).filter_by(name='Heure et date').first()
        dateTimeActions = [
            Action(name='Jour et heure', description='Se déclenche à une date et heure donnée', service_id=dateTime.id).add_parameter_array([
                Parameter(name='Jour', type='date', required=True),
                Parameter(name='Heure', type='time', required=True),
            ]),
            Action(name='Tous les jours à', description='Se déclenche tous les jours à une heure donnée', service_id=dateTime.id).add_parameter_array([
                Parameter(name='Heure', type='time', required=True),
            ]),
            Action(name='Tous les mois à', description='Se déclenche tous les mois à une heure donnée', service_id=dateTime.id).add_parameter_array([
                Parameter(name='Jour', type='integer', required=True),
                Parameter(name='Heure', type='time', required=True),
            ]),
            Action(name='Tous les ans à', description='Se déclenche tous les ans à une heure donnée', service_id=dateTime.id).add_parameter_array([
                Parameter(name='Jour', type='integer', required=True),
                Parameter(name='Mois', type='integer', required=True),
                Parameter(name='Heure', type='time', required=True),
            ])
        ]
        dateTimeReactions = [
        ]
        for action in dateTimeActions:
            dateTime.actions.append(action)
        for reaction in dateTimeReactions:
            dateTime.reactions.append(reaction)
        db.session.commit()
        ######################

        # Space actions/reactions setup
        space = db.session.query(Service).filter_by(name='Espace').first()
        spaceActions = [
            Action(name="Astronaute entre dans l'espace", description="Se déclenche quand un astronaute entre dans l'espace", service_id=space.id),
            Action(name="Astronaute quitte l'espace", description="Se déclenche quand un astronaute quitte l'espace", service_id=space.id),
        ]
        spaceReactions = [
        ]
        for action in spaceActions:
            space.actions.append(action)
        for reaction in spaceReactions:
            space.reactions.append(reaction)
        db.session.commit()

        ######################

        # Spotify actions/reactions setup
        spotify = db.session.query(Service).filter_by(name='Spotify').first()
        spotifyActions = [
            Action(name='Nouvelle playlist', description='Se déclenche quand une nouvelle playlist est créée', service_id=spotify.id),
        ]
        spotifyReactions = [
            REAction(name='Passer à la chanson suivante', description="Passer à la chanson suivante sur l'appareil jouant la musique", service_id=spotify.id),
            REAction(name='Passer à la chanson précédente', description="Passer à la chanson précédente sur l'appareil jouant la musique", service_id=spotify.id),
            REAction(name='Mettre en pause', description="Mettre en pause la chanson sur l'appareil jouant la musique", service_id=spotify.id),
        ]
        for action in spotifyActions:
            spotify.actions.append(action)
        for reaction in spotifyReactions:
            spotify.reactions.append(reaction)
        db.session.commit()

        ######################

        # Discord actions/reactions setup
        discord = db.session.query(Service).filter_by(name='Discord').first()
        discordActions = [
            Action(name='Message discord', description='Nouveau message sur un serveur discord', service_id=discord.id),
        ]
        discordReactions = [
            REAction(name='Envoyer un message', description='Envoyer un message sur un channel (si il n\'existe pas, envoie le message dans le premier channel)', service_id=discord.id).add_parameter_array([
                Parameter(name='channel', type='string', required=True),
                Parameter(name='message', type='string', required=True)
            ])
        ]
        for action in discordActions:
            discord.actions.append(action)
        for reaction in discordReactions:
            discord.reactions.append(reaction)
        db.session.commit()

        ######################

        # dropbox actions/reactions setup
        dropbox = db.session.query(Service).filter_by(name='Dropbox').first()
        dropboxActions = [
            Action(name='Nouveau fichier dropbox', description='Se déclenche quand un nouveau fichier est créé sur dropbox', service_id=dropbox.id),
        ]
        dropboxReactions = [
            REAction(name='Créer un fichier dropbox', description='Créer un fichier sur dropbox', service_id=dropbox.id).add_parameter_array([
                Parameter(name='Nom', type='string', required=True),
                Parameter(name='Contenu', type='string', required=True)
            ])
        ]
        for action in dropboxActions:
            dropbox.actions.append(action)
        for reaction in dropboxReactions:
            dropbox.reactions.append(reaction)
        db.session.commit()
        ######################
        
        # weather actions/reactions setup
        weather = db.session.query(Service).filter_by(name='Météo').first()
        weatherActions = [
            Action(name='Température supérieure à', description='Se déclenche quand la température est supérieure à la température donnée dans une ville', service_id=weather.id).add_parameter_array([
                Parameter(name='Ville', type='string', required=True),
                Parameter(name='Température', type='number', required=True)
            ]),
            Action(name='Humidité supérieure à', description='Se déclenche quand l\'humidité est supérieure à l\'humidité donnée dans une ville', service_id=weather.id).add_parameter_array([
                Parameter(name='Ville', type='string', required=True),
                Parameter(name='Humidité', type='number', required=True)
            ]),
            Action(name='Vitesse du vent supérieure à', description='Se déclenche quand la vitesse du vent est supérieure à la vitesse du vent donnée dans une ville (en km/h)', service_id=weather.id).add_parameter_array([
                Parameter(name='Ville', type='string', required=True),
                Parameter(name='Vitesse', type='number', required=True)
            ]),
        ]
        weatherReactions = [
        ]
        for action in weatherActions:
            weather.actions.append(action)
        for reaction in weatherReactions:
            weather.reactions.append(reaction)
        db.session.commit()
        ######################
        
        # github actions/reactions setup
        github = db.session.query(Service).filter_by(name='Github').first()
        githubActions = [
            Action(name='Nouveau dépôt', description='Se déclenche quand un nouveau dépôt est créé', service_id=github.id),
        ]
        githubReactions = [
            REAction(name='Créer un dépôt', description='Créer un dépôt', service_id=github.id).add_parameter_array([
                Parameter(name='Nom', type='string', required=True),
                Parameter(name='description', type='string')
            ])
        ]
        for action in githubActions:
            github.actions.append(action)
        for reaction in githubReactions:
            github.reactions.append(reaction)
        db.session.commit()
        ######################
        
        # crypto actions/reactions setup
        crypto = db.session.query(Service).filter_by(name='Cryptomonnaie').first()
        cryptoActions = [
            Action(name='Croisement cryptomonnaie', description='Se déclenche quand la cryptomonnaie sélectionné croise le prix donné(uniquement BTC, ETH, BNB, XRP)', service_id=crypto.id).add_parameter_array([
                Parameter(name='Symbole', type='string', required=True),
                Parameter(name='Prix', type='number', required=True),
            ])
        ]
        cryptoReactions = [
        ]
        for action in cryptoActions:
            crypto.actions.append(action)
        for reaction in cryptoReactions:
            crypto.reactions.append(reaction)
        db.session.commit()
        ######################
        
        # forex actions/reactions setup
        forex = db.session.query(Service).filter_by(name='Forex').first()
        forexActions = [
            Action(name='Croisement forex', description='Se déclenche quand la pair de devise sélectionné croise la valeur donné(uniquement EUR, USD, GBP, JPY)', service_id=forex.id).add_parameter_array([
                Parameter(name='Première monnaie', type='string', required=True),
                Parameter(name='Deuxième monnaie', type='string', required=True),
                Parameter(name='Valeur', type='number', required=True),
            ])
        ]
        forexReactions = [
        ]
        for action in forexActions:
            forex.actions.append(action)
        for reaction in forexReactions:
            forex.reactions.append(reaction)
        db.session.commit()
        ######################
        
        # google docs actions/reactions setup
        googleDocs = db.session.query(Service).filter_by(name='Google Docs').first()
        googleDocsActions = [
            Action(name='Nouveau document', description='Se déclenche quand un nouveau document est créé', service_id=googleDocs.id),
        ]
        googleDocsReactions = [
            REAction(name='Créer un document', description='Créer un document', service_id=googleDocs.id).add_parameter_array([
                Parameter(name='Nom', type='string', required=True),
                Parameter(name='Dossier', type='string'),
            ])
        ]
        for action in googleDocsActions:
            googleDocs.actions.append(action)
        for reaction in googleDocsReactions:
            googleDocs.reactions.append(reaction)
        db.session.commit()
        ######################
        
        # create admin user
        services = db.session.query(Service).all()
        admin = User(email='admin@gmail.com')
        admin.set_password('admin')
        db.session.add(admin)
        db.session.commit()
        for service in services:
            if service.subscribable == False:
                serviceWithToken = ServiceWithToken(service, admin.id)
                admin.services.append(serviceWithToken)
        db.session.commit()
        
        # base date and time + mail area setup
        baseArea = Area(name='New year area', description='New year area', user_id=1)
        action = db.session.query(Action).filter_by(name='Jour et heure').first()
        actionWithValues = ActionWithValues(name=action.name, description=action.description, service_id=action.service_id)
        date_param = ParameterWithValues(name='date', type='date', value='2023-12-31')
        time_param = ParameterWithValues(name='time', type='time', value='23:59')
        message_param = ParameterWithValues(name='message', type='string', value='Happy new year!')
        actionWithValues.add_parameter_array([date_param, time_param, message_param])
        baseArea.actions.append(actionWithValues)
        reaction = db.session.query(REAction).filter_by(name='Envoyer un mail').first()
        reactionWithValues = REActionWithValues(name=reaction.name, description=reaction.description, service_id=reaction.service_id)
        to_param = ParameterWithValues(name='to', type='string', value='charles.baux@epitech.eu')
        subject_param = ParameterWithValues(name='subject', type='string', value='Happy new year!')
        body_param = ParameterWithValues(name='body', type='string', value='Happy new year!')
        reactionWithValues.add_parameter_array([to_param, subject_param, body_param])
        baseArea.reactions.append(reactionWithValues)
        db.session.add(baseArea)
        db.session.commit()
        areaOutOfDb = AreaOutOfDb(baseArea)
        scheduler.add_job(
            func=actions[areaOutOfDb.actions[0].name],
            trigger='interval',
            args=[areaOutOfDb],
            id=str(areaOutOfDb.id),
            seconds=5
        )
        print('------------------')
        print([area.serialize() for area in db.session.query(Area).all()])
        ######################
        
        print([service.serialize() for service in services])


class ParameterWithValues(db.Model):
    __tablename__ = 'parameters_with_values'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    value = db.Column(db.String(255), nullable=True)
    type = db.Column(db.String(255), nullable=False)
    
    def __init__(self, name, value, type):
        self.name = name
        self.value = value
        self.type = type
        
    def serialize(self):
        return {
            'name': self.name,
            'value': self.value,
            'type': self.type
        }
        
    def __repr__(self):
        return f"<ParameterWithValues {self.id} {self.name} {self.value} {self.type}>"

class ActionWithValues(db.Model):
    __tablename__ = 'actions_with_values'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    service_id = db.Column(db.Integer, db.ForeignKey('services.id'), nullable=False)
    action_parameters = db.Table('action_with_values_parameters', db.Column('action_id', db.Integer, db.ForeignKey('actions_with_values.id'), primary_key=True), db.Column('parameter_id', db.Integer, db.ForeignKey('parameters_with_values.id'), primary_key=True))
    action_output = db.Table('action_with_values_output', db.Column('action_id', db.Integer, db.ForeignKey('actions_with_values.id'), primary_key=True), db.Column('output_id', db.Integer, db.ForeignKey('outputs.id'), primary_key=True))
    outputs = db.relationship('Output', secondary='action_with_values_output', backref=db.backref('actions_with_values', lazy=True))
    parameters = db.relationship('ParameterWithValues', secondary='action_with_values_parameters', backref=db.backref('actions_with_values', lazy=True))
    
    def __init__(self, name, description, service_id):
        self.name = name
        self.description = description
        self.service_id = service_id
        
    def serialize(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'service_id': self.service_id,
            'parameters': [parameter.serialize() for parameter in self.parameters],
            'outputs': [output.serialize() for output in self.outputs]
        }

    def add_parameter_array(self, parameters):
        for parameter in parameters:
            self.parameters.append(parameter)
        db.session.commit()
        return self
        
    def __repr__(self):
        return f"<ActionWithValues {self.id} {self.name} {self.description}>"

class REActionWithValues(db.Model):
    __tablename__ = 'reactions_with_values'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    service_id = db.Column(db.Integer, db.ForeignKey('services.id'), nullable=False)
    reaction_parameters = db.Table('reaction_with_values_parameters', db.Column('reaction_id', db.Integer, db.ForeignKey('reactions_with_values.id'), primary_key=True), db.Column('parameter_id', db.Integer, db.ForeignKey('parameters_with_values.id'), primary_key=True))
    parameters = db.relationship('ParameterWithValues', secondary='reaction_with_values_parameters', backref=db.backref('reactions_with_values', lazy=True))
    
    def __init__(self, name, description, service_id):
        self.name = name
        self.description = description
        self.service_id = service_id
        
    def serialize(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'service_id': self.service_id,
            'parameters': [parameter.serialize() for parameter in self.parameters]
        }
        
    def add_parameter_array(self, parameters):
        for parameter in parameters:
            self.parameters.append(parameter)
        db.session.commit()
        return self
        
    def __repr__(self):
        return f"<REActionWithValues {self.id} {self.name} {self.description}>"
    
class Area(db.Model):
    __tablename__ = 'areas'
    id = db.Column(db.Integer, primary_key=True)
    enabled = db.Column(db.Boolean, nullable=False, default=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    user = db.relationship('User')
    name = db.Column(db.String(255), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    area_actions = db.Table('area_actions', db.Column('area_id', db.Integer, db.ForeignKey('areas.id'), primary_key=True), db.Column('action_id', db.Integer, db.ForeignKey('actions_with_values.id'), primary_key=True))
    area_reactions = db.Table('area_reactions', db.Column('area_id', db.Integer, db.ForeignKey('areas.id'), primary_key=True), db.Column('reaction_id', db.Integer, db.ForeignKey('reactions_with_values.id'), primary_key=True))
    actions = db.relationship('ActionWithValues', secondary='area_actions', backref=db.backref('areas', lazy=True))
    reactions = db.relationship('REActionWithValues', secondary='area_reactions', backref=db.backref('areas', lazy=True))
    
    def __init__(self, name, description, user_id, enabled=True):
        self.name = name
        self.enabled = enabled
        self.description = description
        self.user_id = user_id
        self.user = db.session.query(User).filter_by(id=user_id).first()
        
    def serialize(self):
        return {
            'id': self.id,
            'user': self.user.serialize(),
            'enabled': self.enabled,
            'name': self.name,
            'description': self.description,
            'user_id': self.user_id,
            'actions': [action.serialize() for action in self.actions],
            'reactions': [reaction.serialize() for reaction in self.reactions]
        }
        
    def add_action_array(self, actions):
        for action in actions:
            self.actions.append(action)
        db.session.commit()
        return self

    def add_reaction_array(self, reactions):
        for reaction in reactions:
            self.reactions.append(reaction)
        db.session.commit()
        return self
    
    def disable(self):
        response = requests.post(
            url='http://localhost:5000/login',
            json={
                'email': 'admin@gmail.com',
                'password': 'admin'
            }
        )
        token = response.json().get('access_token')
        response = requests.put(
            url='http://localhost:5000/area/disable/' + str(self.id),
            headers={
                "x-access-tokens": token
            }
        )
        print(response.json())
        return self
        
    def __repr__(self):
        return f"<Area {self.id} {self.name} {self.description}>"    

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), nullable=False, unique=True)
    password = db.Column(db.String(255), nullable=False)
    user_services = db.Table('user_services', db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True), db.Column('service_id', db.Integer, db.ForeignKey('services_with_token.id'), primary_key=True))
    services = db.relationship('ServiceWithToken', secondary='user_services', backref=db.backref('users', lazy=True))
    
    def __init__(self, email):
        self.email = email
        
    def serialize(self):
        return {
            'id': self.id,
            'email': self.email,
            'services': [service.serialize() for service in self.services]
        }
    
    def set_password(self, password):
        self.password = generate_password_hash(password, method='scrypt')
        
    def check_password(self, password):
        return check_password_hash(self.password, password)
    
    def __repr__(self):
        return f"<User {self.id}: {self.email}>"
    
class ServiceWithToken(db.Model):
    __tablename__ = 'services_with_token'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    color = db.Column(db.String(255), nullable=False)
    icon = db.Column(db.String(255), nullable=False)
    token = db.Column(db.String(510), nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    service_id = db.Column(db.Integer, db.ForeignKey('services.id'), nullable=False)
    subscribable = db.Column(db.Boolean, nullable=False, default=False)
    service_with_token_reactions = db.Table('service_with_token_reactions', db.Column('service_with_token_id', db.Integer, db.ForeignKey('services_with_token.id'), primary_key=True), db.Column('reaction_id', db.Integer, db.ForeignKey('reactions.id'), primary_key=True))
    service_with_token_actions = db.Table('service_with_token_actions', db.Column('service_with_token_id', db.Integer, db.ForeignKey('services_with_token.id'), primary_key=True), db.Column('action_id', db.Integer, db.ForeignKey('actions.id'), primary_key=True))
    actions = db.relationship('Action', secondary='service_with_token_actions', backref=db.backref('services_with_token', lazy=True))
    reactions = db.relationship('REAction', secondary='service_with_token_reactions', backref=db.backref('services_with_token', lazy=True))

    def __init__(self, service, user_id):
        self.name = service.name
        self.color = service.color
        self.icon = service.icon
        self.token = ''
        self.user_id = user_id
        self.subscribable = service.subscribable
        self.service_id = service.id
        db.session.add(self)
        db.session.commit()
        self.set_actions(service.actions)
        self.set_reactions(service.reactions)
        
    def set_reactions(self, reactions):
        for reaction in reactions:
            self.reactions.append(reaction)
        db.session.commit()
        return self
    
    def set_actions(self, actions):
        for action in actions:
            self.actions.append(action)
        db.session.commit()
        return self
    
    def set_token(self, token):
        self.token = token
        db.session.commit()
        return self

    def serialize(self):
        return {
            'service_id': self.service_id,
            'subscribable': self.subscribable,
            'name': self.name,
            'color': self.color,
            'icon': self.icon,
            'actions': [action.serialize() for action in self.actions],
            'reactions': [reaction.serialize() for reaction in self.reactions]
        }

    def __repr__(self):
        return f"<Service {self.id}: {self.name}>"

class Service(db.Model):
    __tablename__ = 'services'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False, unique=True)
    color = db.Column(db.String(255), nullable=False)
    icon = db.Column(db.String(255), nullable=False)
    subscribable = db.Column(db.Boolean, nullable=False, default=False)
    service_reactions = db.Table('service_reactions', db.Column('service_id', db.Integer, db.ForeignKey('services.id'), primary_key=True), db.Column('reaction_id', db.Integer, db.ForeignKey('reactions.id'), primary_key=True))
    service_actions = db.Table('service_actions', db.Column('service_id', db.Integer, db.ForeignKey('services.id'), primary_key=True), db.Column('action_id', db.Integer, db.ForeignKey('actions.id'), primary_key=True))
    actions = db.relationship('Action', secondary='service_actions', backref=db.backref('services', lazy=True))
    reactions = db.relationship('REAction', secondary='service_reactions', backref=db.backref('services', lazy=True))

    def __init__(self, name, color, icon, subscribable=False):
        self.name = name
        self.color = color
        self.icon = icon
        self.subscribable = subscribable

    def serialize(self):
        return {
            'id': self.id,
            'subscribable': self.subscribable,
            'name': self.name,
            'color': self.color,
            'icon': self.icon,
            'actions': [action.serialize() for action in self.actions],
            'reactions': [reaction.serialize() for reaction in self.reactions]
        }
        
    def about(self):
        return {
            'name': self.name,
            'subscribable': self.subscribable,
            'actions': [action.about() for action in self.actions],
            'reactions': [reaction.about() for reaction in self.reactions]
        }
        
    def __repr__(self):
        return f"<Service {self.id}: {self.name}>"
    
class Action(db.Model):
    __tablename__ = 'actions'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    service_id = db.Column(db.Integer, db.ForeignKey('services.id'), nullable=False)
    action_parameters = db.Table('action_parameters', db.Column('action_id', db.Integer, db.ForeignKey('actions.id'), primary_key=True), db.Column('parameter_id', db.Integer, db.ForeignKey('parameters.id'), primary_key=True))
    action_outputs = db.Table('action_outputs', db.Column('action_id', db.Integer, db.ForeignKey('actions.id'), primary_key=True), db.Column('output_id', db.Integer, db.ForeignKey('outputs.id'), primary_key=True))
    parameters = db.relationship('Parameter', secondary='action_parameters', backref=db.backref('actions', lazy=True))
    outputs = db.relationship('Output', secondary='action_outputs', backref=db.backref('actions', lazy=True))

    def __init__(self, name, description, service_id):
        self.name = name
        self.description = description
        self.service_id = service_id
        
    def serialize(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'service_id': self.service_id,
            'outputs': [output.serialize() for output in self.outputs],
            'parameters': [parameter.serialize() for parameter in self.parameters]
        }
        
    def add_parameter_array(self, parameters):
        for parameter in parameters:
            self.parameters.append(parameter)
        db.session.commit()
        return self
        
    def about(self):
        return {
            'name': self.name,
            'description': self.description,
            'parameters': [parameter.serialize() for parameter in self.parameters]
        }
    
    def __repr__(self):
        return f"<Action {self.id}: {self.name}>"
    
class Output(db.Model):
    __tablename__ = 'outputs'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    type = db.Column(db.String(100), nullable=False)
    
    def __init__(self, name, type):
        self.name = name
        self.type = type
        
    def serialize(self):
        return {
            'name': self.name,
            'type': self.type
        }
        
    def __repr__(self):
        return f"<Output \"{self.name}\" of type {self.type}>"
    
class REAction(db.Model):
    __tablename__ = 'reactions'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(100), nullable=False)
    service_id = db.Column(db.Integer, db.ForeignKey('services.id'), nullable=False)
    reaction_parameters = db.Table('reaction_parameters', db.Column('reaction_id', db.Integer, db.ForeignKey('reactions.id'), primary_key=True), db.Column('parameter_id', db.Integer, db.ForeignKey('parameters.id'), primary_key=True))
    parameters = db.relationship('Parameter', secondary='reaction_parameters', backref=db.backref('reactions', lazy=True))

    def __init__(self, name, description, service_id):
        self.name = name
        self.description = description
        self.service_id = service_id

    def serialize(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'service_id': self.service_id,
            'parameters': [parameter.serialize() for parameter in self.parameters]
        }
        
    def about(self):
        return {
            'name': self.name,
            'description': self.description,
            'parameters': [parameter.serialize() for parameter in self.parameters]
        }
        
    def add_parameter_array(self, parameters):
        for parameter in parameters:
            self.parameters.append(parameter)
        db.session.commit()
        return self
    
    def __repr__(self):
        return f"<Reaction {self.id}: {self.name}>"
    
class Parameter(db.Model):
    __tablename__ = 'parameters'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    type = db.Column(db.String(100), nullable=False)
    required = db.Column(db.Boolean, nullable=False, default=False)
    
    def __init__(self, name, type, required=False):
        self.name = name
        self.type = type
        self.required = required
        
    def serialize(self):
        return {
            'name': self.name,
            'type': self.type,
            'required': self.required
        }
        
    def __repr__(self):
        return f"<Parameter \"{self.name}\" of type {self.type}>" # type: ignore