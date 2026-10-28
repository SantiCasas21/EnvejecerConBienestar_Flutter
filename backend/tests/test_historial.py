"""Tests para el módulo de Historial de Tomas, Hábitos y Resumen de Adherencia."""
import pytest
from datetime import date, timedelta
from app.extensions import db
from app.models.medicamento import Medicamento
from app.models.habito import Habito
from app.models.historial_toma import HistorialToma


@pytest.fixture
def test_medicamento(client, auth_headers):
    """Crea un medicamento de prueba para test_user."""
    res = client.post('/api/medicamentos', json={
        'nombre': 'Losartán',
        'miligramos': '50mg',
        'frecuencia': 12,
        'hora_alarma': '08:00',
        'icono': '💊',
        'cantidad_restante': 30,
        'umbral_alerta': 5,
    }, headers=auth_headers)
    assert res.status_code == 201
    return res.json


def test_registrar_toma_estados(client, auth_headers, test_medicamento):
    """
    Prueba el registro de tomas con los estados 'tomada', 'pospuesta' y 'omitida',
    así como el manejo de errores de validación y medicamento no encontrado.
    """
    med_id = test_medicamento['id']
    hoy_str = date.today().isoformat()

    # 1. Registrar toma con estado 'tomada'
    res_tomada = client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med_id,
        'fecha': hoy_str,
        'hora_programada': '08:00',
        'estado': 'tomada',
        'notas': 'Tomada con el desayuno y agua'
    })
    assert res_tomada.status_code == 201
    data_tomada = res_tomada.get_json()
    assert data_tomada['estado'] == 'tomada'
    assert data_tomada['notas'] == 'Tomada con el desayuno y agua'
    assert data_tomada['medicamento_id'] == med_id
    assert data_tomada['hora_programada'] == '08:00'
    assert data_tomada['hora_real'] is not None

    # 2. Registrar toma con estado 'pospuesta'
    res_pospuesta = client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med_id,
        'fecha': hoy_str,
        'hora_programada': '14:00',
        'estado': 'pospuesta',
        'notas': 'Pospuesta 10 minutos'
    })
    assert res_pospuesta.status_code == 201
    data_pospuesta = res_pospuesta.get_json()
    assert data_pospuesta['estado'] == 'pospuesta'
    assert data_pospuesta['hora_programada'] == '14:00'

    # 3. Registrar toma con estado 'omitida'
    res_omitida = client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med_id,
        'fecha': hoy_str,
        'hora_programada': '20:00',
        'estado': 'omitida',
        'notas': 'Omitida por indicación médica'
    })
    assert res_omitida.status_code == 201
    data_omitida = res_omitida.get_json()
    assert data_omitida['estado'] == 'omitida'

    # 4. Error con estado inválido
    res_invalida = client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med_id,
        'estado': 'desconocido'
    })
    assert res_invalida.status_code == 400
    assert 'errores' in res_invalida.get_json()

    # 5. Error con medicamento_id inexistente
    res_no_existe = client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': 99999,
        'estado': 'tomada'
    })
    assert res_no_existe.status_code == 404


