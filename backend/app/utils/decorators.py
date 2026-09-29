"""Decoradores útiles."""
from functools import wraps
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from flask import jsonify

def require_auth(f):
    """Decorador para requerir autenticación (JWT)."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        verify_jwt_in_request()
        current_user = get_jwt_identity()
        if not current_user:
            return jsonify({"msg": "Acceso denegado"}), 401
        return f(*args, **kwargs)
    return decorated_function
