"""Tests para endpoints de Medicamentos e Inventario de Botiquín por Cuidadores."""
from datetime import time
from app.extensions import db
from app.models.medicamento import Medicamento


def test_cuidador_consulta_medicamentos_paciente_vinculado(client, app):
    """
    Prueba que un cuidador autenticado y vinculado pueda consultar la lista completa
    de medicamentos e inventario de botiquín de su paciente (GET /api/cuidadores/pacientes/<id>/medicamentos).
    """
    # 1. Registrar paciente adulto mayor
    res_paciente = client.post('/api/auth/register', json={
        'nombre': 'Don Efraín',
        'email': 'efrain@botiquin.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_paciente.get_json()['usuario']['id']
    codigo_paciente = res_paciente.get_json()['usuario']['codigo_vinculacion']

    # 2. Registrar cuidador y vincularlo
    res_cuidador = client.post('/api/auth/register', json={
        'nombre': 'Cuidador Mateo',
        'email': 'mateo@cuidador.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_cuidador = res_cuidador.get_json()['access_token']
    headers_cuidador = {'Authorization': f'Bearer {token_cuidador}'}

    res_vinc = client.post('/api/cuidadores/vincular', headers=headers_cuidador, json={
        'codigo_vinculacion': codigo_paciente,
        'parentesco': 'Nieto'
    })
    assert res_vinc.status_code == 201

    # 3. Crear medicamento en base de datos para el paciente
    with app.app_context():
        med = Medicamento(
            usuario_id=paciente_id,
            nombre='Metformina',
            miligramos='850mg',
            frecuencia=12,
            hora_alarma=time(8, 0),
            esta_tomado=False,
            cantidad_restante=8,
            umbral_alerta=5,
            icono='💊'
        )
        db.session.add(med)
        db.session.commit()

    # 4. Cuidador consulta los medicamentos del paciente
    response = client.get(
        f'/api/cuidadores/pacientes/{paciente_id}/medicamentos',
        headers=headers_cuidador
    )
    assert response.status_code == 200
    data = response.get_json()
    assert 'medicamentos' in data
    assert len(data['medicamentos']) == 1

    med_resp = data['medicamentos'][0]
    assert med_resp['nombre'] == 'Metformina'
    assert med_resp['miligramos'] == '850mg'
    assert med_resp['cantidad_restante'] == 8
    assert med_resp['tomas_por_dia'] == 2  # 24 // 12
    assert med_resp['dias_autonomia'] == 4  # 8 // 2
    assert med_resp['alerta_inventario'] is False  # 8 > 5


def test_cuidador_no_vinculado_recibe_403(client, app):
    """
    Prueba que un cuidador no vinculado al paciente reciba HTTP 403 Forbidden
    al intentar consultar sus medicamentos.
    """
    # 1. Registrar paciente
    res_paciente = client.post('/api/auth/register', json={
        'nombre': 'Don Mario',
        'email': 'mario.privado@botiquin.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_paciente.get_json()['usuario']['id']

    # 2. Registrar cuidador ajeno (sin vincular)
    res_cuidador_ajeno = client.post('/api/auth/register', json={
        'nombre': 'Cuidador No Vinculado',
        'email': 'ajeno@cuidador.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_ajeno = res_cuidador_ajeno.get_json()['access_token']
    headers_ajeno = {'Authorization': f'Bearer {token_ajeno}'}

    # 3. Intentar consultar medicamentos sin vínculo
    response = client.get(
        f'/api/cuidadores/pacientes/{paciente_id}/medicamentos',
        headers=headers_ajeno
    )
    assert response.status_code == 403
    data = response.get_json()
    assert 'No tienes autorización' in data['msg']


def test_reabastecer_stock_medicamento_paciente_exitoso(client, app):
    """
    Prueba el endpoint POST '/api/cuidadores/pacientes/<id>/medicamentos/<med_id>/reabastecer'
    con incrementos rápidos de +10 y +30 pastillas, verificando que la BD persista la nueva cantidad.
    """
    # 1. Registrar paciente y cuidador vinculado
    res_pac = client.post('/api/auth/register', json={
        'nombre': 'Dña Teresa',
        'email': 'teresa@botiquin.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_pac.get_json()['usuario']['id']
    codigo = res_pac.get_json()['usuario']['codigo_vinculacion']

    res_cuid = client.post('/api/auth/register', json={
        'nombre': 'Cuidadora Andrea',
        'email': 'andrea@botiquin.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_cuid = res_cuid.get_json()['access_token']
    headers = {'Authorization': f'Bearer {token_cuid}'}

    res_vinc = client.post('/api/cuidadores/vincular', headers=headers, json={
        'codigo_vinculacion': codigo,
        'parentesco': 'Hija'
    })
    assert res_vinc.status_code == 201

    # 2. Crear medicamento inicial con 5 pastillas (en alerta)
    with app.app_context():
        med = Medicamento(
            usuario_id=paciente_id,
            nombre='Losartán',
            miligramos='50mg',
            frecuencia=24,
            cantidad_restante=5,
            umbral_alerta=5
        )
        db.session.add(med)
        db.session.commit()
        med_id = med.id

    # 3. Reabastecer +10 pastillas (5 + 10 = 15)
    res_reabast_10 = client.post(
        f'/api/cuidadores/pacientes/{paciente_id}/medicamentos/{med_id}/reabastecer',
        headers=headers,
        json={'cantidad': 10}
    )
    assert res_reabast_10.status_code == 200
    data_10 = res_reabast_10.get_json()
    assert data_10['medicamento']['cantidad_restante'] == 15
    assert data_10['medicamento']['alerta_inventario'] is False
    assert '10 pastillas' in data_10['mensaje']

    # 4. Reabastecer +30 pastillas adicionales (15 + 30 = 45)
    res_reabast_30 = client.post(
        f'/api/cuidadores/pacientes/{paciente_id}/medicamentos/{med_id}/reabastecer',
        headers=headers,
        json={'cantidad': 30}
    )
    assert res_reabast_30.status_code == 200
    data_30 = res_reabast_30.get_json()
    assert data_30['medicamento']['cantidad_restante'] == 45
    assert '30 pastillas' in data_30['mensaje']

    # 5. Verificar persistencia en base de datos
    with app.app_context():
        med_db = Medicamento.query.get(med_id)
        assert med_db.cantidad_restante == 45


def test_reabastecer_stock_valida_cantidad_positiva(client, app):
    """
    Prueba que el endpoint de reabastecimiento rechace cantidades inválidas (<= 0)
    retornando HTTP 400 Bad Request.
    """
    # 1. Registrar paciente y cuidador
    res_pac = client.post('/api/auth/register', json={
        'nombre': 'Don Carlos',
        'email': 'carlos.val@botiquin.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_pac.get_json()['usuario']['id']
    codigo = res_pac.get_json()['usuario']['codigo_vinculacion']

    res_cuid = client.post('/api/auth/register', json={
        'nombre': 'Cuidador Esteban',
        'email': 'esteban@botiquin.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token = res_cuid.get_json()['access_token']
    headers = {'Authorization': f'Bearer {token}'}

    client.post('/api/cuidadores/vincular', headers=headers, json={
        'codigo_vinculacion': codigo,
        'parentesco': 'Hermano'
    })

    # 2. Crear medicamento
    with app.app_context():
        med = Medicamento(
            usuario_id=paciente_id,
            nombre='Enalapril',
            cantidad_restante=10
        )
        db.session.add(med)
        db.session.commit()
        med_id = med.id

    # 3. Intentar reabastecer con cantidad 0
    res_zero = client.post(
        f'/api/cuidadores/pacientes/{paciente_id}/medicamentos/{med_id}/reabastecer',
        headers=headers,
        json={'cantidad': 0}
    )
    assert res_zero.status_code == 400
    assert 'mayor a 0' in res_zero.get_json()['msg']

    # 4. Intentar reabastecer con cantidad negativa
    res_neg = client.post(
        f'/api/cuidadores/pacientes/{paciente_id}/medicamentos/{med_id}/reabastecer',
        headers=headers,
        json={'cantidad': -10}
    )
    assert res_neg.status_code == 400
    assert 'mayor a 0' in res_neg.get_json()['msg']


def test_reabastecer_cuidador_no_vinculado_retorna_403(client, app):
    """
    Prueba que un cuidador no vinculado al paciente no pueda reabastecer sus medicamentos
    y reciba HTTP 403 Forbidden.
    """
    # 1. Registrar paciente y medicamento
    res_pac = client.post('/api/auth/register', json={
        'nombre': 'Dña Gloria',
        'email': 'gloria@botiquin.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_pac.get_json()['usuario']['id']

    with app.app_context():
        med = Medicamento(
            usuario_id=paciente_id,
            nombre='Aspirina',
            cantidad_restante=20
        )
        db.session.add(med)
        db.session.commit()
        med_id = med.id

    # 2. Registrar cuidador sin vínculo
    res_cuid = client.post('/api/auth/register', json={
        'nombre': 'Cuidador Sin Vinculo',
        'email': 'sinvinculo@botiquin.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token = res_cuid.get_json()['access_token']
    headers = {'Authorization': f'Bearer {token}'}

    # 3. Intentar reabastecer
    response = client.post(
        f'/api/cuidadores/pacientes/{paciente_id}/medicamentos/{med_id}/reabastecer',
        headers=headers,
        json={'cantidad': 10}
    )
    assert response.status_code == 403
    assert 'No tienes autorización' in response.get_json()['msg']
