class_name BombaWidget
extends Control

# Widget de bomba (resuelto): círculo con triángulo, verde en marcha / gris
# detenida. Emite "presionada" al hacer clic — conéctala a tu HMI para el
# control manual (B2).

signal presionada

@export var etiqueta := "B-101"
@export var color_marcha := Color(0.30, 0.80, 0.40)
@export var color_parada := Color(0.45, 0.48, 0.52)

var marcha := false


func set_marcha(valor: bool) -> void:
	marcha = valor
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		presionada.emit()


func _draw() -> void:
	var fuente = get_theme_default_font()
	var centro = size / 2.0
	var radio = minf(size.x, size.y) / 2.0 - 2.0
	draw_circle(centro, radio, color_marcha if marcha else color_parada)
	draw_arc(centro, radio, 0, TAU, 32, Color(0.9, 0.9, 0.95), 2.0)
	# triángulo (sentido del flujo: hacia la derecha)
	draw_colored_polygon(PackedVector2Array([
		centro + Vector2(-radio * 0.4, -radio * 0.5),
		centro + Vector2(radio * 0.6, 0),
		centro + Vector2(-radio * 0.4, radio * 0.5),
	]), Color(0.95, 0.95, 0.98))
	draw_string(fuente, Vector2(0, size.y + 16), etiqueta,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Color(0.85, 0.88, 0.92))
