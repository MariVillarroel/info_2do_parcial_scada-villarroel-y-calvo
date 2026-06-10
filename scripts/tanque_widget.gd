class_name TanqueWidget
extends Control

# Widget de tanque (resuelto): dibuja el contorno, el líquido según el nivel y
# el porcentaje. Es el EJEMPLO de cómo se hace un widget de sinóptico con
# _draw(); úsalo como referencia para mejorar los demás o crear los tuyos.

@export var etiqueta := "TK-101"
@export var color_liquido := Color(0.25, 0.55, 0.95)
@export var color_borde := Color(0.85, 0.88, 0.92)

var pct := 0.0   # 0..100


func set_pct(valor: float) -> void:
	pct = clampf(valor, 0.0, 100.0)
	queue_redraw()


func _draw() -> void:
	var fuente = get_theme_default_font()
	var alto_liquido = size.y * pct / 100.0
	# líquido
	draw_rect(Rect2(Vector2(0, size.y - alto_liquido), Vector2(size.x, alto_liquido)),
			color_liquido)
	# contorno (abierto arriba, como un tanque atmosférico)
	draw_line(Vector2.ZERO, Vector2(0, size.y), color_borde, 3.0)
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), color_borde, 3.0)
	draw_line(Vector2(size.x, 0), Vector2(size.x, size.y), color_borde, 3.0)
	# etiqueta y porcentaje
	draw_string(fuente, Vector2(4, -8), etiqueta, HORIZONTAL_ALIGNMENT_LEFT,
			size.x, 14, color_borde)
	draw_string(fuente, Vector2(0, size.y / 2), "%.0f %%" % pct,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color.WHITE)
