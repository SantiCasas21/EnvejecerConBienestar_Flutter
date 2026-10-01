from datetime import datetime, timedelta
from app.extensions import db
from app.models.actividad_cognitiva import ActividadCognitiva
from app.models.usuario import Usuario
from app.models.cuidador_paciente import CuidadorPaciente
from flask_jwt_extended import create_access_token


def test_guardar_puntaje_con_nivel_dificultad(client, auth_headers, test_user):
    """Prueba que el registro de puntaje guarde correctamente el juego, puntuación y dificultad."""
    # 1. Registro con dificultad 'basico'
    payload_basico = {
        "tipo_juego": "Sopa de Letras",
        "puntaje": 150,
        "nivel_dificultad": "basico"
    }
    res1 = client.post('/api/juegos/puntaje', json=payload_basico, headers=auth_headers)
    assert res1.status_code == 201
    data1 = res1.get_json()
    assert data1["tipo_juego"] == "Sopa de Letras"
    assert data1["puntaje"] == 150
    assert data1["nivel_dificultad"] == "basico"
    assert data1["usuario_id"] == test_user.id

    # 2. Registro con dificultad 'avanzado'
    payload_avanzado = {
        "tipo_juego": "Sudoku",
        "puntaje": 320,
        "nivel_dificultad": "avanzado"
    }
    res2 = client.post('/api/juegos/puntaje', json=payload_avanzado, headers=auth_headers)
    assert res2.status_code == 201
    data2 = res2.get_json()
    assert data2["tipo_juego"] == "Sudoku"
    assert data2["puntaje"] == 320
    assert data2["nivel_dificultad"] == "avanzado"

    # 3. Validación de campos requeridos faltantes
    res_invalido = client.post('/api/juegos/puntaje', json={"tipo_juego": "Sudoku"}, headers=auth_headers)
    assert res_invalido.status_code == 400


def test_get_historial_y_mejores_puntajes(client, auth_headers, test_user):
    """Prueba la consulta cronológica de historial y el Top 3 de mejores puntajes."""
    # Insertar actividades
    p1 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sudoku", puntaje=100, nivel_dificultad="basico")
    p2 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sudoku", puntaje=300, nivel_dificultad="intermedio")
    p3 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sopa de Letras", puntaje=200, nivel_dificultad="basico")
    p4 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Memoria", puntaje=150, nivel_dificultad="intermedio")
    db.session.add_all([p1, p2, p3, p4])
    db.session.commit()

    # 1. Historial
    res_hist = client.get('/api/juegos/historial?limite=10', headers=auth_headers)
    assert res_hist.status_code == 200
    historial = res_hist.get_json()
    assert len(historial) == 4

    # 2. Mejores puntajes globales (Top 3)
    res_top = client.get('/api/juegos/mejores?limite=3', headers=auth_headers)
    assert res_top.status_code == 200
    mejores = res_top.get_json()
    assert len(mejores) == 3
    assert mejores[0]["puntaje"] == 300
    assert mejores[1]["puntaje"] == 200
    assert mejores[2]["puntaje"] == 150

    # 3. Mejores puntajes filtrados por minijuego
    res_sudoku = client.get('/api/juegos/mejores?tipo_juego=Sudoku', headers=auth_headers)
    assert res_sudoku.status_code == 200
    mejores_sudoku = res_sudoku.get_json()
    assert len(mejores_sudoku) == 2
    assert mejores_sudoku[0]["puntaje"] == 300
    assert mejores_sudoku[1]["puntaje"] == 100


def test_get_estadisticas_globales(client, auth_headers, test_user):
    """Prueba el resumen estadístico de puntos totales, partidas jugadas y juego favorito."""
    p1 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sopa de Letras", puntaje=120)
    p2 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sopa de Letras", puntaje=180)
    p3 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sudoku", puntaje=250)
    db.session.add_all([p1, p2, p3])
    db.session.commit()

    res = client.get('/api/juegos/estadisticas', headers=auth_headers)
    assert res.status_code == 200
    stats = res.get_json()
    assert stats["total_puntos"] == 550
    assert stats["partidas_jugadas"] == 3
    assert stats["record_maximo"] == 250
    assert stats["juego_favorito"] == "Sopa de Letras"


