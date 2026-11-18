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


def test_sincronizar_contactos_evita_duplicados(client, auth_headers):
    client.post('/api/contactos', json={
        'nombre': 'Juan Existente',
        'telefono': '+57 3001234567',
        'es_emergencia': False
    }, headers=auth_headers)

    res = client.post('/api/contactos/sincronizar', json={
        'contactos': [
            {'nombre': 'Juan Repetido', 'telefono': '300 123 4567'},
            {'nombre': 'María Hija', 'telefono': '3109876543', 'es_favorito': True, 'categoria': 'Familia/Amigos'},
            {'nombre': 'Dr. Carlos', 'telefono': '6013456789', 'es_emergencia': True, 'categoria': 'Médico'},
        ]
    }, headers=auth_headers)

    assert res.status_code == 201
    data = res.get_json()
    assert data['total_creados'] == 2
    assert data['omitidos_duplicados'] == 1
    assert len(data['creados']) == 2
