"""Manejadores de errores globales."""
from flask import Flask, jsonify

def register_error_handlers(app: Flask) -> None:
    """Registra los manejadores de errores en la aplicación."""
    
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({"msg": "Petición incorrecta"}), 400

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"msg": "Recurso no encontrado"}), 404

    @app.errorhandler(422)
    def unprocessable_entity(error):
        return jsonify({"msg": "Entidad no procesable, validación fallida"}), 422

    @app.errorhandler(500)
    def internal_server_error(error):
        return jsonify({"msg": "Error interno del servidor"}), 500
