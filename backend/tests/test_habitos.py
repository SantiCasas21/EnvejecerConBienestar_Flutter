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

def test_crud_metas_actualizar_y_eliminar(client, auth_headers):
    # Crear meta
    res = client.post('/api/metas', json={
        'nombre': 'Tomar agua mineral',
        'objetivo': 8,
        'unidad': 'vasos',
        'icono': '💧'
    }, headers=auth_headers)
    assert res.status_code == 201
    meta_id = res.json['id']

    # Modificar meta existente
    res_mod = client.put(f'/api/metas/{meta_id}', json={
        'nombre': 'Agua con limón',
        'objetivo': 6,
        'unidad': 'vasos',
        'icono': '🍋'
    }, headers=auth_headers)
    assert res_mod.status_code == 200
    assert res_mod.json['nombre'] == 'Agua con limón'
    assert res_mod.json['objetivo'] == 6
    assert res_mod.json['icono'] == '🍋'

    # Eliminar meta
    res_del = client.delete(f'/api/metas/{meta_id}', headers=auth_headers)
    assert res_del.status_code == 204

    # Verificar que ya no existe
    res_check = client.get('/api/metas', headers=auth_headers)
    assert res_check.status_code == 200
    assert not any(m['id'] == meta_id for m in res_check.json)

def test_consultar_racha_adherencia(client, auth_headers):
    res = client.get('/api/historial/racha', headers=auth_headers)
    assert res.status_code == 200
    assert 'racha_actual' in res.json
    assert 'racha_mejor' in res.json
    assert 'mensaje_racha' in res.json
    assert 'dias_semana' in res.json
    assert isinstance(res.json['racha_actual'], int)
