import os
import json

base_dir = r"c:\Users\Santiago\OneDrive\Documentos\Santiago\Proyectos\envejecer_con_bienestar_flutter\backend"

directories = [
    "app",
    "app/models",
    "app/schemas",
    "app/services",
    "app/utils",
    "app/api",
    "tests"
]

for d in directories:
    os.makedirs(os.path.join(base_dir, d), exist_ok=True)

files = {}

files["requirements.txt"] = """Flask==3.1.1
Flask-SQLAlchemy==3.1.1
Flask-Migrate==4.1.0
Flask-JWT-Extended==4.7.1
Flask-CORS==5.0.1
flask-marshmallow==1.2.1
marshmallow-sqlalchemy==1.1.0
python-dotenv==1.0.1
gunicorn==23.0.0
Werkzeug==3.1.3
pytest==8.3.4
"""

files[".env.example"] = """FLASK_ENV=development
DATABASE_URL=sqlite:///app.db
JWT_SECRET_KEY=super-secret-key-change-me
"""

files["config.py"] = """\"\"\"Configuración de la aplicación Flask.\"\"\"
import os
from datetime import timedelta

class Config:
    \"\"\"Configuración base.\"\"\"
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'jwt-dev-secret-key'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

class DevelopmentConfig(Config):
    \"\"\"Configuración de desarrollo.\"\"\"
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///app.db'

class TestingConfig(Config):
    \"\"\"Configuración de pruebas.\"\"\"
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    WTF_CSRF_ENABLED = False

class ProductionConfig(Config):
    \"\"\"Configuración de producción.\"\"\"
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///prod.db'
"""

files["app/__init__.py"] = """\"\"\"Factory de la aplicación Flask.\"\"\"
from flask import Flask
from config import DevelopmentConfig, TestingConfig, ProductionConfig
from app.extensions import db, migrate, jwt, cors, ma
from app.utils.error_handlers import register_error_handlers
from app.api import register_blueprints
import os

def create_app(config_class=DevelopmentConfig) -> Flask:
    \"\"\"Crea y configura la aplicación Flask.\"\"\"
    app = Flask(__name__)
    
    env = os.environ.get('FLASK_ENV', 'development')
    if env == 'production':
        app.config.from_object(ProductionConfig)
    elif env == 'testing':
        app.config.from_object(TestingConfig)
    else:
        app.config.from_object(config_class)

    # Inicializar extensiones
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    cors.init_app(app)
    ma.init_app(app)

    # Registrar manejadores de errores y blueprints
    register_error_handlers(app)
    register_blueprints(app)

    return app
"""

files["app/extensions.py"] = """\"\"\"Extensiones de Flask para evitar dependencias circulares.\"\"\"
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_marshmallow import Marshmallow

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
cors = CORS()
ma = Marshmallow()
"""

files["app/models/__init__.py"] = """\"\"\"Módulo de modelos.\"\"\"
from .usuario import Usuario
from .medicamento import Medicamento
from .contacto import Contacto
from .habito import Habito
from .actividad_cognitiva import ActividadCognitiva
"""

files["app/models/usuario.py"] = """\"\"\"Modelo de Usuario.\"\"\"
from app.extensions import db
from datetime import datetime, timezone
from werkzeug.security import generate_password_hash, check_password_hash

class Usuario(db.Model):
    \"\"\"Entidad de Usuario en la base de datos.\"\"\"
    __tablename__ = 'usuarios'
    
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relaciones
    medicamentos = db.relationship('Medicamento', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')
    contactos = db.relationship('Contacto', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')
    habitos = db.relationship('Habito', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')
    actividades_cognitivas = db.relationship('ActividadCognitiva', backref='usuario', lazy='dynamic', cascade='all, delete-orphan')

    def set_password(self, password: str) -> None:
        \"\"\"Hashea y guarda la contraseña.\"\"\"
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        \"\"\"Verifica si la contraseña dada coincide con el hash.\"\"\"
        return check_password_hash(self.password_hash, password)
"""