def test_podio_familiar_usuario_sin_vinculos(client, auth_headers, test_user):
    """Prueba que un usuario sin familiares vinculados reciba su código de vinculación y estado no vinculado."""
    # Asignar rol y código
    test_user.rol = 'adulto_mayor'
    test_user.codigo_vinculacion = 'ECB-7788'
    db.session.commit()

    # Agregar una partida propia
    p1 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Memoria", puntaje=210)
    db.session.add(p1)
    db.session.commit()

    res = client.get('/api/juegos/podio-familiar', headers=auth_headers)
    assert res.status_code == 200
    data = res.get_json()

    assert data["hay_vinculacion"] is False
    assert data["total_miembros"] == 1
    assert data["codigo_vinculacion_usuario"] == "ECB-7788"
    assert len(data["podio"]) == 1

    item_propio = data["podio"][0]
    assert item_propio["usuario_id"] == test_user.id
    assert item_propio["es_usuario_actual"] is True
    assert item_propio["posicion"] == 1
    assert item_propio["medalla"] == "🥇"
    assert item_propio["puntaje_maximo"] == 210
    assert item_propio["partidas_jugadas"] == 1


def test_podio_familiar_con_vinculacion_familiar_completa(client):
    """Prueba la tabla de posiciones con múltiples miembros familiares, medallas y records."""
    # 1. Crear Adulto Mayor titular (Abuelo Carlos)
    abuelo = Usuario(nombre="Abuelo Carlos", email="carlos@example.com", rol="adulto_mayor", codigo_vinculacion="ECB-3030")
    abuelo.set_password("pass123")
    
    # 2. Crear Cuidadora (Hija Andrea)
    hija = Usuario(nombre="Andrea Cuidadora", email="andrea@example.com", rol="cuidador")
    hija.set_password("pass123")

    # 3. Crear Co-paciente (Hermana Beatriz)
    tia = Usuario(nombre="Tía Beatriz", email="beatriz@example.com", rol="adulto_mayor", codigo_vinculacion="ECB-4040")
    tia.set_password("pass123")

    db.session.add_all([abuelo, hija, tia])
    db.session.commit()

    # Vincular en CuidadorPaciente: Hija cuida a Abuelo Carlos y a Tía Beatriz
    v1 = CuidadorPaciente(cuidador_id=hija.id, paciente_id=abuelo.id, parentesco="Hija")
    v2 = CuidadorPaciente(cuidador_id=hija.id, paciente_id=tia.id, parentesco="Sobrina")
    db.session.add_all([v1, v2])
    db.session.commit()

    # 4. Registrar partidas cognitivas con diferentes puntajes
    # Andrea: 400 pts (Sudoku) -> Récord más alto = 🥇
    p_andrea = ActividadCognitiva(usuario_id=hija.id, tipo_juego="Sudoku", puntaje=400)
    # Beatriz: 280 pts (Sopa de Letras) -> Segundo récord = 🥈
    p_beatriz = ActividadCognitiva(usuario_id=tia.id, tipo_juego="Sopa de Letras", puntaje=280)
    # Carlos: 150 pts (Memoria) -> Tercer récord = 🥉
    p_carlos = ActividadCognitiva(usuario_id=abuelo.id, tipo_juego="Memoria", puntaje=150)
    db.session.add_all([p_andrea, p_beatriz, p_carlos])
    db.session.commit()

    # 5. Consultar podio familiar desde la sesión de Abuelo Carlos
    token_carlos = create_access_token(identity=str(abuelo.id))
    headers_carlos = {'Authorization': f'Bearer {token_carlos}'}

    res = client.get('/api/juegos/podio-familiar', headers=headers_carlos)
    assert res.status_code == 200
    data = res.get_json()

    assert data["hay_vinculacion"] is True
    assert data["total_miembros"] == 3
    podio = data["podio"]

    # Posición 1: Andrea (400)
    assert podio[0]["nombre"] == "Andrea Cuidadora"
    assert podio[0]["posicion"] == 1
    assert podio[0]["medalla"] == "🥇"
    assert podio[0]["puntaje_maximo"] == 400
    assert podio[0]["juego_record"] == "Sudoku"
    assert podio[0]["es_usuario_actual"] is False

    # Posición 2: Beatriz (280)
    assert podio[1]["nombre"] == "Tía Beatriz"
    assert podio[1]["posicion"] == 2
    assert podio[1]["medalla"] == "🥈"
    assert podio[1]["puntaje_maximo"] == 280
    assert podio[1]["juego_record"] == "Sopa de Letras"
    assert podio[1]["es_usuario_actual"] is False

    # Posición 3: Carlos (150) - Titular
    assert podio[2]["nombre"] == "Abuelo Carlos"
    assert podio[2]["posicion"] == 3
    assert podio[2]["medalla"] == "🥉"
    assert podio[2]["puntaje_maximo"] == 150
    assert podio[2]["juego_record"] == "Memoria"
    assert podio[2]["es_usuario_actual"] is True

    # 6. Filtrar podio familiar por juego (ej. Sudoku)
    res_filtro = client.get('/api/juegos/podio-familiar?tipo_juego=Sudoku', headers=headers_carlos)
    assert res_filtro.status_code == 200
    data_filtro = res_filtro.get_json()
    assert data_filtro["filtro_juego"] == "Sudoku"
    # Andrea tiene 400 en Sudoku, los demás tienen 0
    assert data_filtro["podio"][0]["nombre"] == "Andrea Cuidadora"
    assert data_filtro["podio"][0]["puntaje_maximo"] == 400


