from os import environ, path
from redis import from_url
from datetime import timedelta

basedir = path.abspath(path.dirname(__file__))

class Config(object):
    ROOT_PATH = basedir
    SECRET_KEY = environ.get('SECRET_KEY') or 'you-will-never-guess'
    SQLALCHEMY_DATABASE_URI = environ.get('DATABASE_URL') or \
        'sqlite:///' + path.join(basedir, 'app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    SESSION_TYPE = 'redis'
    SESSION_KEY_PREFIX = 'flask_'
    PERMANENT_SESSION_LIFETIME = timedelta(days=1)
    SESSION_PERMANENT = False
    SESSION_USE_SIGNER = True
    SESSION_REDIS = from_url(f"{environ.get('REDIS_URL')}")
    
class ProdConfig(Config):
    DEBUG = False
    TESTING = False
    LOGIN_DISABLED = False
    
class DevConfig(Config):
    DEBUG = True
    TESTING = True
    LOGIN_DISABLED = False