files["app/models/medicamento.py"] = """\"\"\"Modelo de Medicamento.\"\"\"
from app.extensions import db
from datetime import datetime, timezone

class Medicamento(db.Model):
    \"\"\"Entidad de Medicamento en la base de datos.\"\"\"
    __tablename__ = 'medicamentos'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    nombre = db.Column(db.String(100), nullable=False)
    miligramos = db.Column(db.String(50))
    notas = db.Column(db.Text)
    frecuencia = db.Column(db.Integer)  # en horas
    hora_alarma = db.Column(db.Time)
    esta_tomado = db.Column(db.Boolean, default=False)
    icono = db.Column(db.String(20), default='💊')
    fecha_inicio = db.Column(db.Date)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
"""

files["app/models/contacto.py"] = """\"\"\"Modelo de Contacto.\"\"\"
from app.extensions import db
from datetime import datetime, timezone

class Contacto(db.Model):
    \"\"\"Entidad de Contacto en la base de datos.\"\"\"
    __tablename__ = 'contactos'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    nombre = db.Column(db.String(100), nullable=False)
    telefono = db.Column(db.String(20), nullable=False)
    ubicacion = db.Column(db.String(200))
    categoria = db.Column(db.String(50), default='Familia/Amigos')
    icono = db.Column(db.String(20), default='👤')
    es_favorito = db.Column(db.Boolean, default=False)
    es_emergencia = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
"""

files["app/models/habito.py"] = """\"\"\"Modelo de Habito.\"\"\"
from app.extensions import db
from datetime import datetime, timezone

class Habito(db.Model):
    \"\"\"Entidad de Habito en la base de datos.\"\"\"
    __tablename__ = 'habitos'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    tipo = db.Column(db.String(50), nullable=False)
    meta = db.Column(db.Integer, nullable=False)
    progreso_actual = db.Column(db.Integer, default=0)
    fecha = db.Column(db.Date, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    @property
    def porcentaje(self) -> float:
        \"\"\"Calcula el porcentaje de progreso del hábito.\"\"\"
        if self.meta == 0:
            return 0.0
        return min((self.progreso_actual / self.meta) * 100, 100.0)
"""

files["app/models/actividad_cognitiva.py"] = """\"\"\"Modelo de Actividad Cognitiva (Juegos).\"\"\"
from app.extensions import db
from datetime import datetime, timezone

class ActividadCognitiva(db.Model):
    \"\"\"Entidad de Actividad Cognitiva en la base de datos.\"\"\"
    __tablename__ = 'actividades_cognitivas'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    tipo_juego = db.Column(db.String(50), nullable=False)
    puntaje = db.Column(db.Integer, nullable=False)
    fecha_realizacion = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
"""

files["app/schemas/__init__.py"] = """\"\"\"Módulo de esquemas de serialización.\"\"\"
from .medicamento_schema import MedicamentoSchema, MedicamentoCreateSchema
from .contacto_schema import ContactoSchema
from .habito_schema import HabitoSchema
from .actividad_cognitiva_schema import ActividadCognitivaSchema
"""

files["app/schemas/medicamento_schema.py"] = """\"\"\"Esquemas para Medicamento.\"\"\"
from app.extensions import ma
from app.models.medicamento import Medicamento
from marshmallow import fields, validate

class MedicamentoSchema(ma.SQLAlchemyAutoSchema):
    \"\"\"Esquema completo de Medicamento.\"\"\"
    class Meta:
        model = Medicamento
        include_fk = True
        load_instance = True

class MedicamentoCreateSchema(ma.Schema):
    \"\"\"Esquema para validar creación de Medicamento.\"\"\"
    nombre = fields.String(required=True, validate=validate.Length(min=1, max=100))
    miligramos = fields.String(validate=validate.Length(max=50), missing=None)
    notas = fields.String(missing=None)
    frecuencia = fields.Integer(missing=None)
    hora_alarma = fields.Time(missing=None)
    esta_tomado = fields.Boolean(missing=False)
    icono = fields.String(validate=validate.Length(max=20), missing='💊')
    fecha_inicio = fields.Date(missing=None)
"""

files["app/schemas/contacto_schema.py"] = """\"\"\"Esquemas para Contacto.\"\"\"
from app.extensions import ma
from app.models.contacto import Contacto

class ContactoSchema(ma.SQLAlchemyAutoSchema):
    \"\"\"Esquema completo de Contacto.\"\"\"
    class Meta:
        model = Contacto
        include_fk = True
        load_instance = True
"""

