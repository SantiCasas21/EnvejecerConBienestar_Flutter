"""Tests para Contactos."""
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
