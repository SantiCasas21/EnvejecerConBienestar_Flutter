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


def test_google_auth_crea_y_reutiliza_usuario(client):
    from unittest.mock import patch

    fake_claims = {
        'email': 'google.user@example.com',
        'name': 'Laura Google',
        'sub': 'uid-123',
    }
    with patch('app.api.auth.google_id_token.verify_firebase_token', return_value=fake_claims):
        res1 = client.post('/api/auth/google', json={
            'id_token': 'fake-firebase-token',
            'rol': 'adulto_mayor',
        })
        assert res1.status_code == 201
        d1 = res1.get_json()
        assert d1['es_nuevo'] is True
        assert d1['usuario']['email'] == 'google.user@example.com'
        assert d1['usuario']['codigo_vinculacion'].startswith('ECB-')
        assert 'access_token' in d1

        res2 = client.post('/api/auth/google', json={
            'id_token': 'fake-firebase-token',
        })
        assert res2.status_code == 200
        d2 = res2.get_json()
        assert d2['es_nuevo'] is False
        assert d2['usuario']['id'] == d1['usuario']['id']