files["app/schemas/habito_schema.py"] = """\"\"\"Esquemas para Habito.\"\"\"
from app.extensions import ma
from app.models.habito import Habito
from marshmallow import fields

class HabitoSchema(ma.SQLAlchemyAutoSchema):
    \"\"\"Esquema completo de Habito.\"\"\"
    class Meta:
        model = Habito
        include_fk = True
        load_instance = True
    
    porcentaje = fields.Float(dump_only=True)
"""

files["app/schemas/actividad_cognitiva_schema.py"] = """\"\"\"Esquemas para Actividad Cognitiva.\"\"\"
from app.extensions import ma
from app.models.actividad_cognitiva import ActividadCognitiva

class ActividadCognitivaSchema(ma.SQLAlchemyAutoSchema):
    \"\"\"Esquema completo de Actividad Cognitiva.\"\"\"
    class Meta:
        model = ActividadCognitiva
        include_fk = True
        load_instance = True
"""

files["app/services/__init__.py"] = """\"\"\"Módulo de servicios.\"\"\"
from .medicamento_service import MedicamentoService
from .contacto_service import ContactoService
from .habito_service import HabitoService
from .juego_service import JuegoService
"""

files["app/services/medicamento_service.py"] = """\"\"\"Servicio de Medicamentos.\"\"\"
from app.models.medicamento import Medicamento
from app.extensions import db
from typing import List, Optional, Dict, Any

class MedicamentoService:
    \"\"\"Servicios para la entidad Medicamento.\"\"\"

    @staticmethod
    def get_all(usuario_id: int) -> List[Medicamento]:
        \"\"\"Obtiene todos los medicamentos de un usuario.\"\"\"
        return Medicamento.query.filter_by(usuario_id=usuario_id).all()

    @staticmethod
    def get_by_id(id: int, usuario_id: int) -> Optional[Medicamento]:
        \"\"\"Obtiene un medicamento específico por ID y usuario.\"\"\"
        return Medicamento.query.filter_by(id=id, usuario_id=usuario_id).first()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Medicamento:
        \"\"\"Crea un nuevo medicamento.\"\"\"
        medicamento = Medicamento(usuario_id=usuario_id, **data)
        db.session.add(medicamento)
        db.session.commit()
        return medicamento

    @staticmethod
    def update(id: int, data: Dict[str, Any], usuario_id: int) -> Optional[Medicamento]:
        \"\"\"Actualiza un medicamento existente.\"\"\"
        medicamento = MedicamentoService.get_by_id(id, usuario_id)
        if not medicamento:
            return None
        
        for key, value in data.items():
            if hasattr(medicamento, key):
                setattr(medicamento, key, value)
                
        db.session.commit()
        return medicamento

    @staticmethod
    def delete(id: int, usuario_id: int) -> bool:
        \"\"\"Elimina un medicamento.\"\"\"
        medicamento = MedicamentoService.get_by_id(id, usuario_id)
        if not medicamento:
            return False
            
        db.session.delete(medicamento)
        db.session.commit()
        return True

    @staticmethod
    def toggle_tomado(id: int, usuario_id: int) -> Optional[Medicamento]:
        \"\"\"Alterna el estado de 'esta_tomado' del medicamento.\"\"\"
        medicamento = MedicamentoService.get_by_id(id, usuario_id)
        if not medicamento:
            return None
            
        medicamento.esta_tomado = not medicamento.esta_tomado
        db.session.commit()
        return medicamento
"""

