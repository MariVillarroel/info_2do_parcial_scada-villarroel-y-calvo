class_name ValvulaWidget
extends Control

# Widget de válvula (resuelto): "moño" clásico de P&ID. Verde abierta, gris
# cerrada, amarillo a media apertura. Emite "presionada" al hacer clic.

signal presionada

@export var etiqueta := "V-102"

var apertura := 0.0   # 0..1


func set_apertura(valor: float) -> void:
	apertura = clampf(valor, 0.0, 1.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		presionada.emit()


func _color() -> Color:
	if apertura < 0.05:
		return Color(0.45, 0.48, 0.52)       # cerrada
	if apertura > 0.95:
		return Color(0.30, 0.80, 0.40)       # abierta
	return Color(0.92, 0.78, 0.25)           # parcial


func _draw() -> void:
	var fuente = get_theme_default_font()
	var c = size / 2.0
	var w = size.x / 2.0 - 2.0
	var h = size.y / 2.0 - 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - w, c.y - h), Vector2(c.x, c.y), Vector2(c.x - w, c.y + h),
	]), _color())
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x + w, c.y - h), Vector2(c.x, c.y), Vector2(c.x + w, c.y + h),
	]), _color())
	draw_string(fuente, Vector2(0, size.y + 14),
			"%s  %.0f%%" % [etiqueta, apertura * 100],
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Color(0.85, 0.88, 0.92))
