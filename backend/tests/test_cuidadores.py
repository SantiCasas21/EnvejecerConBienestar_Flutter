"""Tests para el módulo de Cuidadores, Vinculación y Supervisión."""
import re
from datetime import time
from app.extensions import db
from app.models.medicamento import Medicamento


def test_registro_adulto_mayor_asigna_codigo_vinculacion(client):
    """
    Prueba que el registro de un usuario con rol 'adulto_mayor'
    le asigne automáticamente un código de vinculación con formato 'ECB-XXXX'.
    """
    response = client.post('/api/auth/register', json={
        'nombre': 'Abuela Rosa',
        'email': 'abuela.rosa@example.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    assert response.status_code == 201
    data = response.get_json()
    usuario = data['usuario']
    assert usuario['rol'] == 'adulto_mayor'
    assert usuario['codigo_vinculacion'] is not None
    assert re.match(r'^ECB-\d{4,}$', usuario['codigo_vinculacion']), \
        f"El código {usuario['codigo_vinculacion']} no coincide con el formato ECB-XXXX"


def test_registro_cuidador_sin_codigo_vinculacion(client):
    """
    Prueba que el registro de un usuario con rol 'cuidador'
    guarde dicho rol y mantenga el codigo_vinculacion en None.
    """
    response = client.post('/api/auth/register', json={
        'nombre': 'Carlos Cuidador',
        'email': 'carlos.cuidador@example.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    assert response.status_code == 201
    data = response.get_json()
    usuario = data['usuario']
    assert usuario['rol'] == 'cuidador'
    assert usuario['codigo_vinculacion'] is None


def test_vincular_paciente_con_codigo_valido(client):
    """
    Prueba que un cuidador pueda vincular a un adulto mayor usando su código válido,
    retornando status 201.
    """
    # 1. Registrar adulto mayor
    res_paciente = client.post('/api/auth/register', json={
        'nombre': 'Don Mario',
        'email': 'mario@example.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    codigo_paciente = res_paciente.get_json()['usuario']['codigo_vinculacion']
    assert codigo_paciente is not None

    # 2. Registrar cuidador
    res_cuidador = client.post('/api/auth/register', json={
        'nombre': 'Hija Sofia',
        'email': 'sofia@example.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_cuidador = res_cuidador.get_json()['access_token']
    headers = {'Authorization': f'Bearer {token_cuidador}'}

    # 3. Vincular cuidador -> paciente
    res_vinculo = client.post('/api/cuidadores/vincular', headers=headers, json={
        'codigo_vinculacion': codigo_paciente,
        'parentesco': 'Hija'
    })
    assert res_vinculo.status_code == 201
    datos_vinculo = res_vinculo.get_json()
    assert datos_vinculo['paciente']['nombre'] == 'Don Mario'
    assert datos_vinculo['parentesco'] == 'Hija'
    assert datos_vinculo['ya_vinculado'] is False


def test_vincular_paciente_codigo_inexistente(client):
    """
    Prueba que intentar vincular con un código que no existe retorne 404.
    """
    # Registrar cuidador
    res_cuidador = client.post('/api/auth/register', json={
        'nombre': 'Cuidador Test',
        'email': 'cuidador.404@example.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_cuidador = res_cuidador.get_json()['access_token']
    headers = {'Authorization': f'Bearer {token_cuidador}'}

    # Vincular con código inexistente
    response = client.post('/api/cuidadores/vincular', headers=headers, json={
        'codigo_vinculacion': 'ECB-9999',
        'parentesco': 'Enfermero'
    })
    assert response.status_code == 404
    data = response.get_json()
    assert 'No encontramos ningún adulto mayor' in data['msg']


def test_prevenir_vinculacion_duplicada(client):
    """
    Prueba que intentar vincular un paciente ya vinculado retorne 409 (Conflict).
    """
    # 1. Registrar adulto mayor
    res_paciente = client.post('/api/auth/register', json={
        'nombre': 'Abuelo Juan',
        'email': 'abuelo.juan@example.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    codigo = res_paciente.get_json()['usuario']['codigo_vinculacion']

    # 2. Registrar cuidador
    res_cuidador = client.post('/api/auth/register', json={
        'nombre': 'Cuidador Juan Jr',
        'email': 'juan.jr@example.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token = res_cuidador.get_json()['access_token']
    headers = {'Authorization': f'Bearer {token}'}

    # 3. Primera vinculación (exitosa 201)
    res_1 = client.post('/api/cuidadores/vincular', headers=headers, json={
        'codigo_vinculacion': codigo,
        'parentesco': 'Hijo'
    })
    assert res_1.status_code == 201

    # 4. Segunda vinculación idéntica (debe retornar 409)
    res_2 = client.post('/api/cuidadores/vincular', headers=headers, json={
        'codigo_vinculacion': codigo,
        'parentesco': 'Hijo'
    })
    assert res_2.status_code == 409
    data_2 = res_2.get_json()
    assert data_2.get('ya_vinculado') is True
    assert 'ya se encuentra vinculado' in data_2.get('msg', '')


def test_listar_pacientes_con_metricas_tomas(client, app):
    """
    Prueba el endpoint '/api/cuidadores/pacientes' para listar los adultos mayores
    vinculados y verificar el cálculo de tomas de medicamentos (cumplidas, pendientes, alertas).
    """
    # 1. Registrar adulto mayor y cuidador
    res_paciente = client.post('/api/auth/register', json={
        'nombre': 'Dña Carmen',
        'email': 'carmen@example.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_paciente.get_json()['usuario']['id']
    codigo = res_paciente.get_json()['usuario']['codigo_vinculacion']

    res_cuidador = client.post('/api/auth/register', json={
        'nombre': 'Cuidadora Lucia',
        'email': 'lucia@example.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_cuidador = res_cuidador.get_json()['access_token']
    headers = {'Authorization': f'Bearer {token_cuidador}'}

    # 2. Vincular
    res_vinc = client.post('/api/cuidadores/vincular', headers=headers, json={
        'codigo_vinculacion': codigo,
        'parentesco': 'Sobrina'
    })
    assert res_vinc.status_code == 201

    # 3. Insertar medicamentos para el paciente en la base de datos
    with app.app_context():
        # Medicamento 1: Tomado, suficiente stock
        med1 = Medicamento(
            usuario_id=paciente_id,
            nombre='Losartán 50mg',
            miligramos='50mg',
            frecuencia=12,
            hora_alarma=time(8, 0),
            esta_tomado=True,
            cantidad_restante=20,
            umbral_alerta=5
        )
        # Medicamento 2: Pendiente, bajo stock (alerta)
        med2 = Medicamento(
            usuario_id=paciente_id,
            nombre='Atorvastatina 20mg',
            miligramos='20mg',
            frecuencia=24,
            hora_alarma=time(20, 0),
            esta_tomado=False,
            cantidad_restante=3,
            umbral_alerta=5
        )
        db.session.add_all([med1, med2])
        db.session.commit()

    # 4. Consultar lista de pacientes supervisados
    res_lista = client.get('/api/cuidadores/pacientes', headers=headers)
    assert res_lista.status_code == 200
    pacientes = res_lista.get_json()['pacientes']
    assert len(pacientes) == 1

    p = pacientes[0]
    assert p['nombre'] == 'Dña Carmen'
    assert p['codigo_vinculacion'] == codigo
    assert p['parentesco'] == 'Sobrina'
    assert p['total_medicamentos'] == 2
    assert p['tomas_cumplidas'] == 1
    assert p['tomas_pendientes'] == 1
    assert p['alertas_stock'] == 1
    assert 'Atorvastatina 20mg' in p['medicamentos_alerta']
    assert p['proxima_toma'] is not None
    assert p['proxima_toma']['nombre'] == 'Atorvastatina 20mg'

    # 5. Verificar lista completa de medicamentos enriquecida para cola y botiquín
    assert 'medicamentos' in p
    assert len(p['medicamentos']) == 2
    nombres_meds = [m['nombre'] for m in p['medicamentos']]
    assert 'Losartán 50mg' in nombres_meds
    assert 'Atorvastatina 20mg' in nombres_meds

    med_alerta = next(m for m in p['medicamentos'] if m['nombre'] == 'Atorvastatina 20mg')
    assert med_alerta['alerta_inventario'] is True
    assert med_alerta['esta_tomado'] is False
    assert med_alerta['cantidad_restante'] == 3

    med_ok = next(m for m in p['medicamentos'] if m['nombre'] == 'Losartán 50mg')
    assert med_ok['alerta_inventario'] is False
    assert med_ok['esta_tomado'] is True


def test_sincronizacion_contacto_sos_al_actualizar_perfil(client, app, test_user, auth_headers):
    """
    Prueba que al guardar o actualizar la ficha médica en /api/perfil con
    contacto_emergencia_nombre y contacto_emergencia_telefono, se sincronice
    automáticamente en la tabla Contacto con es_emergencia=True y es_favorito=True.
    """
    from app.models.contacto import Contacto

    # 1. Actualizar perfil médico con datos de emergencia SOS
    res_perfil = client.put('/api/perfil', headers=auth_headers, json={
        'edad': 76,
        'tipo_sangre': 'O+',
        'contacto_emergencia_nombre': 'Dra. Claudia Gómez',
        'contacto_emergencia_telefono': '3001234567',
        'contacto_emergencia_parentesco': 'Médico de Cabecera'
    })
    assert res_perfil.status_code == 200

    # 2. Verificar que se haya creado el contacto SOS en base de datos
    with app.app_context():
        contacto = Contacto.query.filter_by(
            usuario_id=test_user.id,
            telefono='3001234567'
        ).first()
        assert contacto is not None
        assert contacto.nombre == 'Dra. Claudia Gómez'
        assert contacto.es_emergencia is True
        assert contacto.es_favorito is True
        assert contacto.icono == '🚨'

    # 3. Verificar que aparezca en el endpoint de emergencias
    res_sos = client.get('/api/contactos/emergencia', headers=auth_headers)
    assert res_sos.status_code == 200
    contactos_sos = res_sos.get_json()
    assert any(c['telefono'] == '3001234567' and c['es_emergencia'] for c in contactos_sos)

    # 4. Actualizar nuevamente el contacto de emergencia en la ficha médica
    res_actualizar = client.put('/api/perfil', headers=auth_headers, json={
        'contacto_emergencia_nombre': 'Hijo Andrés SOS',
        'contacto_emergencia_telefono': '3109876543',
        'contacto_emergencia_parentesco': 'Hijo'
    })
    assert res_actualizar.status_code == 200

    # 5. Verificar que el contacto existente se actualice sin duplicar contactos de emergencia
    with app.app_context():
        contactos_emergencia = Contacto.query.filter_by(
            usuario_id=test_user.id,
            es_emergencia=True
        ).all()
        assert len(contactos_emergencia) == 1
        assert contactos_emergencia[0].nombre == 'Hijo Andrés SOS'
        assert contactos_emergencia[0].telefono == '3109876543'
        assert contactos_emergencia[0].es_favorito is True