def test_historial_con_filtros_dias_y_familiar(client):
    """Prueba GET /api/juegos/historial con filtros de días (1, 3, 5, 8, 15, 30) y familiar=true."""
    # 1. Crear Paciente (Abuelo José) y Cuidador (Hijo Martín)
    paciente = Usuario(nombre="Abuelo José", email="jose@test.com", rol="adulto_mayor", codigo_vinculacion="ECB-1122")
    paciente.set_password("pass123")
    cuidador = Usuario(nombre="Hijo Martín", email="martin@test.com", rol="cuidador")
    cuidador.set_password("pass123")
    db.session.add_all([paciente, cuidador])
    db.session.commit()

    # Vinculación
    vinculo = CuidadorPaciente(cuidador_id=cuidador.id, paciente_id=paciente.id, parentesco="Hijo")
    db.session.add(vinculo)
    db.session.commit()

    ahora = datetime.utcnow()

    # Insertar actividades en fechas escalonadas:
    # - Paciente: hoy (hace 1 hora)
    act1 = ActividadCognitiva(usuario_id=paciente.id, tipo_juego="Sudoku", puntaje=200, fecha_realizacion=ahora - timedelta(hours=1))
    # - Cuidador: hace 2 días
    act2 = ActividadCognitiva(usuario_id=cuidador.id, tipo_juego="Sopa de Letras", puntaje=250, fecha_realizacion=ahora - timedelta(days=2))
    # - Paciente: hace 4 días
    act3 = ActividadCognitiva(usuario_id=paciente.id, tipo_juego="Trivia de Salud", puntaje=180, fecha_realizacion=ahora - timedelta(days=4))
    # - Cuidador: hace 7 días
    act4 = ActividadCognitiva(usuario_id=cuidador.id, tipo_juego="Buscar Pares", puntaje=300, fecha_realizacion=ahora - timedelta(days=7))
    # - Paciente: hace 12 días
    act5 = ActividadCognitiva(usuario_id=paciente.id, tipo_juego="Secuencia de Luces", puntaje=150, fecha_realizacion=ahora - timedelta(days=12))
    # - Paciente: hace 25 días
    act6 = ActividadCognitiva(usuario_id=paciente.id, tipo_juego="Sudoku", puntaje=350, fecha_realizacion=ahora - timedelta(days=25))
    # - Paciente: hace 45 días
    act7 = ActividadCognitiva(usuario_id=paciente.id, tipo_juego="Sopa de Letras", puntaje=100, fecha_realizacion=ahora - timedelta(days=45))

    db.session.add_all([act1, act2, act3, act4, act5, act6, act7])
    db.session.commit()

    token_paciente = create_access_token(identity=str(paciente.id))
    headers = {'Authorization': f'Bearer {token_paciente}'}

    # 1. Sin familiar=true, solo ve sus propias partidas
    res_solo_yo = client.get('/api/juegos/historial?familiar=false', headers=headers)
    assert res_solo_yo.status_code == 200
    hist_solo = res_solo_yo.get_json()
    assert len(hist_solo) == 5  # act1, act3, act5, act6, act7
    assert all(item["usuario_id"] == paciente.id for item in hist_solo)
    assert all(item["es_usuario_actual"] is True for item in hist_solo)
    assert all(item["nombre_jugador"] == "Abuelo José" for item in hist_solo)

    # 2. Con familiar=true, incluye al cuidador
    res_familiar = client.get('/api/juegos/historial?familiar=true', headers=headers)
    assert res_familiar.status_code == 200
    hist_fam = res_familiar.get_json()
    assert len(hist_fam) == 7
    # Verificar nombres mapeados
    nombres = {item["nombre_jugador"] for item in hist_fam}
    assert "Abuelo José" in nombres
    assert "Hijo Martín" in nombres

    # 3. Filtro días = 1 (solo últimas 24 horas: act1)
    res_d1 = client.get('/api/juegos/historial?familiar=true&dias=1', headers=headers)
    assert res_d1.status_code == 200
    items_d1 = res_d1.get_json()
    assert len(items_d1) == 1
    assert items_d1[0]["tipo_juego"] == "Sudoku"

    # 4. Filtro días = 3 (últimos 3 días: act1 de hoy y act2 de hace 2 días)
    res_d3 = client.get('/api/juegos/historial?familiar=true&dias=3', headers=headers)
    assert res_d3.status_code == 200
    assert len(res_d3.get_json()) == 2

    # 5. Filtro días = 5 (últimos 5 días: act1, act2, act3)
    res_d5 = client.get('/api/juegos/historial?familiar=true&dias=5', headers=headers)
    assert res_d5.status_code == 200
    assert len(res_d5.get_json()) == 3

    # 6. Filtro días = 8 (últimos 8 días: act1, act2, act3, act4)
    res_d8 = client.get('/api/juegos/historial?familiar=true&dias=8', headers=headers)
    assert res_d8.status_code == 200
    assert len(res_d8.get_json()) == 4

    # 7. Filtro días = 15 (últimos 15 días: act1 a act5)
    res_d15 = client.get('/api/juegos/historial?familiar=true&dias=15', headers=headers)
    assert res_d15.status_code == 200
    assert len(res_d15.get_json()) == 5

    # 8. Filtro días = 30 (últimos 30 días: act1 a act6, excluye act7 de hace 45 días)
    res_d30 = client.get('/api/juegos/historial?familiar=true&dias=30', headers=headers)
    assert res_d30.status_code == 200
    assert len(res_d30.get_json()) == 6


