"""Configuración de la aplicación Flask."""
import os
from datetime import timedelta
from dotenv import load_dotenv

# Cargar variables de entorno desde .env
load_dotenv()

class Config:
    """Configuración base."""
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'jwt-dev-secret-key'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

class DevelopmentConfig(Config):
    """Configuración de desarrollo conectada primariamente a PostgreSQL (persistencia real)."""
    DEBUG = True
    # PostgreSQL es la opción principal y predeterminada de base de datos
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'postgresql://ecb_user:ecb_secret_2024@localhost:5432/envejecer_bienestar'
    # Opción de base de datos local SQLite para desarrollo desconectado
    OFFLINE_SQLITE_URI = f"sqlite:///{os.path.join(os.path.abspath(os.path.dirname(__file__)), 'offline_envejecer.db')}"

class TestingConfig(Config):
    """Configuración de pruebas."""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    WTF_CSRF_ENABLED = False

class ProductionConfig(Config):
    """Configuración de producción."""
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'postgresql://ecb_user:ecb_secret_2024@db:5432/envejecer_bienestar'
