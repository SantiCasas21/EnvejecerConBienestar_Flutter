"""Factory de la aplicación Flask."""
from flask import Flask, request, jsonify
from config import DevelopmentConfig, TestingConfig, ProductionConfig
from app.extensions import db, migrate, jwt, cors, ma
from app.utils.error_handlers import register_error_handlers
from app.api import register_blueprints
import os

def create_app(config_class=DevelopmentConfig) -> Flask:
    """Crea y configura la aplicación Flask con soporte completo de CORS."""
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
    
    # Comprobación de resiliencia: Si PostgreSQL no está disponible en desarrollo local,
    # se activa la base de datos SQLite offline para no bloquear la app.
    with app.app_context():
        if not app.config.get('TESTING') and 'sqlite' not in app.config.get('SQLALCHEMY_DATABASE_URI', ''):
            try:
                conn = db.engine.connect()
                conn.close()
            except Exception as e:
                offline_db = os.path.join(app.root_path, '..', 'offline_envejecer.db')
                app.logger.warning(
                    f"⚠️ PostgreSQL principal no disponible ({e}). Activando fallback SQLite offline."
                )
                app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{os.path.abspath(offline_db)}"
                db.engine.dispose()
                db.init_app(app)

        if not app.config.get('TESTING'):
            from app.utils.db_migrations import run_db_migrations
            run_db_migrations()

    migrate.init_app(app, db)
    jwt.init_app(app)
    
    # Configuración amplia de CORS para clientes Web, Móviles y herramientas API
    cors.init_app(
        app,
        resources={r"/*": {"origins": "*"}},
        supports_credentials=True,
        allow_headers=["Content-Type", "Authorization", "Access-Control-Allow-Credentials", "Origin", "Accept"],
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"]
    )
    ma.init_app(app)

    # Middleware para asegurar cabeceras CORS en todas las respuestas y manejar OPTIONS preflight
    @app.after_request
    def after_request(response):
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Access-Control-Allow-Credentials, Origin, Accept'
        response.headers['Access-Control-Allow-Methods'] = 'GET, PUT, POST, DELETE, OPTIONS, PATCH, HEAD'
        return response

    # Registrar manejadores de errores y blueprints
    register_error_handlers(app)
    register_blueprints(app)

    return app
