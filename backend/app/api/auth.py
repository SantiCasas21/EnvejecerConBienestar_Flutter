"""Blueprint de Autenticación."""
from flask import Blueprint, request, jsonify
from app.models.usuario import Usuario
from app.extensions import db
from flask_jwt_extended import create_access_token, create_refresh_token, get_jwt_identity, jwt_required

bp = Blueprint('auth', __name__)

@bp.route('/register', methods=['POST'])
def register():
    """Registra un nuevo usuario y retorna tokens directos."""
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password') or not data.get('nombre'):
        return jsonify({"msg": "Por favor completa todos los campos requeridos."}), 400
        
    email = data['email'].strip().lower()
    nombre = data['nombre'].strip()
    password = data['password']

    if len(password) < 6:
        return jsonify({"msg": "La contraseña debe tener al menos 6 caracteres."}), 400

    if Usuario.query.filter_by(email=email).first():
        return jsonify({"msg": "Ya existe una cuenta con este correo electrónico."}), 409
        
    nuevo_usuario = Usuario(nombre=nombre, email=email)
    nuevo_usuario.set_password(password)
    
    db.session.add(nuevo_usuario)
    db.session.commit()

    access_token = create_access_token(identity=str(nuevo_usuario.id))
    refresh_token = create_refresh_token(identity=str(nuevo_usuario.id))
    
    return jsonify({
        "msg": "Usuario registrado exitosamente",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "usuario": nuevo_usuario.to_dict()
    }), 201

@bp.route('/login', methods=['POST'])
def login():
    """Inicia sesión y obtiene tokens."""
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"msg": "Por favor ingresa tu correo y contraseña."}), 400
        
    email = data['email'].strip().lower()
    password = data['password']

    usuario = Usuario.query.filter_by(email=email).first()
    
    if not usuario or not usuario.check_password(password):
        return jsonify({"msg": "Correo electrónico o contraseña incorrectos."}), 401
        
    access_token = create_access_token(identity=str(usuario.id))
    refresh_token = create_refresh_token(identity=str(usuario.id))
    
    return jsonify({
        "access_token": access_token,
        "refresh_token": refresh_token,
        "usuario": usuario.to_dict()
    }), 200

@bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Refresca el token de acceso."""
    current_user_id = get_jwt_identity()
    new_access_token = create_access_token(identity=current_user_id)
    return jsonify({"access_token": new_access_token}), 200

@bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Obtiene la información del usuario autenticado actual."""
    usuario_id = int(get_jwt_identity())
    usuario = Usuario.query.get(usuario_id)
    if not usuario:
        return jsonify({"msg": "Usuario no encontrado"}), 404
        
    return jsonify({
        "usuario": usuario.to_dict()
    }), 200
