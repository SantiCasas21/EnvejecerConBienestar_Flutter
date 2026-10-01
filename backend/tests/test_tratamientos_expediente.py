"""Tests para el Módulo 3: Tratamientos Clínicos, Ficha Médica Integral y Expediente Clínico."""
from datetime import date, time
from app.extensions import db
from app.models.tratamiento import Tratamiento
from app.models.medicamento import Medicamento
from app.models.perfil import PerfilUsuario
from app.models.usuario import Usuario
from flask_jwt_extended import create_access_token

def test_crear_tratamiento_con_campos_clinicos(client, auth_headers, test_user):
    """Prueba que un tratamiento se cree con los nuevos campos clínicos enriquecidos."""
    payload = {
        "diagnostico": "Hipertensión Arterial Grado II",
        "especialidad_medica": "Cardiología",
        "medico_tratante": "Dra. Sofía Rivas",
        "institucion_salud": "Fundación Santa Fe",
        "fecha_inicio": "2026-01-10",
        "es_cronico": True,
        "estado": "activo",
        "objetivo_terapeutico": "Mantener TA < 130/80 mmHg",
        "notas_evolucion": "Presión estable en último control.",
        "recomendaciones": "Dieta hiposódica estricta.",
        "fecha_ultima_revision": "2026-08-15",
        "proxima_cita": "2026-11-20",
        "color": "#0D9488"
    }

    res = client.post('/api/tratamientos', json=payload, headers=auth_headers)
    assert res.status_code == 201
    data = res.get_json()

    assert data["diagnostico"] == "Hipertensión Arterial Grado II"
    assert data["especialidad_medica"] == "Cardiología"
    assert data["objetivo_terapeutico"] == "Mantener TA < 130/80 mmHg"
    assert data["notas_evolucion"] == "Presión estable en último control."
    assert data["recomendaciones"] == "Dieta hiposódica estricta."
    assert data["fecha_ultima_revision"] == "2026-08-15"
    assert data["proxima_cita"] == "2026-11-20"
    assert data["es_cronico"] is True

def test_adherencia_tratamiento_calculada(client, auth_headers, test_user):
    """Prueba que la adherencia calculada refleje el porcentaje de tomas de hoy."""
    # 1. Crear tratamiento
    t = Tratamiento(
        usuario_id=test_user.id,
        diagnostico="Diabetes Tipo 2",
        especialidad_medica="Endocrinología",
        es_cronico=True
    )
    db.session.add(t)
    db.session.commit()

    # 2. Asociar dos medicamentos: uno tomado y uno pendiente
    m1 = Medicamento(
        usuario_id=test_user.id,
        tratamiento_id=t.id,
        nombre="Metformina",
        miligramos="850 mg",
        esta_tomado=True
    )
    m2 = Medicamento(
        usuario_id=test_user.id,
        tratamiento_id=t.id,
        nombre="Glibenclamida",
        miligramos="5 mg",
        esta_tomado=False
    )
    db.session.add_all([m1, m2])
    db.session.commit()

    assert t.adherencia_porcentaje == 50.0

    res = client.get(f'/api/tratamientos/{t.id}', headers=auth_headers)
    assert res.status_code == 200
    data = res.get_json()
    assert data["adherencia_porcentaje"] == 50.0
    assert len(data["medicamentos"]) == 2

def test_actualizar_perfil_con_ficha_clinica_completa(client, auth_headers, test_user):
    """Prueba que el perfil registre identificación oficial, régimen EPS y antecedentes."""
    payload = {
        "tipo_documento": "CC",
        "numero_documento": "19482903",
        "edad": 75,
        "genero": "Masculino",
        "tipo_sangre": "O+",
        "peso": 70.0,
        "altura": 170.0,
        "eps": "SURA EPS",
        "regimen_eps": "Contributivo",
        "presion_habitual": "125/80 mmHg",
        "nivel_movilidad": "Uso de bastón",
        "alergias": "Penicilina",
        "condiciones": "Hipertensión Arterial",
        "restricciones_alimentarias": "Baja en sodio",
        "antecedentes_familiares": "Padre con infarto a los 68 años"
    }

    res = client.put('/api/perfil', json=payload, headers=auth_headers)
    assert res.status_code == 200
    data = res.get_json()

    assert data["tipo_documento"] == "CC"
    assert data["numero_documento"] == "19482903"
    assert data["regimen_eps"] == "Contributivo"
    assert data["presion_habitual"] == "125/80 mmHg"
    assert data["nivel_movilidad"] == "Uso de bastón"
    assert data["alergias"] == "Penicilina"
    assert data["restricciones_alimentarias"] == "Baja en sodio"
    assert data["antecedentes_familiares"] == "Padre con infarto a los 68 años"
    # IMC: 70 / (1.70 * 1.70) = 24.2 (Peso saludable)
    assert data["imc"] == 24.2
    assert data["clasificacion_imc"] == "Peso saludable"