files["app/services/contacto_service.py"] = """\"\"\"Servicio de Contactos.\"\"\"
from app.models.contacto import Contacto
from app.extensions import db
from typing import List, Optional, Dict, Any

class ContactoService:
    \"\"\"Servicios para la entidad Contacto.\"\"\"

    @staticmethod
    def get_all(usuario_id: int) -> List[Contacto]:
        \"\"\"Obtiene todos los contactos de un usuario.\"\"\"
        return Contacto.query.filter_by(usuario_id=usuario_id).all()

    @staticmethod
    def get_by_id(id: int, usuario_id: int) -> Optional[Contacto]:
        \"\"\"Obtiene un contacto específico.\"\"\"
        return Contacto.query.filter_by(id=id, usuario_id=usuario_id).first()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Contacto:
        \"\"\"Crea un nuevo contacto.\"\"\"
        contacto = Contacto(usuario_id=usuario_id, **data)
        db.session.add(contacto)
        db.session.commit()
        return contacto

    @staticmethod
    def update(id: int, data: Dict[str, Any], usuario_id: int) -> Optional[Contacto]:
        \"\"\"Actualiza un contacto.\"\"\"
        contacto = ContactoService.get_by_id(id, usuario_id)
        if not contacto:
            return None
            
        for key, value in data.items():
            if hasattr(contacto, key):
                setattr(contacto, key, value)
                
        db.session.commit()
        return contacto

    @staticmethod
    def delete(id: int, usuario_id: int) -> bool:
        \"\"\"Elimina un contacto.\"\"\"
        contacto = ContactoService.get_by_id(id, usuario_id)
        if not contacto:
            return False
            
        db.session.delete(contacto)
        db.session.commit()
        return True

    @staticmethod
    def get_emergencia(usuario_id: int) -> List[Contacto]:
        \"\"\"Obtiene los contactos de emergencia de un usuario.\"\"\"
        return Contacto.query.filter_by(usuario_id=usuario_id, es_emergencia=True).all()
"""

files["app/services/habito_service.py"] = """\"\"\"Servicio de Habitos.\"\"\"
from app.models.habito import Habito
from app.extensions import db
from datetime import date
from typing import List, Optional, Dict, Any

class HabitoService:
    \"\"\"Servicios para la entidad Habito.\"\"\"

    @staticmethod
    def get_by_fecha(usuario_id: int, fecha: date) -> List[Habito]:
        \"\"\"Obtiene los hábitos de un usuario para una fecha específica.\"\"\"
        return Habito.query.filter_by(usuario_id=usuario_id, fecha=fecha).all()

    @staticmethod
    def create(data: Dict[str, Any], usuario_id: int) -> Habito:
        \"\"\"Crea un nuevo hábito.\"\"\"
        habito = Habito(usuario_id=usuario_id, **data)
        db.session.add(habito)
        db.session.commit()
        return habito

    @staticmethod
    def actualizar_progreso(id: int, valor: int, usuario_id: int) -> Optional[Habito]:
        \"\"\"Actualiza el progreso de un hábito.\"\"\"
        habito = Habito.query.filter_by(id=id, usuario_id=usuario_id).first()
        if not habito:
            return None
            
        habito.progreso_actual = valor
        db.session.commit()
        return habito

    @staticmethod
    def inicializar_habitos_default(usuario_id: int, fecha: date) -> List[Habito]:
        \"\"\"Inicializa hábitos por defecto para un nuevo usuario en una fecha.\"\"\"
        habitos_default = [
            {"tipo": "Agua", "meta": 8, "progreso_actual": 0},
            {"tipo": "Caminata", "meta": 30, "progreso_actual": 0}
        ]
        
        creados = []
        for h in habitos_default:
            habito = Habito(usuario_id=usuario_id, fecha=fecha, **h)
            db.session.add(habito)
            creados.append(habito)
            
        db.session.commit()
        return creados
"""

files["app/services/juego_service.py"] = """\"\"\"Servicio de Juegos (Actividad Cognitiva).\"\"\"
from app.models.actividad_cognitiva import ActividadCognitiva
from app.extensions import db
from typing import List, Dict, Any

class JuegoService:
    \"\"\"Servicios para las actividades cognitivas.\"\"\"

    @staticmethod
    def guardar_puntaje(data: Dict[str, Any], usuario_id: int) -> ActividadCognitiva:
        \"\"\"Guarda el puntaje de un juego.\"\"\"
        actividad = ActividadCognitiva(usuario_id=usuario_id, **data)
        db.session.add(actividad)
        db.session.commit()
        return actividad

    @staticmethod
    def get_historial(usuario_id: int) -> List[ActividadCognitiva]:
        \"\"\"Obtiene el historial de puntajes de un usuario.\"\"\"
        return ActividadCognitiva.query.filter_by(usuario_id=usuario_id).order_by(ActividadCognitiva.fecha_realizacion.desc()).all()
"""

