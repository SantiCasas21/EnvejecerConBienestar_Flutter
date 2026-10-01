"""Modelo de Perfil de Usuario con Ficha Médica Integral y Habeas Data."""
from app.extensions import db
from datetime import datetime, timezone

class PerfilUsuario(db.Model):
    """Entidad de PerfilUsuario en la base de datos."""
    __tablename__ = 'perfil_usuario'

    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False, unique=True)
    
    # ── Datos Personales y Biométricos ──
    tipo_documento = db.Column(db.String(20), default='CC')
    numero_documento = db.Column(db.String(30), nullable=True)
    fecha_nacimiento = db.Column(db.String(20), nullable=True) # YYYY-MM-DD o DD/MM/YYYY
    edad = db.Column(db.Integer, nullable=True)
    genero = db.Column(db.String(20), default='No especificado')
    tipo_sangre = db.Column(db.String(10), default='O+')
    peso = db.Column(db.Float, nullable=True) # en kg
    altura = db.Column(db.Float, nullable=True) # en cm
    presion_habitual = db.Column(db.String(30), nullable=True)
    nivel_movilidad = db.Column(db.String(50), default='Independiente')
    
    # ── Cobertura y Cuidados Clínicos ──
    eps = db.Column(db.String(100), default='No especificada')
    regimen_eps = db.Column(db.String(50), default='Contributivo')
    alergias = db.Column(db.Text, default='Ninguna')
    condiciones = db.Column(db.Text, default='Ninguna')
    cirugias = db.Column(db.Text, default='Ninguna')
    dispositivos_medicos = db.Column(db.String(255), default='Ninguno')
    restricciones_alimentarias = db.Column(db.Text, default='Ninguna')
    antecedentes_familiares = db.Column(db.Text, default='Ninguno')
    
    # ── Contactos de Emergencia y Red Médica ──
    telefono = db.Column(db.String(25), nullable=True) # Teléfono propio
    contacto_emergencia_nombre = db.Column(db.String(120), nullable=True)
    contacto_emergencia_telefono = db.Column(db.String(25), nullable=True)
    contacto_emergencia_parentesco = db.Column(db.String(50), default='Familiar')
    medico_tratante = db.Column(db.String(120), nullable=True)
    telefono_medico = db.Column(db.String(25), nullable=True)
    clinica_preferida = db.Column(db.String(150), default='Hospital General')
    
    # ── Cumplimiento Legal: Ley 1581 de 2012 (Habeas Data) ──
    acepto_habeas_data = db.Column(db.Boolean, default=False, nullable=False)
    fecha_habeas_data = db.Column(db.DateTime, nullable=True)

    # ── Notas y Observaciones ──
    notas_adicionales = db.Column(db.Text, nullable=True)
    
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    @property
    def imc(self) -> float | None:
        """Calcula el Índice de Masa Corporal (IMC)."""
        if self.peso and self.altura and self.altura > 30 and self.peso > 10:
            altura_m = self.altura / 100.0
            return round(self.peso / (altura_m * altura_m), 1)
        return None

    @property
    def clasificacion_imc(self) -> str:
        """Clasificación médica del IMC para adultos mayores."""
        val = self.imc
        if val is None:
            return 'No calculado'
        if val < 18.5:
            return 'Bajo peso'
        if val < 25.0:
            return 'Peso saludable'
        if val < 30.0:
            return 'Sobrepeso'
        return 'Obesidad'

    def to_dict(self) -> dict:
        """Representación en diccionario enriquecida."""
        return {
            "id": self.id,
            "usuario_id": self.usuario_id,
            "tipo_documento": self.tipo_documento or 'CC',
            "numero_documento": self.numero_documento,
            "fecha_nacimiento": self.fecha_nacimiento,
            "edad": self.edad,
            "genero": self.genero or 'No especificado',
            "tipo_sangre": self.tipo_sangre or 'O+',
            "peso": self.peso,
            "altura": self.altura,
            "imc": self.imc,
            "clasificacion_imc": self.clasificacion_imc,
            "eps": self.eps or 'No especificada',
            "regimen_eps": self.regimen_eps or 'Contributivo',
            "presion_habitual": self.presion_habitual,
            "nivel_movilidad": self.nivel_movilidad or 'Independiente',
            "alergias": self.alergias or 'Ninguna',
            "condiciones": self.condiciones or 'Ninguna',
            "cirugias": self.cirugias or 'Ninguna',
            "dispositivos_medicos": self.dispositivos_medicos or 'Ninguno',
            "restricciones_alimentarias": self.restricciones_alimentarias or 'Ninguna',
            "antecedentes_familiares": self.antecedentes_familiares or 'Ninguno',
            "telefono": self.telefono,
            "contacto_emergencia_nombre": self.contacto_emergencia_nombre,
            "contacto_emergencia_telefono": self.contacto_emergencia_telefono,
            "contacto_emergencia_parentesco": self.contacto_emergencia_parentesco or 'Familiar',
            "medico_tratante": self.medico_tratante,
            "telefono_medico": self.telefono_medico,
            "clinica_preferida": self.clinica_preferida or 'Hospital General',
            "acepto_habeas_data": bool(self.acepto_habeas_data),
            "fecha_habeas_data": self.fecha_habeas_data.isoformat() if self.fecha_habeas_data else None,
            "notas_adicionales": self.notas_adicionales,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