def test_get_expediente_clinico_completo(client, auth_headers, test_user):
    """Prueba que el endpoint unificado de expediente clínico retorne toda la información consolidada."""
    # Configurar perfil
    perfil = PerfilUsuario(
        usuario_id=test_user.id,
        tipo_documento="CC",
        numero_documento="19482903",
        alergias="Penicilina",
        condiciones="Hipertensión",
        contacto_emergencia_nombre="Ana Hija",
        contacto_emergencia_telefono="3001234567"
    )
    db.session.add(perfil)

    # Configurar tratamiento con medicamento
    t = Tratamiento(
        usuario_id=test_user.id,
        diagnostico="Hipertensión Arterial",
        especialidad_medica="Cardiología",
        estado="activo"
    )
    db.session.add(t)
    db.session.flush()

    m = Medicamento(
        usuario_id=test_user.id,
        tratamiento_id=t.id,
        nombre="Losartán",
        miligramos="50 mg",
        esta_tomado=True
    )
    # Medicamento huérfano / SOS
    m_sos = Medicamento(
        usuario_id=test_user.id,
        tratamiento_id=None,
        nombre="Acetaminofén",
        miligramos="500 mg",
        esta_tomado=False
    )
    db.session.add_all([m, m_sos])
    db.session.commit()

    res = client.get('/api/expediente-clinico', headers=auth_headers)
    assert res.status_code == 200
    exp = res.get_json()

    assert exp["paciente"]["nombre"] == test_user.nombre
    assert exp["perfil_medico"]["alergias"] == "Penicilina"
    assert len(exp["tratamientos_activos"]) == 1
    assert exp["tratamientos_activos"][0]["diagnostico"] == "Hipertensión Arterial"
    assert len(exp["tratamientos_activos"][0]["medicamentos_vinculados"]) == 1
    assert len(exp["medicamentos_independientes"]) == 1
    assert exp["medicamentos_independientes"][0]["nombre"] == "Acetaminofén"
    assert exp["resumen_adherencia"]["total_medicamentos"] == 2
    assert exp["resumen_adherencia"]["tomados_hoy"] == 1
    assert exp["resumen_adherencia"]["porcentaje_adherencia"] == 50.0

def test_get_contexto_ia_formato_seguro(client, auth_headers, test_user):
    """Prueba que el resumen para IA contenga las alertas críticas y directrices de seguridad."""
    perfil = PerfilUsuario(
        usuario_id=test_user.id,
        alergias="Penicilina, Sulfas",
        condiciones="Hipertensión Severa"
    )
    db.session.add(perfil)
    db.session.commit()

    res = client.get('/api/expediente-clinico/contexto-ia', headers=auth_headers)
    assert res.status_code == 200
    data = res.get_json()

    contexto = data["contexto_ia"]
    assert "EXPEDIENTE CLÍNICO INTEGRAL — CONTEXTO IA" in contexto
    assert "Penicilina, Sulfas" in contexto
    assert "DIRECTRICES DE SEGURIDAD Y GUARDRAILS CLÍNICOS PARA LA IA" in contexto
    assert "NUNCA prescribas medicamentos" in contexto
    assert "Botón SOS" in contexto

