from jwt import decode as jwt_decode
from functools import wraps
from flask import request, jsonify, current_app
from . import User
from time import time

def token_required(f):
    @wraps(f)
    def decorator(*args, **kwargs):
        token = None
        
        if 'x-access-tokens' in request.headers:
            token = request.headers['x-access-tokens']
        if not token:
            return jsonify({'message': 'Token is missing'}), 401
        try:
            data = jwt_decode(token, current_app.config['SECRET_KEY'], algorithms=["HS256"])
            if data['exp'] < time():
                return jsonify({'message': 'Token has expired'}), 401
            current_user = User.query.filter_by(email=data['email']).first()
        except:
            return jsonify({'message': 'Token is invalid'}), 401
        return f(current_user, *args, **kwargs)
    return decorator