def test_consultar_tomas_filtros(client, auth_headers, test_medicamento):
    """
    Prueba la consulta de tomas filtrando por rango de fechas (desde, hasta),
    por día específico y por medicamento_id.
    """
    med_id = test_medicamento['id']
    hoy = date.today()
    ayer = hoy - timedelta(days=1)
    antier = hoy - timedelta(days=2)

    # Registrar tomas en diferentes días
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med_id,
        'fecha': antier.isoformat(),
        'hora_programada': '08:00',
        'estado': 'tomada'
    })
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med_id,
        'fecha': ayer.isoformat(),
        'hora_programada': '08:00',
        'estado': 'tomada'
    })
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med_id,
        'fecha': hoy.isoformat(),
        'hora_programada': '08:00',
        'estado': 'pospuesta'
    })

    # Crear un segundo medicamento y registrar toma
    res_med2 = client.post('/api/medicamentos', json={'nombre': 'Enalapril'}, headers=auth_headers)
    med2_id = res_med2.json['id']
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med2_id,
        'fecha': hoy.isoformat(),
        'hora_programada': '09:00',
        'estado': 'tomada'
    })

    # Consulta sin filtros (debe traer las 4)
    res_todas = client.get('/api/historial/tomas', headers=auth_headers)
    assert res_todas.status_code == 200
    assert len(res_todas.get_json()) == 4

    # Filtro por rango (desde ayer hasta hoy -> 3 tomas)
    res_rango = client.get(
        f'/api/historial/tomas?desde={ayer.isoformat()}&hasta={hoy.isoformat()}',
        headers=auth_headers
    )
    assert res_rango.status_code == 200
    assert len(res_rango.get_json()) == 3

    # Filtro por día específico (desde ayer hasta ayer -> 1 toma)
    res_dia = client.get(
        f'/api/historial/tomas?desde={ayer.isoformat()}&hasta={ayer.isoformat()}',
        headers=auth_headers
    )
    assert res_dia.status_code == 200
    assert len(res_dia.get_json()) == 1
    assert res_dia.get_json()[0]['fecha'] == ayer.isoformat()

    # Filtro por medicamento_id específico
    res_med = client.get(f'/api/historial/tomas?medicamento_id={med2_id}', headers=auth_headers)
    assert res_med.status_code == 200
    assert len(res_med.get_json()) == 1
    assert res_med.get_json()[0]['medicamento_id'] == med2_id