def test_cuidador_gestiona_tratamientos_paciente(client):
    """Prueba el flujo completo donde un cuidador supervisa y gestiona tratamientos de su paciente."""
    # 1. Registrar paciente y cuidador
    res_pac = client.post('/api/auth/register', json={
        'nombre': 'Abuelo Jaime',
        'email': 'jaime@example.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_pac.get_json()['usuario']['id']
    codigo = res_pac.get_json()['usuario']['codigo_vinculacion']

    res_cuid = client.post('/api/auth/register', json={
        'nombre': 'Laura Cuidadora',
        'email': 'laura@example.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_cuidador = res_cuid.get_json()['access_token']
    cuid_headers = {'Authorization': f'Bearer {token_cuidador}'}

    # 2. Vincular
    res_vinc = client.post('/api/cuidadores/vincular', json={
        'codigo_vinculacion': codigo,
        'parentesco': 'Hija'
    }, headers=cuid_headers)
    assert res_vinc.status_code == 201

    # 3. Cuidador crea tratamiento para el paciente
    payload_trat = {
        'diagnostico': 'Osteoartritis de rodilla',
        'especialidad_medica': 'Reumatología',
        'medico_tratante': 'Dr. Salazar',
        'estado': 'activo',
        'recomendaciones': 'Terapia física 2 veces por semana.'
    }
    res_create = client.post(f'/api/cuidadores/pacientes/{paciente_id}/tratamientos', json=payload_trat, headers=cuid_headers)
    assert res_create.status_code == 201
    trat_id = res_create.get_json()['id']
    assert res_create.get_json()['diagnostico'] == 'Osteoartritis de rodilla'

    # 4. Cuidador lista tratamientos del paciente
    res_list = client.get(f'/api/cuidadores/pacientes/{paciente_id}/tratamientos', headers=cuid_headers)
    assert res_list.status_code == 200
    lista = res_list.get_json()
    assert len(lista) == 1
    assert lista[0]['diagnostico'] == 'Osteoartritis de rodilla'

    # 5. Cuidador consulta expediente clínico del paciente
    res_exp = client.get(f'/api/expediente-clinico?paciente_id={paciente_id}', headers=cuid_headers)
    assert res_exp.status_code == 200
    exp = res_exp.get_json()
    assert exp['paciente']['nombre'] == 'Abuelo Jaime'
    assert len(exp['tratamientos_activos']) == 1

def test_cuidador_no_autorizado_recibe_403(client):
    """Prueba que un usuario sin vínculo no pueda acceder al expediente de otro paciente."""
    # 1. Registrar paciente y un cuidador NO vinculado
    res_pac = client.post('/api/auth/register', json={
        'nombre': 'Don Luis',
        'email': 'luis@example.com',
        'password': 'password123',
        'rol': 'adulto_mayor'
    })
    paciente_id = res_pac.get_json()['usuario']['id']

    res_cuid = client.post('/api/auth/register', json={
        'nombre': 'Cuidador Intruso',
        'email': 'intruso@example.com',
        'password': 'password123',
        'rol': 'cuidador'
    })
    token_intruso = res_cuid.get_json()['access_token']
    intruso_headers = {'Authorization': f'Bearer {token_intruso}'}

    # Intentar ver tratamientos -> 403 Forbidden
    res_trat = client.get(f'/api/cuidadores/pacientes/{paciente_id}/tratamientos', headers=intruso_headers)
    assert res_trat.status_code == 403

    # Intentar ver expediente -> 403 Forbidden
    res_exp = client.get(f'/api/expediente-clinico?paciente_id={paciente_id}', headers=intruso_headers)
    assert res_exp.status_code == 403

def test_prediccion_adherencia_ml(client, auth_headers, test_user):
    """Prueba el endpoint de Machine Learning para predicción de adherencia y riesgo de omisión."""
    # Configurar paciente con medicamento bajo stock
    m = Medicamento(
        usuario_id=test_user.id,
        nombre="Losartán",
        miligramos="50",
        frecuencia=8,
        cantidad_restante=2  # Stock crítico <= 5 activa feature de riesgo
    )
    db.session.add(m)
    db.session.commit()

    res = client.get('/api/expediente-clinico/prediccion-adherencia-ml', headers=auth_headers)
    assert res.status_code == 200
    data = res.get_json()
    assert "probabilidad_omision" in data
    assert "score_adherencia_estimada" in data
    assert "categoria_riesgo" in data
    assert "factores_riesgo_detectados" in data
    assert "modelo_ml" in data
    assert data["modelo_ml"]["nombre"] == "Geriatric Adherence Logistic Classifier (GALC-v1)"
    assert len(data["factores_riesgo_detectados"]) >= 1

