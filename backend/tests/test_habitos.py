"""Tests para Hábitos."""
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
