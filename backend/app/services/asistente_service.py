"""Servicio del Asistente de Salud IA con DeepSeek y Guardrails Clínicos (Módulo 9)."""
import json
import ssl
import urllib.request
import urllib.error
from typing import Any, Dict, List, Optional, Tuple
from flask import current_app
from app.extensions import db
from app.models.mensaje_ia import MensajeIA
from app.services.expediente_service import ExpedienteService
from app.services.medicamento_service import MedicamentoService
from app.services.tratamiento_service import TratamientoService
from app.services.meta_service import MetaService
from app.services.perfil_service import PerfilService


class AsistenteService:
    """Orquestador conversacional seguro con DeepSeek y herramientas de la app."""

    MAX_TOOL_ROUNDS = 3
    HISTORY_LIMIT = 14

    # Reglas deterministas de respaldo para detección rápida de conflictos comunes
    _GRUPOS_ALERGIA = {
        'aine': ['ibuprofeno', 'naproxeno', 'diclofenaco', 'ketoprofeno', 'meloxicam', 'celecoxib', 'piroxicam', 'indometacina', 'aspirina', 'acido acetilsalicilico', 'ácido acetilsalicílico', 'advil', 'dolex forte'],
        'penicilina': ['penicilina', 'amoxicilina', 'ampicilina', 'oxacilina', 'dicloxacilina', 'piperacilina', 'augmentin'],
        'sulfa': ['sulfametoxazol', 'trimetoprim', 'bactrim', 'sulfadiazina'],
        'cefalosporina': ['cefalexina', 'ceftriaxona', 'cefuroxima', 'cefazolina'],
    }

    @staticmethod
    def _normalizar(texto: Optional[str]) -> str:
        if not texto:
            return ''
        reemplazos = str.maketrans('áéíóúüñ', 'aeiouun')
        return texto.lower().translate(reemplazos).strip()

    @classmethod
    def verificar_conflicto_medicamento(cls, nombre_med: str, expediente: Dict[str, Any]) -> Optional[str]:
        """
        Verificación determinista de respaldo en servidor para detectar cruces obvios
        con alergias, condiciones crónicas o duplicidades en tratamientos activos.
        """
        med_norm = cls._normalizar(nombre_med)
        if not med_norm:
            return None

        perfil = expediente.get('perfil_medico', {})
        alergias_norm = cls._normalizar(perfil.get('alergias'))
        condiciones_norm = cls._normalizar(perfil.get('condiciones'))

        # 1. Coincidencia directa con alergia registrada
        if alergias_norm and alergias_norm not in ('ninguna', 'ninguna reportada', 'no'):
            if med_norm in alergias_norm:
                return (
                    f"⚠️ Posible conflicto con alergia registrada: '{nombre_med}' coincide con "
                    f"las alergias de tu ficha ({perfil.get('alergias')}). Consulta a tu médico antes de tomarlo."
                )

            # 2. Coincidencia por grupo farmacológico
            for grupo, farmacos in cls._GRUPOS_ALERGIA.items():
                if grupo in alergias_norm and any(f in med_norm for f in farmacos):
                    return (
                        f"⚠️ Precaución por alergia: '{nombre_med}' pertenece al grupo '{grupo.upper()}', "
                        f"y en tu historial figura alergia a '{perfil.get('alergias')}'. "
                        f"No lo tomes sin confirmar primero con tu médico tratante."
                    )

        # 3. Riesgo AINEs en Hipertensión / Enfermedad Renal
        aines = cls._GRUPOS_ALERGIA['aine']
        if any(f in med_norm for f in aines) and (
            'hipertension' in condiciones_norm or 'presion' in condiciones_norm or 'renal' in condiciones_norm
        ):
            return (
                f"⚠️ Precaución clínica: '{nombre_med}' es un antiinflamatorio (AINE) que puede elevar la "
                f"presión arterial o afectar el control de '{perfil.get('condiciones')}'. "
                f"Consulta a tu médico antes de usarlo."
            )

        # 4. Duplicidad con medicamentos ya activos
        tratamientos = expediente.get('tratamientos_activos', [])
        meds_indep = expediente.get('medicamentos_independientes', [])
        todos = list(meds_indep)
        for t in tratamientos:
            todos.extend(t.get('medicamentos_vinculados', []))

        for m in todos:
            existente = cls._normalizar(m.get('nombre'))
            if existente and (existente == med_norm or existente in med_norm or med_norm in existente):
                return (
                    f"⚠️ Posible duplicidad: ya tienes registrado '{m.get('nombre')} "
                    f"{m.get('miligramos') or ''}' en tu rutina actual. Verifica con tu médico si es un reemplazo o ajuste."
                )

        return None

    @staticmethod
    def _call_deepseek(messages: List[Dict[str, Any]], tools: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        """Realiza la petición HTTPS a la API de DeepSeek (formato compatible OpenAI)."""
        api_key = current_app.config.get('DEEPSEEK_API_KEY') or ''
        if not api_key or api_key == 'sk-your-deepseek-api-key-here':
            raise ValueError(
                'El servicio de Asistente IA no tiene configurada la clave DEEPSEEK_API_KEY en el servidor.'
            )

        base_url = (current_app.config.get('DEEPSEEK_BASE_URL') or 'https://api.deepseek.com').rstrip('/')
        model = current_app.config.get('DEEPSEEK_MODEL') or 'deepseek-chat'
        url = f'{base_url}/chat/completions'

        payload: Dict[str, Any] = {
            'model': model,
            'messages': messages,
            'temperature': 0.3,
            'max_tokens': 900,
        }
        if tools:
            payload['tools'] = tools
            payload['tool_choice'] = 'auto'

        data = json.dumps(payload, ensure_ascii=False).encode('utf-8')
        req = urllib.request.Request(
            url,
            data=data,
            headers={
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {api_key}',
            },
            method='POST',
        )

        ctx = ssl.create_default_context()
        try:
            with urllib.request.urlopen(req, timeout=55, context=ctx) as resp:
                body = resp.read().decode('utf-8')
                return json.loads(body)
        except urllib.error.HTTPError as e:
            err_body = e.read().decode('utf-8', errors='ignore')
            raise RuntimeError(f'Error de DeepSeek ({e.code}): {err_body}') from e
        except urllib.error.URLError as e:
            raise RuntimeError(f'No se pudo conectar con DeepSeek: {e.reason}') from e

    @staticmethod
    def _build_tools() -> List[Dict[str, Any]]:
        """Define las herramientas (Function Calling) disponibles para DeepSeek."""
        return [
            {
                'type': 'function',
                'function': {
                    'name': 'consultar_prediccion_adherencia',
                    'description': 'Obtiene el análisis predictivo de adherencia terapéutica (GALC-v1) y factores de riesgo del paciente.',
                    'parameters': {'type': 'object', 'properties': {}},
                },
            },
            {
                'type': 'function',
                'function': {
                    'name': 'marcar_toma_medicamento',
                    'description': 'Marca como tomada o pendiente una medicina existente del paciente para el día de hoy.',
                    'parameters': {
                        'type': 'object',
                        'properties': {
                            'medicamento_id': {
                                'type': 'integer',
                                'description': 'ID numérico del medicamento en el expediente del paciente.',
                            }
                        },
                        'required': ['medicamento_id'],
                    },
                },
            },
            {
                'type': 'function',
                'function': {
                    'name': 'registrar_progreso_habito',
                    'description': 'Suma progreso a una meta o hábito de bienestar existente (ej. vasos de agua, minutos de caminata).',
                    'parameters': {
                        'type': 'object',
                        'properties': {
                            'meta_id': {'type': 'integer', 'description': 'ID numérico de la meta o hábito.'},
                            'incremento': {'type': 'integer', 'description': 'Cantidad positiva a sumar al progreso actual.'},
                        },
                        'required': ['meta_id', 'incremento'],
                    },
                },
            },
            {
                'type': 'function',
                'function': {
                    'name': 'proponer_accion_clinica',
                    'description': (
                        'Propone crear o modificar un medicamento, tratamiento/cita, alergia del perfil o hábito para que '
                        'el usuario lo confirme con un toque en pantalla. NUNCA la uses si el medicamento tiene riesgo grave '
                        'con alergias; en ese caso solo emite la alerta preventiva.'
                    ),
                    'parameters': {
                        'type': 'object',
                        'properties': {
                            'tipo': {
                                'type': 'string',
                                'enum': [
                                    'crear_medicamento',
                                    'actualizar_medicamento',
                                    'crear_tratamiento',
                                    'actualizar_tratamiento',
                                    'actualizar_alergias_perfil',
                                    'crear_habito',
                                ],
                                'description': 'Tipo de acción a confirmar por el usuario.',
                            },
                            'resumen': {
                                'type': 'string',
                                'description': 'Descripción clara y sencilla para el adulto mayor de lo que se guardará.',
                            },
                            'datos': {
                                'type': 'object',
                                'description': (
                                    'Campos exactos según el tipo. Para crear_medicamento: nombre, miligramos, frecuencia (int horas), '
                                    'hora_alarma (HH:MM), cantidad_restante (int), notas. Para actualizar_medicamento: id + campos a cambiar. '
                                    'Para crear_tratamiento: diagnostico, especialidad_medica, medico_tratante, es_cronico (bool), proxima_cita (YYYY-MM-DD), recomendaciones. '
                                    'Para actualizar_tratamiento: id + campos. Para actualizar_alergias_perfil: alergias, condiciones, restricciones_alimentarias. '
                                    'Para crear_habito: nombre, objetivo (int), unidad, icono.'
                                ),
                            },
                        },
                        'required': ['tipo', 'resumen', 'datos'],
                    },
                },
            },
            {
                'type': 'function',
                'function': {
                    'name': 'reportar_alerta_clinica',
                    'description': 'Emite una tarjeta visual de alerta preventiva (ámbar) por cruce de medicamentos/alergias o una alerta de emergencia SOS (roja).',
                    'parameters': {
                        'type': 'object',
                        'properties': {
                            'mensaje_alerta': {
                                'type': 'string',
                                'description': 'Explicación clara y serena del riesgo detectado o instrucción de emergencia.',
                            },
                            'es_emergencia': {
                                'type': 'boolean',
                                'description': 'True únicamente ante síntomas de urgencia vital (dolor torácico, disnea, síncope, etc.).',
                            },
                        },
                        'required': ['mensaje_alerta', 'es_emergencia'],
                    },
                },
            },
        ]

    @staticmethod
    def _build_system_prompt(paciente_id: int, es_cuidador: bool) -> Tuple[str, Dict[str, Any]]:
        """Construye el prompt del sistema con el expediente clínico y los IDs exactos."""
        contexto_ia = ExpedienteService.get_contexto_ia(paciente_id)
        exp = ExpedienteService.get_expediente_completo(paciente_id)

        # Lista estructurada de IDs para que las herramientas puedan referenciar registros exactos
        referencias = ['REFERENCIAS EXACTAS DE REGISTROS (usa estos IDs en herramientas):']
        todos_meds = list(exp.get('medicamentos_independientes', []))
        for t in exp.get('tratamientos_activos', []):
            referencias.append(
                f"  - Tratamiento [ID: {t['id']}]: {t['diagnostico']} | Próxima cita: {t.get('proxima_cita') or 'Sin fecha'}"
            )
            todos_meds.extend(t.get('medicamentos_vinculados', []))

        for m in todos_meds:
            estado = 'Tomado hoy' if m.get('esta_tomado') else 'Pendiente hoy'
            referencias.append(
                f"  - Medicamento [ID: {m['id']}]: {m['nombre']} {m.get('miligramos') or ''} | "
                f"cada {m.get('frecuencia', 24)}h | stock: {m.get('cantidad_restante', 0)} | {estado}"
            )

        for meta in exp.get('metas_estilo_vida', []):
            referencias.append(
                f"  - Hábito/Meta [ID: {meta['id']}]: {meta['nombre']} ({meta['progreso']}/{meta['objetivo']} {meta.get('unidad', '')})"
            )

        medico = exp.get('perfil_medico', {}).get('medico_tratante') or 'su médico tratante'
        rol_usuario = 'un cuidador familiar autorizado' if es_cuidador else 'el paciente adulto mayor'

        instrucciones = f"""Eres "Bienestar IA", el asistente virtual empático de la aplicación "Envejecer con Bienestar".
Actualmente conversas con {rol_usuario}.

REGLAS ESTRICTAS DE DELIMITACIÓN Y SEGURIDAD CLÍNICA:
1. ALCANCE EXCLUSIVO: Solo puedes hablar sobre la salud preventiva del paciente, sus medicamentos, tratamientos, alergias, citas médicas, hábitos de bienestar, reportes y uso de la app "Envejecer con Bienestar". Si te preguntan por temas ajenos (política, programación, chistes sin relación, tareas escolares, etc.), declina con calidez y redirige a su salud o rutina en la app.
2. PROHIBIDO RECETAR O DIAGNOSTICAR: Nunca prescribas medicamentos, nunca cambies dosis por tu cuenta y nunca des diagnósticos médicos definitivos.
3. VERIFICACIÓN OBLIGATORIA DE SEGURIDAD EN MEDICAMENTOS:
   - Si mencionan un medicamento nuevo o piden agregarlo/evaluarlo, SIEMPRE compáralo primero contra las ALERGIAS, CONDICIONES CRÓNICAS, RESTRICCIONES y TRATAMIENTOS ACTIVOS del expediente.
   - Si existe cualquier riesgo de alergia, interacción o contraindicación, NO propongas guardarlo; llama a `reportar_alerta_clinica(es_emergencia=False)` explicando claramente por qué podría ser perjudicial según su historial y recomienda consultar nuevamente con {medico} antes de tomarlo.
   - Si no hay conflicto evidente y desean registrarlo en su agenda porque el médico ya lo formuló, usa `proponer_accion_clinica` para que el usuario lo confirme con un toque.
4. PROTOCOLO DE EMERGENCIA: Si reportan síntomas graves (dolor en el pecho, falta de aire súbita, desmayo, pérdida de fuerza o habla, sangrado severo), llama inmediatamente a `reportar_alerta_clinica(es_emergencia=True)` e instruye presionar el Botón SOS rojo de la app o acudir a urgencias.
5. TONO Y FORMATO: Usa español claro, afectuoso, paciente y fácil de leer para adultos mayores (frases cortas, listas breves, sin tecnicismos abrumadores).
6. SEGUIMIENTO DE SALUD, MOTIVACIÓN Y HÁBITOS: Actúa como un acompañante cercano para que el paciente no desista de su tratamiento médico. Celebra sus logros (tomas cumplidas, racha, metas), dale ánimo sin culpas si olvidó alguna dosis, y según sus actividades y metas actuales, sugiérele de forma amable 1 o 2 hábitos saludables realistas (hidratación, caminata suave, sol y vitamina D, estiramientos, sueño reparador, fruta/verdura, llamada familiar o gimnasio mental) que pueda empezar o mejorar usando `proponer_accion_clinica(tipo='crear_habito')`.

{contexto_ia}

{chr(10).join(referencias)}
"""
        return instrucciones, exp

    @classmethod
    def _ejecutar_tool(
        cls,
        nombre_tool: str,
        args: Dict[str, Any],
        paciente_id: int,
        expediente: Dict[str, Any],
        estado_turno: Dict[str, Any],
    ) -> str:
        """Ejecuta una herramienta del backend solicitada por DeepSeek."""
        if nombre_tool == 'consultar_prediccion_adherencia':
            res = ExpedienteService.predecir_adherencia_ml(paciente_id)
            return json.dumps(res, ensure_ascii=False)

        if nombre_tool == 'marcar_toma_medicamento':
            med_id = int(args.get('medicamento_id', 0))
            med = MedicamentoService.toggle_tomado(med_id, paciente_id)
            if not med:
                return json.dumps({'ok': False, 'error': 'Medicamento no encontrado para este paciente.'})
            estado_turno['entidades_actualizadas'].update(['medicamentos', 'historial'])
            return json.dumps(
                {
                    'ok': True,
                    'nombre': med.nombre,
                    'esta_tomado': bool(med.esta_tomado),
                    'cantidad_restante': med.cantidad_restante,
                },
                ensure_ascii=False,
            )

        if nombre_tool == 'registrar_progreso_habito':
            meta_id = int(args.get('meta_id', 0))
            incremento = int(args.get('incremento', 1))
            meta = MetaService.incrementar_progreso(meta_id, incremento, paciente_id)
            if not meta:
                return json.dumps({'ok': False, 'error': 'Hábito/meta no encontrado.'})
            estado_turno['entidades_actualizadas'].add('metas')
            return json.dumps(
                {
                    'ok': True,
                    'nombre': meta.nombre,
                    'progreso': meta.progreso,
                    'objetivo': meta.objetivo,
                    'completada': meta.completada,
                },
                ensure_ascii=False,
            )

        if nombre_tool == 'reportar_alerta_clinica':
            alerta = args.get('mensaje_alerta', '').strip()
            es_emerg = bool(args.get('es_emergencia', False))
            if alerta:
                estado_turno['alerta_preventiva'] = alerta
            if es_emerg:
                estado_turno['es_emergencia'] = True
            return json.dumps({'ok': True, 'alerta_registrada': True})

        if nombre_tool == 'proponer_accion_clinica':
            tipo = args.get('tipo', '')
            datos = args.get('datos') or {}
            resumen = args.get('resumen', 'Confirmar cambio en tu expediente')

            # Red de seguridad determinista si proponen un medicamento
            if tipo in ('crear_medicamento', 'actualizar_medicamento'):
                nombre_med = datos.get('nombre', '')
                conflicto = cls.verificar_conflicto_medicamento(nombre_med, expediente)
                if conflicto:
                    estado_turno['alerta_preventiva'] = conflicto
                    return json.dumps(
                        {
                            'ok': False,
                            'bloqueado_por_seguridad': True,
                            'motivo': conflicto,
                            'instruccion': 'No guardes este medicamento. Explica al usuario el conflicto detectado y recomienda consultar al médico.',
                        },
                        ensure_ascii=False,
                    )

            estado_turno['accion_pendiente'] = {
                'tipo': tipo,
                'resumen': resumen,
                'datos': datos,
                'estado': 'pendiente',
            }
            return json.dumps(
                {'ok': True, 'propuesta_lista': True, 'mensaje': 'El usuario verá un botón para confirmar o cancelar.'},
                ensure_ascii=False,
            )

        return json.dumps({'ok': False, 'error': f'Herramienta desconocida: {nombre_tool}'})

    @classmethod
    def procesar_mensaje(
        cls,
        usuario_id: int,
        paciente_id: int,
        texto_usuario: str,
        es_cuidador: bool = False,
    ) -> Dict[str, Any]:
        """Procesa un mensaje del usuario, consulta DeepSeek con contexto y persiste la conversación."""
        texto_limpio = (texto_usuario or '').strip()
        if not texto_limpio:
            raise ValueError('El mensaje no puede estar vacío.')

        # 1. Guardar mensaje del usuario
        msg_user = MensajeIA(
            usuario_id=usuario_id,
            paciente_id=paciente_id,
            rol='user',
            contenido=texto_limpio,
        )
        db.session.add(msg_user)
        db.session.flush()

        # 2. Construir historial para DeepSeek
        system_prompt, expediente = cls._build_system_prompt(paciente_id, es_cuidador)
        recientes = (
            MensajeIA.query.filter_by(paciente_id=paciente_id)
            .order_by(MensajeIA.id.desc())
            .limit(cls.HISTORY_LIMIT)
            .all()
        )
        recientes.reverse()

        messages: List[Dict[str, Any]] = [{'role': 'system', 'content': system_prompt}]
        for m in recientes:
            messages.append({'role': m.rol if m.rol in ('user', 'assistant') else 'assistant', 'content': m.contenido})

        tools = cls._build_tools()
        estado_turno: Dict[str, Any] = {
            'alerta_preventiva': None,
            'es_emergencia': False,
            'accion_pendiente': None,
            'entidades_actualizadas': set(),
        }

        respuesta_final = ''
        for _ in range(cls.MAX_TOOL_ROUNDS + 1):
            resp = cls._call_deepseek(messages, tools=tools)
            choice = (resp.get('choices') or [{}])[0]
            msg_ai = choice.get('message') or {}
            tool_calls = msg_ai.get('tool_calls') or []

            if not tool_calls:
                respuesta_final = (msg_ai.get('content') or '').strip()
                break

            messages.append(msg_ai)
            for tc in tool_calls:
                fn = tc.get('function') or {}
                fn_name = fn.get('name', '')
                try:
                    fn_args = json.loads(fn.get('arguments') or '{}')
                except json.JSONDecodeError:
                    fn_args = {}

                resultado_tool = cls._ejecutar_tool(fn_name, fn_args, paciente_id, expediente, estado_turno)
                messages.append({
                    'role': 'tool',
                    'tool_call_id': tc.get('id', ''),
                    'content': resultado_tool,
                })

        if not respuesta_final:
            respuesta_final = (
                'Estoy aquí para acompañarte con tu salud y tu rutina en la app. '
                '¿En qué te puedo ayudar hoy?'
            )

        entidades_lista = sorted(estado_turno['entidades_actualizadas'])

        msg_assistant = MensajeIA(
            usuario_id=usuario_id,
            paciente_id=paciente_id,
            rol='assistant',
            contenido=respuesta_final,
            alerta_preventiva=estado_turno['alerta_preventiva'],
            es_emergencia=estado_turno['es_emergencia'],
            entidades_actualizadas_json=json.dumps(entidades_lista) if entidades_lista else None,
        )
        if estado_turno['accion_pendiente']:
            msg_assistant.set_accion_pendiente(estado_turno['accion_pendiente'])

        db.session.add(msg_assistant)
        db.session.commit()

        return {
            'usuario_mensaje': msg_user.to_dict(),
            'respuesta_asistente': msg_assistant.to_dict(),
            'entidades_actualizadas': entidades_lista,
        }

    @classmethod
    def confirmar_accion(
        cls,
        mensaje_id: int,
        paciente_id: int,
        aceptar: bool,
    ) -> Dict[str, Any]:
        """Ejecuta o cancela una acción clínica pendiente aprobada por el usuario."""
        msg = MensajeIA.query.filter_by(id=mensaje_id, paciente_id=paciente_id).first()
        if not msg:
            raise ValueError('Mensaje no encontrado para este paciente.')

        accion = msg.get_accion_pendiente()
        if not accion or accion.get('estado') != 'pendiente':
            raise ValueError('No hay ninguna acción pendiente por confirmar en este mensaje.')

        if not aceptar:
            accion['estado'] = 'cancelada'
            msg.set_accion_pendiente(accion)
            db.session.commit()
            return {
                'msg': 'Acción cancelada.',
                'mensaje': msg.to_dict(),
                'entidades_actualizadas': [],
            }

        tipo = accion.get('tipo')
        datos = dict(accion.get('datos') or {})
        entidades: List[str] = []

        if tipo == 'crear_medicamento':
            datos.setdefault('frecuencia', 24)
            datos.setdefault('hora_alarma', '08:00')
            datos.setdefault('cantidad_restante', 30)
            MedicamentoService.create(datos, paciente_id)
            entidades.append('medicamentos')
        elif tipo == 'actualizar_medicamento':
            med_id = int(datos.pop('id', 0))
            if not MedicamentoService.update(med_id, datos, paciente_id):
                raise ValueError('No se encontró el medicamento a actualizar.')
            entidades.append('medicamentos')
        elif tipo == 'crear_tratamiento':
            TratamientoService.create(datos, paciente_id)
            entidades.append('tratamientos')
        elif tipo == 'actualizar_tratamiento':
            trat_id = int(datos.pop('id', 0))
            if not TratamientoService.update(trat_id, datos, paciente_id):
                raise ValueError('No se encontró el tratamiento a actualizar.')
            entidades.append('tratamientos')
        elif tipo == 'actualizar_alergias_perfil':
            PerfilService.guardar_o_actualizar(datos, paciente_id)
            entidades.append('perfil')
        elif tipo == 'crear_habito':
            datos.setdefault('objetivo', 1)
            datos.setdefault('unidad', 'veces')
            datos.setdefault('icono', '🌿')
            MetaService.create(datos, paciente_id)
            entidades.append('metas')
        else:
            raise ValueError(f'Tipo de acción no soportado: {tipo}')

        accion['estado'] = 'confirmada'
        msg.set_accion_pendiente(accion)
        msg.entidades_actualizadas_json = json.dumps(entidades)
        db.session.commit()

        return {
            'msg': 'Cambio guardado correctamente en tu expediente.',
            'mensaje': msg.to_dict(),
            'entidades_actualizadas': entidades,
        }

    @staticmethod
    def obtener_historial(paciente_id: int, limite: int = 50) -> List[Dict[str, Any]]:
        """Retorna el historial reciente de conversación del paciente."""
        mensajes = (
            MensajeIA.query.filter_by(paciente_id=paciente_id)
            .order_by(MensajeIA.id.asc())
            .limit(limite)
            .all()
        )
        return [m.to_dict() for m in mensajes]

    @staticmethod
    def limpiar_historial(paciente_id: int) -> int:
        """Elimina el historial conversacional del paciente para iniciar una charla nueva."""
        eliminados = MensajeIA.query.filter_by(paciente_id=paciente_id).delete()
        db.session.commit()
        return eliminados
