"""Módulo de Blueprints de la API."""
from flask import Flask
from .auth import bp as auth_bp
from .medicamentos import bp as medicamentos_bp
from .tratamientos import bp as tratamientos_bp
from .contactos import bp as contactos_bp
from .habitos import bp as habitos_bp
from .juegos import bp as juegos_bp
from .metas import bp as metas_bp
from .perfil import bp as perfil_bp
from .cuidadores import bp as cuidadores_bp
from .expediente import bp as expediente_bp

def register_blueprints(app: Flask) -> None:
    """Registra todos los blueprints en la aplicación."""
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(medicamentos_bp, url_prefix='/api/medicamentos')
    app.register_blueprint(tratamientos_bp, url_prefix='/api/tratamientos')
    app.register_blueprint(contactos_bp, url_prefix='/api/contactos')
    app.register_blueprint(habitos_bp, url_prefix='/api/habitos')
    app.register_blueprint(juegos_bp, url_prefix='/api/juegos')
    app.register_blueprint(metas_bp, url_prefix='/api/metas')
    app.register_blueprint(perfil_bp, url_prefix='/api/perfil')
    app.register_blueprint(cuidadores_bp, url_prefix='/api/cuidadores')
    app.register_blueprint(expediente_bp, url_prefix='/api/expediente-clinico')