files["app/utils/__init__.py"] = """\"\"\"Módulo de utilidades.\"\"\"
"""

files["app/utils/error_handlers.py"] = """\"\"\"Manejadores de errores globales.\"\"\"
from flask import Flask, jsonify

def register_error_handlers(app: Flask) -> None:
    \"\"\"Registra los manejadores de errores en la aplicación.\"\"\"
    
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({"msg": "Petición incorrecta"}), 400

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"msg": "Recurso no encontrado"}), 404

    @app.errorhandler(422)
    def unprocessable_entity(error):
        return jsonify({"msg": "Entidad no procesable, validación fallida"}), 422

    @app.errorhandler(500)
    def internal_server_error(error):
        return jsonify({"msg": "Error interno del servidor"}), 500
"""

files["app/utils/decorators.py"] = """\"\"\"Decoradores útiles.\"\"\"
from functools import wraps
from flask_jwt_extended import get_jwt_identity, verify_jwt_in_request
from flask import jsonify

def require_auth(f):
    \"\"\"Decorador para requerir autenticación (JWT).\"\"\"
    @wraps(f)
    def decorated_function(*args, **kwargs):
        verify_jwt_in_request()
        current_user = get_jwt_identity()
        if not current_user:
            return jsonify({"msg": "Acceso denegado"}), 401
        return f(*args, **kwargs)
    return decorated_function
"""

files["app/api/__init__.py"] = """\"\"\"Módulo de Blueprints de la API.\"\"\"
from flask import Flask
from .auth import bp as auth_bp
from .medicamentos import bp as medicamentos_bp
from .contactos import bp as contactos_bp
from .habitos import bp as habitos_bp
from .juegos import bp as juegos_bp

def register_blueprints(app: Flask) -> None:
    \"\"\"Registra todos los blueprints en la aplicación.\"\"\"
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(medicamentos_bp, url_prefix='/api/medicamentos')
    app.register_blueprint(contactos_bp, url_prefix='/api/contactos')
    app.register_blueprint(habitos_bp, url_prefix='/api/habitos')
    app.register_blueprint(juegos_bp, url_prefix='/api/juegos')
"""

files["app/api/auth.py"] = """\"\"\"Blueprint de Autenticación.\"\"\"
from flask import Blueprint, request, jsonify
from app.models.usuario import Usuario
from app.extensions import db
from flask_jwt_extended import create_access_token, create_refresh_token, get_jwt_identity, jwt_required

bp = Blueprint('auth', __name__)

@bp.route('/register', methods=['POST'])
def register():
    \"\"\"Registra un nuevo usuario.\"\"\"
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password') or not data.get('nombre'):
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    if Usuario.query.filter_by(email=data['email']).first():
        return jsonify({"msg": "El usuario ya existe"}), 400
        
    nuevo_usuario = Usuario(nombre=data['nombre'], email=data['email'])
    nuevo_usuario.set_password(data['password'])
    
    db.session.add(nuevo_usuario)
    db.session.commit()
    
    return jsonify({"msg": "Usuario registrado exitosamente"}), 201

@bp.route('/login', methods=['POST'])
def login():
    \"\"\"Inicia sesión y obtiene tokens.\"\"\"
    data = request.get_json()
    
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"msg": "Faltan credenciales"}), 400
        
    usuario = Usuario.query.filter_by(email=data['email']).first()
    
    if not usuario or not usuario.check_password(data['password']):
        return jsonify({"msg": "Credenciales inválidas"}), 401
        
    access_token = create_access_token(identity=str(usuario.id))
    refresh_token = create_refresh_token(identity=str(usuario.id))
    
    return jsonify({
        "access_token": access_token,
        "refresh_token": refresh_token,
        "usuario": {
            "id": usuario.id,
            "nombre": usuario.nombre,
            "email": usuario.email
        }
    }), 200

@bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    \"\"\"Refresca el token de acceso.\"\"\"
    current_user_id = get_jwt_identity()
    new_access_token = create_access_token(identity=current_user_id)
    return jsonify({"access_token": new_access_token}), 200
"""

