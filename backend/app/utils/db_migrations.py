"""Módulo de migraciones automáticas para base de datos (PostgreSQL y SQLite)."""
from sqlalchemy import text, inspect
from app.extensions import db
import logging

logger = logging.getLogger(__name__)

def run_db_migrations() -> None:
    """
    Ejecuta migraciones idempotentes (ALTER TABLE ... ADD COLUMN IF NOT EXISTS)
    para soportar las nuevas columnas clínicas y de juegos en PostgreSQL y SQLite sin romper datos.
    """
    engine = db.engine
    dialect_name = engine.dialect.name.lower()

    # Columnas nuevas para tabla 'tratamientos'
    tratamiento_cols = [
        ("especialidad_medica", "VARCHAR(100) DEFAULT 'Medicina General'"),
        ("objetivo_terapeutico", "VARCHAR(200)"),
        ("notas_evolucion", "TEXT"),
        ("recomendaciones", "TEXT"),
        ("fecha_ultima_revision", "DATE"),
        ("proxima_cita", "DATE")
    ]

    # Columnas nuevas para tabla 'perfil_usuario'
    perfil_cols = [
        ("tipo_documento", "VARCHAR(20) DEFAULT 'CC'"),
        ("numero_documento", "VARCHAR(30)"),
        ("regimen_eps", "VARCHAR(50) DEFAULT 'Contributivo'"),
        ("presion_habitual", "VARCHAR(30)"),
        ("nivel_movilidad", "VARCHAR(50) DEFAULT 'Independiente'"),
        ("restricciones_alimentarias", "TEXT DEFAULT 'Ninguna'"),
        ("antecedentes_familiares", "TEXT DEFAULT 'Ninguno'")
    ]

    # Columnas nuevas para tabla 'actividades_cognitivas' (Módulo 4)
    actividades_cols = [
        ("nivel_dificultad", "VARCHAR(20) DEFAULT 'intermedio'")
    ]

    try:
        # Asegurar creación de tablas si es base nueva o tabla nueva
        from app.models.historial_toma import HistorialToma
        db.create_all()

        with engine.connect() as conn:
            if 'postgres' in dialect_name:
                for col_name, col_type in tratamiento_cols:
                    sql = f"ALTER TABLE tratamientos ADD COLUMN IF NOT EXISTS {col_name} {col_type};"
                    conn.execute(text(sql))

                for col_name, col_type in perfil_cols:
                    sql = f"ALTER TABLE perfil_usuario ADD COLUMN IF NOT EXISTS {col_name} {col_type};"
                    conn.execute(text(sql))

                for col_name, col_type in actividades_cols:
                    sql = f"ALTER TABLE actividades_cognitivas ADD COLUMN IF NOT EXISTS {col_name} {col_type};"
                    conn.execute(text(sql))

                conn.commit()
                logger.info("✅ [MIGRACIONES] Columnas de Módulo 3 y 4 verificadas en PostgreSQL.")

            elif 'sqlite' in dialect_name:
                # SQLite no soporta 'IF NOT EXISTS' en ADD COLUMN, inspeccionamos previamente
                inspector = inspect(engine)
                
                # 1. Tratamientos
                if inspector.has_table("tratamientos"):
                    existing_trat_cols = {col['name'] for col in inspector.get_columns("tratamientos")}
                    for col_name, col_type in tratamiento_cols:
                        if col_name not in existing_trat_cols:
                            conn.execute(text(f"ALTER TABLE tratamientos ADD COLUMN {col_name} {col_type};"))

                # 2. Perfil Usuario
                if inspector.has_table("perfil_usuario"):
                    existing_perf_cols = {col['name'] for col in inspector.get_columns("perfil_usuario")}
                    for col_name, col_type in perfil_cols:
                        if col_name not in existing_perf_cols:
                            conn.execute(text(f"ALTER TABLE perfil_usuario ADD COLUMN {col_name} {col_type};"))

                # 3. Actividades Cognitivas
                if inspector.has_table("actividades_cognitivas"):
                    existing_act_cols = {col['name'] for col in inspector.get_columns("actividades_cognitivas")}
                    for col_name, col_type in actividades_cols:
                        if col_name not in existing_act_cols:
                            conn.execute(text(f"ALTER TABLE actividades_cognitivas ADD COLUMN {col_name} {col_type};"))

                conn.commit()
                logger.info("✅ [MIGRACIONES] Columnas de Módulo 3 y 4 verificadas en SQLite.")

            # Normalización de datos en actividades_cognitivas (PostgreSQL y SQLite)
            conn.execute(text("UPDATE actividades_cognitivas SET tipo_juego = 'Sudoku' WHERE LOWER(tipo_juego) IN ('sudoku senior', 'sudoku_senior');"))
            conn.execute(text("UPDATE actividades_cognitivas SET tipo_juego = 'Trivia de Cultura General' WHERE LOWER(tipo_juego) IN ('trivia de salud', 'trivia_de_salud', 'trivia');"))
            conn.execute(text("UPDATE actividades_cognitivas SET tipo_juego = 'Secuencia de Luces' WHERE LOWER(tipo_juego) IN ('ordenar secuencia', 'ordenar_secuencia');"))
            conn.commit()
            logger.info("✅ [MIGRACIONES] Nombres canónicos de actividades cognitivas normalizados.")

        # Asegurar datos continuos de 2 meses para usuario de prueba prueba@envejecer.com
        try:
            from app.models.usuario import Usuario
            from app.models.historial_toma import HistorialToma
            u_demo = Usuario.query.filter_by(email='prueba@envejecer.com').first()
            if not u_demo or HistorialToma.query.filter_by(usuario_id=u_demo.id).count() < 100:
                import sys, os
                backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
                if backend_dir not in sys.path:
                    sys.path.insert(0, backend_dir)
                from seed_dos_meses_demo import poblar_dos_meses_demo
                poblar_dos_meses_demo()
                logger.info("✅ [SEED] 2 meses de datos de prueba para prueba@envejecer.com asegurados automáticamente.")
        except Exception as e_seed:
            logger.warning(f"⚠️ [SEED] Advertencia al verificar datos de prueba: {e_seed}")
        # Asegurar Ficha Médica y Tratamientos Clínicos Estructurados para prueba@envejecer.com
        try:
            import sys, os
            backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
            if backend_dir not in sys.path:
                sys.path.insert(0, backend_dir)
            from seed_expediente_clinico import poblar_expediente_clinico
            poblar_expediente_clinico()
            logger.info("✅ [SEED] Ficha Médica y Tratamientos Clínicos asegurados exitosamente.")
        except Exception as e_exp:
            logger.warning(f"⚠️ [SEED] Advertencia al verificar expediente clínico: {e_exp}")

    except Exception as e:
        logger.warning(f"⚠️ [MIGRACIONES] Advertencia durante migración de columnas: {e}")
