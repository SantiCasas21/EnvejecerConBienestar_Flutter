"""Tests para Medicamentos."""
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
