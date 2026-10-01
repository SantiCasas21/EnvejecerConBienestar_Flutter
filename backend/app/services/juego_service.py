"""Servicio de Juegos (Actividad Cognitiva)."""
from app.models.actividad_cognitiva import ActividadCognitiva
from app.models.cuidador_paciente import CuidadorPaciente
from app.models.usuario import Usuario
from app.extensions import db
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy import func

class JuegoService:
    """Servicios para las actividades cognitivas y competencia familiar."""

    @staticmethod
    def normalizar_tipo_juego(tipo_juego: str) -> str:
        """Normaliza el nombre del minijuego al estándar canónico del sistema."""
        t = tipo_juego.strip().lower()
        if t in ('sudoku senior', 'sudoku_senior', 'sudoku'):
            return 'Sudoku'
        if t in ('buscar pares', 'buscar_pares'):
            return 'Buscar Pares'
        if t in ('sopa de letras', 'sopa_letras'):
            return 'Sopa de Letras'
        if t in ('trivia', 'trivia de salud', 'trivia_de_salud', 'trivia de cultura general', 'trivia_cultura_general'):
            return 'Trivia de Cultura General'
        if t in ('ordenar secuencia', 'ordenar_secuencia', 'secuencia de luces', 'secuencia_luces'):
            return 'Secuencia de Luces'
        return tipo_juego.strip()

    @staticmethod
    def guardar_puntaje(data: Dict[str, Any], usuario_id: int) -> ActividadCognitiva:
        """Guarda el puntaje de un juego de manera segura registrando su dificultad."""
        tipo_juego = JuegoService.normalizar_tipo_juego(str(data.get('tipo_juego', 'Juego')))
        puntaje = int(data.get('puntaje', 0))
        nivel_dificultad = str(data.get('nivel_dificultad', 'intermedio')).strip().lower()
        if nivel_dificultad not in ('basico', 'intermedio', 'avanzado'):
            nivel_dificultad = 'intermedio'

        actividad = ActividadCognitiva(
            usuario_id=usuario_id,
            tipo_juego=tipo_juego,
            puntaje=puntaje,
            nivel_dificultad=nivel_dificultad,
        )
        db.session.add(actividad)
        db.session.commit()
        return actividad

    @staticmethod
    def get_historial(usuario_id: int, dias: Optional[int] = None, familiar: bool = False, limite: int = 30) -> List[Dict[str, Any]]:
        """
        Obtiene el historial de puntajes del usuario o de su círculo familiar,
        con filtro temporal opcional por cantidad de días.
        """
        user_ids = [usuario_id]
        nombres_map: Dict[int, str] = {}
        
        usuario = Usuario.query.get(usuario_id)
        if usuario:
            nombres_map[usuario_id] = usuario.nombre

        if familiar and usuario:
            if usuario.rol == 'adulto_mayor':
                vinculos = CuidadorPaciente.query.filter_by(paciente_id=usuario_id).all()
                for v in vinculos:
                    if v.cuidador_id not in user_ids:
                        user_ids.append(v.cuidador_id)
                    co_pacientes = CuidadorPaciente.query.filter_by(cuidador_id=v.cuidador_id).all()
                    for cp in co_pacientes:
                        if cp.paciente_id not in user_ids:
                            user_ids.append(cp.paciente_id)
            else:
                vinculos = CuidadorPaciente.query.filter_by(cuidador_id=usuario_id).all()
                for v in vinculos:
                    if v.paciente_id not in user_ids:
                        user_ids.append(v.paciente_id)
                    co_cuidadores = CuidadorPaciente.query.filter_by(paciente_id=v.paciente_id).all()
                    for cc in co_cuidadores:
                        if cc.cuidador_id not in user_ids:
                            user_ids.append(cc.cuidador_id)

            familiares = Usuario.query.filter(Usuario.id.in_(user_ids)).all()
            for f in familiares:
                nombres_map[f.id] = f.nombre

        query = ActividadCognitiva.query.filter(ActividadCognitiva.usuario_id.in_(user_ids))

        if dias is not None and dias > 0:
            desde = datetime.utcnow() - timedelta(days=dias)
            query = query.filter(ActividadCognitiva.fecha_realizacion >= desde)

        partidas = (
            query
            .order_by(ActividadCognitiva.fecha_realizacion.desc())
            .limit(limite)
            .all()
        )

        resultado = []
        for p in partidas:
            d = p.to_dict()
            d['tipo_juego'] = JuegoService.normalizar_tipo_juego(p.tipo_juego)
            d['nombre_jugador'] = nombres_map.get(p.usuario_id, 'Familiar')
            d['es_usuario_actual'] = (p.usuario_id == usuario_id)
            resultado.append(d)

        return resultado

    @staticmethod
    def get_puntos_por_juego(usuario_id: int) -> List[Dict[str, Any]]:
        """
        Calcula puntos acumulados, partidas y récord máximo para cada uno
        de los 5 minijuegos del usuario, ordenados de mayor a menor total de puntos.
        Identifica el minijuego 'más jugado'.
        """
        partidas = ActividadCognitiva.query.filter_by(usuario_id=usuario_id).all()

        juegos_def = [
            {"id": "sudoku", "titulo": "Sudoku", "alias": ["sudoku", "sudoku senior"]},
            {"id": "buscar_pares", "titulo": "Buscar Pares", "alias": ["buscar pares", "buscar_pares"]},
            {"id": "sopa_letras", "titulo": "Sopa de Letras", "alias": ["sopa de letras", "sopa_letras"]},
            {"id": "trivia", "titulo": "Trivia de Cultura General", "alias": ["trivia", "trivia de cultura general", "trivia de salud"]},
            {"id": "secuencia_luces", "titulo": "Secuencia de Luces", "alias": ["secuencia de luces", "secuencia_luces", "ordenar secuencia", "ordenar_secuencia"]},
        ]

        resumen = []
        for j in juegos_def:
            alias_set = set(a.lower() for a in j["alias"])
            partidas_juego = [p for p in partidas if p.tipo_juego.lower() in alias_set]
            total_puntos = sum(p.puntaje for p in partidas_juego)
            total_partidas = len(partidas_juego)
            record = max((p.puntaje for p in partidas_juego), default=0)

            resumen.append({
                "juego_id": j["id"],
                "tipo_juego": j["titulo"],
                "total_puntos": total_puntos,
                "partidas_jugadas": total_partidas,
                "record_maximo": record,
                "es_mas_jugado": False,
            })

        resumen.sort(key=lambda x: (x["total_puntos"], x["partidas_jugadas"]), reverse=True)

        partidas_max = max((r["partidas_jugadas"] for r in resumen), default=0)
        if partidas_max > 0:
            for r in resumen:
                if r["partidas_jugadas"] == partidas_max:
                    r["es_mas_jugado"] = True
                    break

        medallas = {1: "🥇", 2: "🥈", 3: "🥉"}
        for idx, r in enumerate(resumen):
            pos = idx + 1
            r["posicion"] = pos
            r["medalla"] = medallas.get(pos, f"{pos}º")

        return resumen

    @staticmethod
    def get_mejores_puntajes(usuario_id: int, tipo_juego: Optional[str] = None, limite: int = 3) -> List[ActividadCognitiva]:
        """Obtiene el Top de mejores puntajes del usuario (Top 1, 2, 3) general o por minijuego."""
        query = ActividadCognitiva.query.filter_by(usuario_id=usuario_id)
        if tipo_juego and tipo_juego.lower() != 'todos':
            query = query.filter(func.lower(ActividadCognitiva.tipo_juego) == tipo_juego.lower().strip())
        return (
            query
            .order_by(ActividadCognitiva.puntaje.desc(), ActividadCognitiva.fecha_realizacion.desc())
            .limit(limite)
            .all()
        )

    @staticmethod
    def get_estadisticas(usuario_id: int) -> Dict[str, Any]:
        """Obtiene resumen de puntos totales, partidas completadas y mejor récord."""
        partidas = ActividadCognitiva.query.filter_by(usuario_id=usuario_id).all()
        if not partidas:
            return {
                "total_puntos": 0,
                "partidas_jugadas": 0,
                "record_maximo": 0,
                "juego_favorito": "Ninguno aún",
            }

        total_puntos = sum(p.puntaje for p in partidas)
        partidas_jugadas = len(partidas)
        record_maximo = max(p.puntaje for p in partidas)

        # Juego favorito / más jugado
        conteo_juegos: Dict[str, int] = {}
        for p in partidas:
            conteo_juegos[p.tipo_juego] = conteo_juegos.get(p.tipo_juego, 0) + 1
        juego_favorito = max(conteo_juegos, key=conteo_juegos.get) if conteo_juegos else "Ninguno"

        return {
            "total_puntos": total_puntos,
            "partidas_jugadas": partidas_jugadas,
            "record_maximo": record_maximo,
            "juego_favorito": juego_favorito,
        }

    @staticmethod
    def get_podio_familiar(usuario_id: int, tipo_juego: Optional[str] = None) -> Dict[str, Any]:
        """
        Obtiene la tabla de competencia sana familiar vinculada vía CuidadorPaciente.
        Retorna las posiciones, puntajes récords y medallas de los integrantes.
        """
        usuario = Usuario.query.get(usuario_id)
        if not usuario:
            return {
                "total_miembros": 0,
                "hay_vinculacion": false,
                "filtro_juego": tipo_juego or "Todos",
                "codigo_vinculacion_usuario": None,
                "podio": [],
            }

        parentescos: Dict[int, str] = {
            usuario_id: "Titular" if usuario.rol == "adulto_mayor" else "Cuidador"
        }

        # 1. Búsqueda de vínculos familiares en CuidadorPaciente
        if usuario.rol == 'adulto_mayor':
            # Paciente buscando a sus cuidadores
            vinculos = CuidadorPaciente.query.filter_by(paciente_id=usuario_id).all()
            for v in vinculos:
                parentescos[v.cuidador_id] = v.parentesco or "Familiar / Cuidador"
                # Co-pacientes supervisados por el mismo cuidador (hermanos, cónyuge)
                co_pacientes = CuidadorPaciente.query.filter_by(cuidador_id=v.cuidador_id).all()
                for cp in co_pacientes:
                    if cp.paciente_id not in parentescos:
                        parentescos[cp.paciente_id] = "Familiar"
        else:
            # Cuidador buscando a los pacientes a su cargo
            vinculos = CuidadorPaciente.query.filter_by(cuidador_id=usuario_id).all()
            for v in vinculos:
                parentescos[v.paciente_id] = f"Familiar ({v.parentesco})" if v.parentesco else "Familiar"
                # Co-cuidadores del mismo paciente
                co_cuidadores = CuidadorPaciente.query.filter_by(paciente_id=v.paciente_id).all()
                for cc in co_cuidadores:
                    if cc.cuidador_id not in parentescos:
                        parentescos[cc.cuidador_id] = "Co-Cuidador"

        fam_ids = list(parentescos.keys())
        hay_vinculacion = len(fam_ids) > 1

        # 2. Obtener desempeño cognitivo de cada miembro
        podio_raw: List[Dict[str, Any]] = []
        for uid in fam_ids:
            u = Usuario.query.get(uid)
            if not u:
                continue

            query = ActividadCognitiva.query.filter_by(usuario_id=uid)
            if tipo_juego and tipo_juego.lower() != 'todos':
                t_key = tipo_juego.lower().strip()
                alias_map = {
                    "sudoku": ["sudoku", "sudoku senior"],
                    "buscar pares": ["buscar pares", "buscar_pares"],
                    "sopa de letras": ["sopa de letras", "sopa_letras"],
                    "trivia de cultura general": ["trivia", "trivia de cultura general", "trivia de salud"],
                    "trivia": ["trivia", "trivia de cultura general", "trivia de salud"],
                    "secuencia de luces": ["secuencia de luces", "secuencia_luces", "ordenar secuencia", "ordenar_secuencia"],
                }
                aliases = alias_map.get(t_key, [t_key])
                query = query.filter(func.lower(ActividadCognitiva.tipo_juego).in_([a.lower() for a in aliases]))

            partidas = query.all()
            if partidas:
                best_partida = max(partidas, key=lambda p: p.puntaje)
                puntaje_maximo = best_partida.puntaje
                juego_record = JuegoService.normalizar_tipo_juego(best_partida.tipo_juego)
                total_puntos = sum(p.puntaje for p in partidas)
                partidas_jugadas = len(partidas)
            else:
                puntaje_maximo = 0
                juego_record = "Sin partidas"
                total_puntos = 0
                partidas_jugadas = 0

            podio_raw.append({
                "usuario_id": uid,
                "nombre": u.nombre,
                "rol": u.rol or "adulto_mayor",
                "parentesco": parentescos.get(uid, "Familiar"),
                "puntaje_maximo": puntaje_maximo,
                "total_puntos": total_puntos,
                "partidas_jugadas": partidas_jugadas,
                "juego_record": juego_record,
                "es_usuario_actual": (uid == usuario_id),
            })

        # 3. Ordenar por total_puntos desc, luego puntaje_maximo desc
        podio_raw.sort(key=lambda x: (x["total_puntos"], x["puntaje_maximo"]), reverse=True)

        # 4. Asignar posiciones y medallas
        medallas_map = {1: "🥇", 2: "🥈", 3: "🥉"}
        for idx, item in enumerate(podio_raw):
            pos = idx + 1
            item["posicion"] = pos
            item["medalla"] = medallas_map.get(pos, f"{pos}º")

        return {
            "total_miembros": len(podio_raw),
            "hay_vinculacion": hay_vinculacion,
            "filtro_juego": tipo_juego or "Todos",
            "codigo_vinculacion_usuario": usuario.codigo_vinculacion,
            "podio": podio_raw,
        }
