"""Tests para Autenticación."""
def test_register(client):
    response = client.post('/api/auth/register', json={
        'nombre': 'Nuevo',
        'email': 'nuevo@example.com',
        'password': 'password123'
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
