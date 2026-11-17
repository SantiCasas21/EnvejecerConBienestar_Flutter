"""Pruebas automatizadas del Módulo 9: Asistente de Salud IA (DeepSeek)."""
import json
from unittest.mock import patch
from app.extensions import db
from app.models.meta import Meta
from app.models.medicamento import Medicamento
from app.models.perfil import PerfilUsuario


def test_asistente_requiere_auth(client):
    """El endpoint del asistente debe exigir autenticación JWT."""
    res = client.post('/api/asistente/chat', json={'mensaje': 'Hola'})
    assert res.status_code == 401


def test_asistente_mensaje_vacio(client, auth_headers):
    """Debe rechazar mensajes vacíos con código 400."""
    res = client.post('/api/asistente/chat', json={'mensaje': '   '}, headers=auth_headers)
    assert res.status_code == 400


def test_asistente_chat_y_historial(client, auth_headers):
    """Debe procesar respuesta de DeepSeek, persistir historial y permitir limpiarlo."""
    fake_resp = {
        'choices': [
            {'message': {'role': 'assistant', 'content': 'Hola, ¿cómo amaneciste hoy con tus medicinas?'}}
        ]
    }
    with patch('app.services.asistente_service.AsistenteService._call_deepseek', return_value=fake_resp):
        res = client.post('/api/asistente/chat', json={'mensaje': 'Hola'}, headers=auth_headers)

    assert res.status_code == 200
    data = res.get_json()
    assert data['respuesta_asistente']['contenido'] == 'Hola, ¿cómo amaneciste hoy con tus medicinas?'

    hist_res = client.get('/api/asistente/historial', headers=auth_headers)
    assert hist_res.status_code == 200
    assert len(hist_res.get_json()['mensajes']) == 2

    del_res = client.delete('/api/asistente/historial', headers=auth_headers)
    assert del_res.status_code == 200
    assert del_res.get_json()['eliminados'] == 2


def test_asistente_tool_habito_directo(client, auth_headers, test_user):
    """Debe ejecutar registrar_progreso_habito y reportar entidades_actualizadas."""
    meta = Meta(usuario_id=test_user.id, nombre='Tomar agua', objetivo=8, progreso=2, unidad='vasos', icono='💧')
    db.session.add(meta)
    db.session.commit()

    tool_resp = {
        'choices': [
            {
                'message': {
                    'role': 'assistant',
                    'content': '',
                    'tool_calls': [
                        {
                            'id': 'call_1',
                            'type': 'function',
                            'function': {
                                'name': 'registrar_progreso_habito',
                                'arguments': json.dumps({'meta_id': meta.id, 'incremento': 2}),
                            },
                        }
                    ],
                }
            }
        ]
    }
    final_resp = {
        'choices': [
            {'message': {'role': 'assistant', 'content': '¡Excelente! Ya sumé 2 vasos de agua a tu meta.'}}
        ]
    }

    with patch('app.services.asistente_service.AsistenteService._call_deepseek', side_effect=[tool_resp, final_resp]):
        res = client.post('/api/asistente/chat', json={'mensaje': 'Tomé 2 vasos de agua'}, headers=auth_headers)

    assert res.status_code == 200
    data = res.get_json()
    assert 'metas' in data['entidades_actualizadas']
    db.session.refresh(meta)
    assert meta.progreso == 4


def test_asistente_bloquea_medicamento_con_alergia(client, auth_headers, test_user):
    """Debe bloquear la propuesta de un medicamento que cruza con alergia a AINEs."""
    perfil = PerfilUsuario(usuario_id=test_user.id, alergias='Penicilina, AINEs', condiciones='Hipertensión Arterial')
    db.session.add(perfil)
    db.session.commit()

    tool_resp = {
        'choices': [
            {
                'message': {
                    'role': 'assistant',
                    'content': '',
                    'tool_calls': [
                        {
                            'id': 'call_med_riesgo',
                            'type': 'function',
                            'function': {
                                'name': 'proponer_accion_clinica',
                                'arguments': json.dumps({
                                    'tipo': 'crear_medicamento',
                                    'resumen': 'Agregar Ibuprofeno 400mg',
                                    'datos': {'nombre': 'Ibuprofeno', 'miligramos': '400mg'},
                                }),
                            },
                        }
                    ],
                }
            }
        ]
    }
    final_resp = {
        'choices': [
            {
                'message': {
                    'role': 'assistant',
                    'content': 'Ten mucho cuidado: eres alérgico a los AINEs. Consulta primero con tu médico.',
                }
            }
        ]
    }

    with patch('app.services.asistente_service.AsistenteService._call_deepseek', side_effect=[tool_resp, final_resp]):
        res = client.post('/api/asistente/chat', json={'mensaje': 'Agrégama Ibuprofeno 400mg'}, headers=auth_headers)

    assert res.status_code == 200
    resp_msg = res.get_json()['respuesta_asistente']
    assert resp_msg['alerta_preventiva'] is not None
    assert 'AINE' in resp_msg['alerta_preventiva']
    assert resp_msg['accion_pendiente'] is None


def test_asistente_propuesta_y_confirmacion_medicamento_seguro(client, auth_headers, test_user):
    """Debe proponer medicamento seguro y guardarlo en BD solo tras confirmación."""
    tool_resp = {
        'choices': [
            {
                'message': {
                    'role': 'assistant',
                    'content': '',
                    'tool_calls': [
                        {
                            'id': 'call_med_ok',
                            'type': 'function',
                            'function': {
                                'name': 'proponer_accion_clinica',
                                'arguments': json.dumps({
                                    'tipo': 'crear_medicamento',
                                    'resumen': 'Guardar Vitamina D3 1000 UI cada 24 horas',
                                    'datos': {'nombre': 'Vitamina D3', 'miligramos': '1000 UI', 'frecuencia': 24},
                                }),
                            },
                        }
                    ],
                }
            }
        ]
    }
    final_resp = {
        'choices': [
            {'message': {'role': 'assistant', 'content': 'Preparé el registro de Vitamina D3. ¿Confirmas guardarlo?'}}
        ]
    }

    with patch('app.services.asistente_service.AsistenteService._call_deepseek', side_effect=[tool_resp, final_resp]):
        res = client.post('/api/asistente/chat', json={'mensaje': 'Quiero agregar Vitamina D3'}, headers=auth_headers)

    assert res.status_code == 200
    msg_id = res.get_json()['respuesta_asistente']['id']
    assert res.get_json()['respuesta_asistente']['accion_pendiente']['estado'] == 'pendiente'
    assert Medicamento.query.filter_by(usuario_id=test_user.id).count() == 0

    conf_res = client.post(
        '/api/asistente/confirmar-accion',
        json={'mensaje_id': msg_id, 'aceptar': True},
        headers=auth_headers,
    )
    assert conf_res.status_code == 200
    assert 'medicamentos' in conf_res.get_json()['entidades_actualizadas']
    assert Medicamento.query.filter_by(usuario_id=test_user.id, nombre='Vitamina D3').count() == 1