files["app/api/medicamentos.py"] = """\"\"\"Blueprint de Medicamentos.\"\"\"
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.medicamento_service import MedicamentoService
from app.schemas.medicamento_schema import MedicamentoSchema, MedicamentoCreateSchema

bp = Blueprint('medicamentos', __name__)
schema_many = MedicamentoSchema(many=True)
schema_one = MedicamentoSchema()
create_schema = MedicamentoCreateSchema()

@bp.route('', methods=['GET'])
@jwt_required()
def get_medicamentos():
    \"\"\"Obtiene todos los medicamentos del usuario.\"\"\"
    usuario_id = int(get_jwt_identity())
    medicamentos = MedicamentoService.get_all(usuario_id)
    return jsonify(schema_many.dump(medicamentos)), 200

@bp.route('', methods=['POST'])
@jwt_required()
def create_medicamento():
    \"\"\"Crea un nuevo medicamento.\"\"\"
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    errors = create_schema.validate(data)
    if errors:
        return jsonify({"msg": "Error de validación", "errores": errors}), 400
        
    medicamento = MedicamentoService.create(data, usuario_id)
    return jsonify(schema_one.dump(medicamento)), 201

@bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def get_medicamento(id):
    \"\"\"Obtiene un medicamento por ID.\"\"\"
    usuario_id = int(get_jwt_identity())
    medicamento = MedicamentoService.get_by_id(id, usuario_id)
    
    if not medicamento:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return jsonify(schema_one.dump(medicamento)), 200

@bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_medicamento(id):
    \"\"\"Actualiza un medicamento.\"\"\"
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    medicamento = MedicamentoService.update(id, data, usuario_id)
    if not medicamento:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return jsonify(schema_one.dump(medicamento)), 200

@bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_medicamento(id):
    \"\"\"Elimina un medicamento.\"\"\"
    usuario_id = int(get_jwt_identity())
    success = MedicamentoService.delete(id, usuario_id)
    
    if not success:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return '', 204

@bp.route('/<int:id>/toggle', methods=['PATCH'])
@jwt_required()
def toggle_medicamento(id):
    \"\"\"Alterna el estado tomado de un medicamento.\"\"\"
    usuario_id = int(get_jwt_identity())
    medicamento = MedicamentoService.toggle_tomado(id, usuario_id)
    
    if not medicamento:
        return jsonify({"msg": "Medicamento no encontrado"}), 404
        
    return jsonify(schema_one.dump(medicamento)), 200
"""

files["app/api/contactos.py"] = """\"\"\"Blueprint de Contactos.\"\"\"
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.contacto_service import ContactoService
from app.schemas.contacto_schema import ContactoSchema

bp = Blueprint('contactos', __name__)
schema_many = ContactoSchema(many=True)
schema_one = ContactoSchema()

@bp.route('', methods=['GET'])
@jwt_required()
def get_contactos():
    \"\"\"Obtiene todos los contactos del usuario.\"\"\"
    usuario_id = int(get_jwt_identity())
    contactos = ContactoService.get_all(usuario_id)
    return jsonify(schema_many.dump(contactos)), 200

@bp.route('', methods=['POST'])
@jwt_required()
def create_contacto():
    \"\"\"Crea un nuevo contacto.\"\"\"
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'nombre' not in data or 'telefono' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    contacto = ContactoService.create(data, usuario_id)
    return jsonify(schema_one.dump(contacto)), 201

@bp.route('/<int:id>', methods=['GET'])
@jwt_required()
def get_contacto(id):
    \"\"\"Obtiene un contacto por ID.\"\"\"
    usuario_id = int(get_jwt_identity())
    contacto = ContactoService.get_by_id(id, usuario_id)
    
    if not contacto:
        return jsonify({"msg": "Contacto no encontrado"}), 404
        
    return jsonify(schema_one.dump(contacto)), 200

@bp.route('/<int:id>', methods=['PUT'])
@jwt_required()
def update_contacto(id):
    \"\"\"Actualiza un contacto.\"\"\"
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    contacto = ContactoService.update(id, data, usuario_id)
    if not contacto:
        return jsonify({"msg": "Contacto no encontrado"}), 404
        
    return jsonify(schema_one.dump(contacto)), 200

@bp.route('/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_contacto(id):
    \"\"\"Elimina un contacto.\"\"\"
    usuario_id = int(get_jwt_identity())
    success = ContactoService.delete(id, usuario_id)
    
    if not success:
        return jsonify({"msg": "Contacto no encontrado"}), 404
        
    return '', 204

@bp.route('/emergencia', methods=['GET'])
@jwt_required()
def get_contactos_emergencia():
    \"\"\"Obtiene los contactos de emergencia del usuario.\"\"\"
    usuario_id = int(get_jwt_identity())
    contactos = ContactoService.get_emergencia(usuario_id)
    return jsonify(schema_many.dump(contactos)), 200
"""