def test_cuidador_acceso_historial_paciente(client):
    """
    Prueba que un cuidador vinculado pueda ver y registrar en el historial de su paciente,
    mientras que un cuidador no vinculado es rechazado con 403 Forbidden.
    """
    # 1. Registrar paciente adulto mayor
    res_paciente = client.post('/api/auth/register', json={
        'nombre': 'Abuela Carmen',
        'email': 'carmen@paciente.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_paciente.get_json()['usuario']['id']
    codigo_paciente = res_paciente.get_json()['usuario']['codigo_vinculacion']
    token_paciente = res_paciente.get_json()['access_token']
    headers_paciente = {'Authorization': f'Bearer {token_paciente}'}

    # Paciente crea medicamento y toma
    res_med = client.post('/api/medicamentos', json={'nombre': 'Atorvastatina'}, headers=headers_paciente)
    med_id = res_med.json['id']
    client.post('/api/historial/tomas', headers=headers_paciente, json={
        'medicamento_id': med_id,
        'fecha': date.today().isoformat(),
        'hora_programada': '21:00',
        'estado': 'tomada'
    })

    # 2. Registrar cuidador 1 y vincular
    res_cuidador1 = client.post('/api/auth/register', json={
        'nombre': 'Cuidadora Lucía',
        'email': 'lucia@cuidador.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_c1 = res_cuidador1.get_json()['access_token']
    headers_c1 = {'Authorization': f'Bearer {token_c1}'}

    res_vinc = client.post('/api/cuidadores/vincular', headers=headers_c1, json={
        'codigo_vinculacion': codigo_paciente,
        'parentesco': 'Hija'
    })
    assert res_vinc.status_code == 201

    # 3. Registrar cuidador 2 (NO vinculado)
    res_cuidador2 = client.post('/api/auth/register', json={
        'nombre': 'Cuidador Extraño',
        'email': 'extrano@cuidador.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_c2 = res_cuidador2.get_json()['access_token']
    headers_c2 = {'Authorization': f'Bearer {token_c2}'}

    # 4. Cuidador 1 consulta tomas de su paciente vinculado -> 200 OK
    res_tomas_c1 = client.get(f'/api/historial/tomas?paciente_id={paciente_id}', headers=headers_c1)
    assert res_tomas_c1.status_code == 200
    assert len(res_tomas_c1.get_json()) == 1
    assert res_tomas_c1.get_json()[0]['medicamento_id'] == med_id

    # 5. Cuidador 1 registra toma para su paciente vinculado -> 201 Created
    res_reg_c1 = client.post('/api/historial/tomas', headers=headers_c1, json={
        'medicamento_id': med_id,
        'paciente_id': paciente_id,
        'fecha': date.today().isoformat(),
        'hora_programada': '09:00',
        'estado': 'tomada',
        'notas': 'Supervisada por Lucía'
    })
    assert res_reg_c1.status_code == 201
    assert res_reg_c1.get_json()['notas'] == 'Supervisada por Lucía'

    # 6. Cuidador 2 intenta consultar tomas del paciente -> 403 Forbidden
    res_tomas_c2 = client.get(f'/api/historial/tomas?paciente_id={paciente_id}', headers=headers_c2)
    assert res_tomas_c2.status_code == 403

    # 7. Cuidador 2 intenta registrar toma para el paciente -> 403 Forbidden
    res_reg_c2 = client.post('/api/historial/tomas', headers=headers_c2, json={
        'medicamento_id': med_id,
        'paciente_id': paciente_id,
        'estado': 'tomada'
    })
    assert res_reg_c2.status_code == 403


def test_resumen_adherencia_calculo(client, auth_headers):
    """
    Prueba el cálculo de métricas de adherencia global y diaria a través de GET /api/historial/resumen.
    """
    # 1. Crear 2 medicamentos
    res_m1 = client.post('/api/medicamentos', json={
        'nombre': 'Medicamento A',
        'frecuencia': 12, # 2 al día
    }, headers=auth_headers)
    med1_id = res_m1.json['id']

    res_m2 = client.post('/api/medicamentos', json={
        'nombre': 'Medicamento B',
        'frecuencia': 24, # 1 al día
    }, headers=auth_headers)
    med2_id = res_m2.json['id']

    hoy = date.today()
    ayer = hoy - timedelta(days=1)

    # Ayer: 2 tomadas de Med A, 1 de Med B (100% de 3 esperadas)
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med1_id,
        'fecha': ayer.isoformat(),
        'hora_programada': '08:00',
        'estado': 'tomada'
    })
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med1_id,
        'fecha': ayer.isoformat(),
        'hora_programada': '20:00',
        'estado': 'tomada'
    })
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med2_id,
        'fecha': ayer.isoformat(),
        'hora_programada': '09:00',
        'estado': 'tomada'
    })

    # Hoy: 1 tomada, 1 omitida
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med1_id,
        'fecha': hoy.isoformat(),
        'hora_programada': '08:00',
        'estado': 'tomada'
    })
    client.post('/api/historial/tomas', headers=auth_headers, json={
        'medicamento_id': med1_id,
        'fecha': hoy.isoformat(),
        'hora_programada': '20:00',
        'estado': 'omitida'
    })

    # Consultar resumen en el rango ayer..hoy
    res = client.get(
        f'/api/historial/resumen?desde={ayer.isoformat()}&hasta={hoy.isoformat()}',
        headers=auth_headers
    )
    assert res.status_code == 200
    data = res.get_json()

    assert data['total_tomadas'] == 4
    assert data['total_omitidas'] == 1
    assert data['total_pospuestas'] == 0
    assert 'porcentaje_adherencia_global' in data
    assert data['porcentaje_adherencia_global'] > 0
    assert len(data['cumplimiento_diario']) == 2
    assert len(data['medicamentos_adherencia']) == 2

    # Verificar cumplimiento específico de ayer
    dia_ayer = next(d for d in data['cumplimiento_diario'] if d['fecha'] == ayer.isoformat())
    assert dia_ayer['tomadas'] == 3
    assert dia_ayer['porcentaje'] == 100.0


