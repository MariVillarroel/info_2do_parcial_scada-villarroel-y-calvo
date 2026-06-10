class_name TendenciaWidget
extends Control

# === TENDENCIAS EN TIEMPO REAL (M3) — POR IMPLEMENTAR ===
#
# Un "strip chart" como el de cualquier SCADA: las últimas N muestras de 2 o
# más variables (p. ej. TK101.pct y TK201.pct), desplazándose hacia la
# izquierda, con eje vertical 0–100 % y líneas de referencia (límites de
# alarma o setpoint del control).
#
# Sugerencia de diseño:
#   - hmi.gd llama agregar_muestra() en cada tick (o cada K ticks, decide tú
#     la frecuencia de muestreo) y este widget guarda un buffer por serie.
#   - En _draw(): fondo, rejilla, una polilínea por serie (draw_polyline),
#     leyenda con el color de cada serie y las líneas de límite.
#   - Limita el buffer (p. ej. 300 muestras) descartando lo viejo.

# TODO (PARCIAL · M3): declara tus buffers, p. ej.:
# var series := {}        # nombre -> {"color": Color, "datos": Array[float]}
# var max_muestras := 300


func agregar_muestra(nombre: String, valor: float) -> void:
	# TODO (PARCIAL · M3): guarda la muestra y queue_redraw().
	pass


func poner_linea_referencia(nombre: String, valor: float, color: Color) -> void:
	# TODO (PARCIAL · M3): línea horizontal (límite de alarma, setpoint...).
	pass


func _draw() -> void:
	# placeholder para que se vea dónde va el gráfico; reemplázalo
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.12, 0.16))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.38, 0.45), false, 1.5)
	draw_string(get_theme_default_font(), Vector2(0, size.y / 2),
			"TENDENCIAS (M3) — por implementar",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(0.6, 0.62, 0.68))