files["app/api/habitos.py"] = """\"\"\"Blueprint de Hábitos.\"\"\"
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.habito_service import HabitoService
from app.schemas.habito_schema import HabitoSchema
from datetime import datetime

bp = Blueprint('habitos', __name__)
schema_many = HabitoSchema(many=True)
schema_one = HabitoSchema()

@bp.route('', methods=['GET'])
@jwt_required()
def get_habitos():
    \"\"\"Obtiene los hábitos de una fecha específica.\"\"\"
    usuario_id = int(get_jwt_identity())
    fecha_str = request.args.get('fecha')
    
    if not fecha_str:
        return jsonify({"msg": "La fecha es requerida"}), 400
        
    try:
        fecha = datetime.strptime(fecha_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({"msg": "Formato de fecha inválido. Use YYYY-MM-DD"}), 400
        
    habitos = HabitoService.get_by_fecha(usuario_id, fecha)
    return jsonify(schema_many.dump(habitos)), 200

@bp.route('', methods=['POST'])
@jwt_required()
def create_habito():
    \"\"\"Crea un nuevo hábito.\"\"\"
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'tipo' not in data or 'meta' not in data or 'fecha' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    try:
        data['fecha'] = datetime.strptime(data['fecha'], '%Y-%m-%d').date()
    except ValueError:
        return jsonify({"msg": "Formato de fecha inválido. Use YYYY-MM-DD"}), 400
        
    habito = HabitoService.create(data, usuario_id)
    return jsonify(schema_one.dump(habito)), 201

@bp.route('/<int:id>/progreso', methods=['PATCH'])
@jwt_required()
def update_progreso(id):
    \"\"\"Actualiza el progreso de un hábito.\"\"\"
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'progreso_actual' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    habito = HabitoService.actualizar_progreso(id, data['progreso_actual'], usuario_id)
    if not habito:
        return jsonify({"msg": "Hábito no encontrado"}), 404
        
    return jsonify(schema_one.dump(habito)), 200
"""

files["app/api/juegos.py"] = """\"\"\"Blueprint de Juegos (Actividad Cognitiva).\"\"\"
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.services.juego_service import JuegoService
from app.schemas.actividad_cognitiva_schema import ActividadCognitivaSchema

bp = Blueprint('juegos', __name__)
schema_many = ActividadCognitivaSchema(many=True)
schema_one = ActividadCognitivaSchema()

@bp.route('/puntaje', methods=['POST'])
@jwt_required()
def guardar_puntaje():
    \"\"\"Guarda un nuevo puntaje.\"\"\"
    usuario_id = int(get_jwt_identity())
    data = request.get_json()
    
    if not data or 'tipo_juego' not in data or 'puntaje' not in data:
        return jsonify({"msg": "Faltan datos requeridos"}), 400
        
    actividad = JuegoService.guardar_puntaje(data, usuario_id)
    return jsonify(schema_one.dump(actividad)), 201

@bp.route('/historial', methods=['GET'])
@jwt_required()
def get_historial():
    \"\"\"Obtiene el historial de puntajes del usuario.\"\"\"
    usuario_id = int(get_jwt_identity())
    historial = JuegoService.get_historial(usuario_id)
    return jsonify(schema_many.dump(historial)), 200
"""

files["run.py"] = """\"\"\"Punto de entrada de la aplicación.\"\"\"
from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
"""

