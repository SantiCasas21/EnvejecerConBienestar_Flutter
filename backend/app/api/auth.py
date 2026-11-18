"""Blueprint de Autenticación."""
import os
import secrets
from flask import Blueprint, request, jsonify
from app.models.usuario import Usuario
from app.extensions import db
from flask_jwt_extended import create_access_token, create_refresh_token, get_jwt_identity, jwt_required
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

bp = Blueprint('auth', __name__)
FIREBASE_PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID', 'envejecerconbienestar-4ffb7')

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
        
    rol_recibido = data.get('rol', 'adulto_mayor')
    rol = 'cuidador' if str(rol_recibido).strip().lower() == 'cuidador' else 'adulto_mayor'
    
    codigo_vinculacion = None
    if rol == 'adulto_mayor':
        codigo_vinculacion = Usuario.generar_codigo_vinculacion()

    nuevo_usuario = Usuario(
        nombre=nombre,
        email=email,
        rol=rol,
        codigo_vinculacion=codigo_vinculacion
    )
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


@bp.route('/google', methods=['POST'])
def google_auth():
    """Autentica o registra un usuario validando su ID Token de Firebase/Google."""
    data = request.get_json(silent=True) or {}
    token = (data.get('id_token') or '').strip()
    if not token:
        return jsonify({"msg": "El token de Google/Firebase es obligatorio."}), 400

    try:
        decoded = google_id_token.verify_firebase_token(
            token,
            google_requests.Request(),
            audience=FIREBASE_PROJECT_ID,
        )
    except Exception:
        return jsonify({"msg": "Token de Google inválido o expirado."}), 401

    email = (decoded.get('email') or '').strip().lower()
    if not email:
        return jsonify({"msg": "La cuenta de Google no proporcionó un correo electrónico."}), 400

    nombre_google = (decoded.get('name') or email.split('@')[0]).strip()
    usuario = Usuario.query.filter_by(email=email).first()
    es_nuevo = False

    if not usuario:
        es_nuevo = True
        rol_recibido = data.get('rol', 'adulto_mayor')
        rol = 'cuidador' if str(rol_recibido).strip().lower() == 'cuidador' else 'adulto_mayor'
        codigo_vinculacion = Usuario.generar_codigo_vinculacion() if rol == 'adulto_mayor' else None

        usuario = Usuario(
            nombre=nombre_google,
            email=email,
            rol=rol,
            codigo_vinculacion=codigo_vinculacion,
        )
        usuario.set_password(secrets.token_urlsafe(32))
        db.session.add(usuario)
        db.session.commit()

    access_token = create_access_token(identity=str(usuario.id))
    refresh_token = create_refresh_token(identity=str(usuario.id))

    return jsonify({
        "msg": "Usuario registrado con Google" if es_nuevo else "Sesión iniciada con Google",
        "es_nuevo": es_nuevo,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "usuario": usuario.to_dict(),
    }), (201 if es_nuevo else 200)