def test_get_puntos_por_juego_ranking_y_mas_jugado(client, auth_headers, test_user):
    """Prueba GET /api/juegos/puntos-por-juego verificando los 5 minijuegos ordenados y 'es_mas_jugado'."""
    # Partidas para test_user:
    # 1. Sopa de Letras: 4 partidas, total 500 pts, récord 200 pts
    # 2. Sudoku: 2 partidas, total 600 pts, récord 350 pts -> Mayor puntaje = 🥇 Posición 1
    # 3. Buscar Pares: 1 partida, total 100 pts, récord 100 pts
    # 4. Trivia de Salud: 0 partidas, total 0 pts
    # 5. Secuencia de Luces: 0 partidas, total 0 pts
    p1 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sudoku", puntaje=250)
    p2 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sudoku", puntaje=350)

    p3 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sopa de Letras", puntaje=100)
    p4 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sopa de Letras", puntaje=100)
    p5 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sopa de Letras", puntaje=100)
    p6 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Sopa de Letras", puntaje=200)

    p7 = ActividadCognitiva(usuario_id=test_user.id, tipo_juego="Buscar Pares", puntaje=100)

    db.session.add_all([p1, p2, p3, p4, p5, p6, p7])
    db.session.commit()

    res = client.get('/api/juegos/puntos-por-juego', headers=auth_headers)
    assert res.status_code == 200
    data = res.get_json()

    # Exactamente 5 minijuegos
    assert len(data) == 5

    # 1º Lugar en puntos: Sudoku (600 pts, récord 350, 2 partidas)
    assert data[0]["juego_id"] == "sudoku"
    assert data[0]["tipo_juego"] == "Sudoku"
    assert data[0]["total_puntos"] == 600
    assert data[0]["record_maximo"] == 350
    assert data[0]["partidas_jugadas"] == 2
    assert data[0]["posicion"] == 1
    assert data[0]["medalla"] == "🥇"
    assert data[0]["es_mas_jugado"] is False

    # 2º Lugar en puntos: Sopa de Letras (500 pts, 4 partidas) -> Es el más jugado
    assert data[1]["juego_id"] == "sopa_letras"
    assert data[1]["tipo_juego"] == "Sopa de Letras"
    assert data[1]["total_puntos"] == 500
    assert data[1]["record_maximo"] == 200
    assert data[1]["partidas_jugadas"] == 4
    assert data[1]["posicion"] == 2
    assert data[1]["medalla"] == "🥈"
    assert data[1]["es_mas_jugado"] is True  # Máximo de partidas (4)

    # 3º Lugar en puntos: Buscar Pares (100 pts, 1 partida)
    assert data[2]["juego_id"] == "buscar_pares"
    assert data[2]["total_puntos"] == 100
    assert data[2]["partidas_jugadas"] == 1
    assert data[2]["posicion"] == 3
    assert data[2]["medalla"] == "🥉"
    assert data[2]["es_mas_jugado"] is False

    # 4º y 5º: Juegos no jugados aún (0 puntos)
    assert data[3]["total_puntos"] == 0
    assert data[3]["partidas_jugadas"] == 0
    assert data[4]["total_puntos"] == 0
    assert data[4]["partidas_jugadas"] == 0

