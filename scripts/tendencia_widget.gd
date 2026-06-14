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

const MAX_MUESTRAS := 600

var series := {
	"TK101": {
		"color": Color.CYAN,
		"datos": []
	},
	"TK201": {
		"color": Color.GREEN_YELLOW,
		"datos": []
	}
}

var lineas_referencia := {}


func agregar_muestra(nombre: String, valor: float) -> void:

	if not series.has(nombre):
		return

	var datos = series[nombre]["datos"]

	datos.append(valor)

	if datos.size() > MAX_MUESTRAS:
		datos.pop_front()

	queue_redraw()


func poner_linea_referencia(nombre: String, valor: float, color: Color) -> void:

	lineas_referencia[nombre] = {
		"valor": valor,
		"color": color
	}

	queue_redraw()


func _draw() -> void:

	draw_rect(
		Rect2(Vector2.ZERO, size),
		Color(0.10, 0.12, 0.16),
		true
	)

	draw_rect(
		Rect2(Vector2.ZERO, size),
		Color(0.35, 0.38, 0.45),
		false,
		1.5
	)

	# líneas de referencia

	for ref in lineas_referencia.values():

		var valor = ref["valor"]
		var color = ref["color"]

		var y = size.y - (valor / 100.0) * size.y

		draw_line(
			Vector2(0, y),
			Vector2(size.x, y),
			color,
			1.0
		)

	# curvas

	for nombre in series.keys():

		var serie = series[nombre]
		var datos = serie["datos"]

		if datos.size() < 2:
			continue

		var puntos := PackedVector2Array()

		for i in range(datos.size()):

			var x = float(i) / float(max(datos.size() - 1, 1)) * size.x
			var y = size.y - (float(datos[i]) / 100.0) * size.y

			puntos.append(Vector2(x, y))

		draw_polyline(
			puntos,
			serie["color"],
			2.0
		)

	# leyenda

	var font = get_theme_default_font()

	draw_string(
		font,
		Vector2(10, 20),
		"TK101",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color.CYAN
	)

	draw_string(
		font,
		Vector2(80, 20),
		"TK201",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color.GREEN_YELLOW
	)
