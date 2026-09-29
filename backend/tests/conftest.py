"""Fixtures de Pytest."""
import pytest
from app import create_app
from app.extensions import db
from app.models.usuario import Usuario
from flask_jwt_extended import create_access_token

@pytest.fixture
def app():
    """Fixture de la aplicación en modo testing."""
    app = create_app('config.TestingConfig')
    
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    """Fixture del cliente de pruebas."""
    return app.test_client()

@pytest.fixture
def test_user(app):
    """Crea un usuario de prueba."""
    user = Usuario(nombre='Test User', email='test@example.com')
    user.set_password('password123')
    db.session.add(user)
    db.session.commit()
    return user

@pytest.fixture
def auth_headers(app, test_user):
    """Genera headers con token JWT para el usuario de prueba."""
    access_token = create_access_token(identity=str(test_user.id))
    return {'Authorization': f'Bearer {access_token}'}