files["tests/conftest.py"] = """\"\"\"Fixtures de Pytest.\"\"\"
import pytest
from app import create_app
from app.extensions import db
from app.models.usuario import Usuario
from flask_jwt_extended import create_access_token

@pytest.fixture
def app():
    \"\"\"Fixture de la aplicación en modo testing.\"\"\"
    app = create_app('config.TestingConfig')
    
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    \"\"\"Fixture del cliente de pruebas.\"\"\"
    return app.test_client()

@pytest.fixture
def test_user(app):
    \"\"\"Crea un usuario de prueba.\"\"\"
    user = Usuario(nombre='Test User', email='test@example.com')
    user.set_password('password123')
    db.session.add(user)
    db.session.commit()
    return user

@pytest.fixture
def auth_headers(app, test_user):
    \"\"\"Genera headers con token JWT para el usuario de prueba.\"\"\"
    access_token = create_access_token(identity=str(test_user.id))
    return {'Authorization': f'Bearer {access_token}'}
"""

files["tests/test_auth.py"] = """\"\"\"Tests para Autenticación.\"\"\"
def test_register(client):
    response = client.post('/api/auth/register', json={
        'nombre': 'Nuevo',
        'email': 'nuevo@example.com',
        'password': 'pass'
    })
    assert response.status_code == 201
    assert b'exitosamente' in response.data

def test_login(client, test_user):
    response = client.post('/api/auth/login', json={
        'email': 'test@example.com',
        'password': 'password123'
    })
    assert response.status_code == 200
    assert 'access_token' in response.json
"""

files["tests/test_medicamentos.py"] = """\"\"\"Tests para Medicamentos.\"\"\"
def test_create_medicamento(client, auth_headers):
    response = client.post('/api/medicamentos', json={
        'nombre': 'Paracetamol'
    }, headers=auth_headers)
    assert response.status_code == 201
    assert response.json['nombre'] == 'Paracetamol'

def test_get_medicamentos(client, auth_headers):
    client.post('/api/medicamentos', json={'nombre': 'Aspirina'}, headers=auth_headers)
    response = client.get('/api/medicamentos', headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json) == 1
    assert response.json[0]['nombre'] == 'Aspirina'

def test_toggle_medicamento(client, auth_headers):
    res = client.post('/api/medicamentos', json={'nombre': 'Aspirina'}, headers=auth_headers)
    med_id = res.json['id']
    
    toggle_res = client.patch(f'/api/medicamentos/{med_id}/toggle', headers=auth_headers)
    assert toggle_res.status_code == 200
    assert toggle_res.json['esta_tomado'] is True
"""

files["tests/test_contactos.py"] = """\"\"\"Tests para Contactos.\"\"\"
def test_create_contacto(client, auth_headers):
    response = client.post('/api/contactos', json={
        'nombre': 'Juan',
        'telefono': '123456789',
        'es_emergencia': True
    }, headers=auth_headers)
    assert response.status_code == 201

def test_get_emergencia(client, auth_headers):
    client.post('/api/contactos', json={
        'nombre': 'Juan',
        'telefono': '123456789',
        'es_emergencia': True
    }, headers=auth_headers)
    
    response = client.get('/api/contactos/emergencia', headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json) == 1
"""

files["tests/test_habitos.py"] = """\"\"\"Tests para Hábitos.\"\"\"
def test_create_habito(client, auth_headers):
    response = client.post('/api/habitos', json={
        'tipo': 'Agua',
        'meta': 8,
        'fecha': '2023-10-01'
    }, headers=auth_headers)
    assert response.status_code == 201

def test_actualizar_progreso(client, auth_headers):
    res = client.post('/api/habitos', json={
        'tipo': 'Agua',
        'meta': 8,
        'fecha': '2023-10-01'
    }, headers=auth_headers)
    habito_id = res.json['id']
    
    update_res = client.patch(f'/api/habitos/{habito_id}/progreso', json={
        'progreso_actual': 4
    }, headers=auth_headers)
    assert update_res.status_code == 200
    assert update_res.json['progreso_actual'] == 4
    assert update_res.json['porcentaje'] == 50.0
"""

for path, content in files.items():
    full_path = os.path.join(base_dir, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Backend generation complete.")