def test_toggle_medicamento_persistencia_historial(client, auth_headers):
    """
    Prueba que alternar el estado de un medicamento mediante /api/medicamentos/<id>/toggle
    registre automáticamente la toma en el historial, y revertirlo la desmarque/elimine.
    """
    # 1. Crear medicamento
    res_med = client.post('/api/medicamentos', json={
        'nombre': 'Omeprazol',
        'cantidad_restante': 10,
        'hora_alarma': '07:30'
    }, headers=auth_headers)
    med_id = res_med.json['id']

    # 2. Toggle a tomado (PATCH)
    res_toggle1 = client.patch(f'/api/medicamentos/{med_id}/toggle', headers=auth_headers)
    assert res_toggle1.status_code == 200
    assert res_toggle1.json['esta_tomado'] is True
    assert res_toggle1.json['cantidad_restante'] == 9

    # Verificar que se creó el registro en Historial
    res_historial1 = client.get('/api/historial/tomas', headers=auth_headers)
    assert res_historial1.status_code == 200
    tomas = res_historial1.get_json()
    assert len(tomas) >= 1
    toma_hoy = next(t for t in tomas if t['medicamento_id'] == med_id and t['fecha'] == date.today().isoformat())
    assert toma_hoy['estado'] == 'tomada'
    assert toma_hoy['hora_programada'] == '07:30'

    # 3. Toggle a desmarcado (des-tomar)
    res_toggle2 = client.patch(f'/api/medicamentos/{med_id}/toggle', headers=auth_headers)
    assert res_toggle2.status_code == 200
    assert res_toggle2.json['esta_tomado'] is False
    assert res_toggle2.json['cantidad_restante'] == 10

    # Verificar que la toma de hoy fue eliminada del historial
    res_historial2 = client.get('/api/historial/tomas', headers=auth_headers)
    assert res_historial2.status_code == 200
    tomas_despues = res_historial2.get_json()
    tomas_med_hoy = [t for t in tomas_despues if t['medicamento_id'] == med_id and t['fecha'] == date.today().isoformat() and t['estado'] == 'tomada']
    assert len(tomas_med_hoy) == 0


def test_consultar_historial_habitos(client, auth_headers):
    """
    Prueba la consulta de hábitos históricos con filtrado por tipo y rango de fechas.
    """
    hoy = date.today()
    ayer = hoy - timedelta(days=1)

    # 1. Registrar hábito de Agua
    res_agua = client.post('/api/habitos', json={
        'tipo': 'Agua',
        'meta': 8,
        'fecha': hoy.isoformat()
    }, headers=auth_headers)
    agua_id = res_agua.json['id']
    client.patch(f'/api/habitos/{agua_id}/progreso', json={'progreso_actual': 8}, headers=auth_headers)

    # 2. Registrar hábito de Pasos
    res_pasos = client.post('/api/habitos', json={
        'tipo': 'Caminata',
        'meta': 30,
        'fecha': ayer.isoformat()
    }, headers=auth_headers)
    pasos_id = res_pasos.json['id']
    client.patch(f'/api/habitos/{pasos_id}/progreso', json={'progreso_actual': 15}, headers=auth_headers)

    # 3. Consultar todos los hábitos históricos
    res_todos = client.get('/api/historial/habitos', headers=auth_headers)
    assert res_todos.status_code == 200
    habitos = res_todos.get_json()
    assert len(habitos) >= 2

    # 4. Filtrar por tipo 'Agua'
    res_solo_agua = client.get('/api/historial/habitos?tipo=Agua', headers=auth_headers)
    assert res_solo_agua.status_code == 200
    habitos_agua = res_solo_agua.get_json()
    assert len(habitos_agua) == 1
    assert habitos_agua[0]['tipo'] == 'Agua'
    assert habitos_agua[0]['progreso_actual'] == 8
    assert habitos_agua[0]['cumplido'] is True
    assert habitos_agua[0]['porcentaje'] == 100.0

    # 5. Filtrar por rango de fechas
    res_ayer = client.get(
        f'/api/historial/habitos?desde={ayer.isoformat()}&hasta={ayer.isoformat()}',
        headers=auth_headers
    )
    assert res_ayer.status_code == 200
    habitos_ayer = res_ayer.get_json()
    assert len(habitos_ayer) == 1
    assert habitos_ayer[0]['tipo'] == 'Caminata'
    assert habitos_ayer[0]['cumplido'] is False
