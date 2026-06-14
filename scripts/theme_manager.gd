class_name ThemeManager
extends Node

var modo_oscuro := true

func aplicar(root: Control) -> void:

	if modo_oscuro:
		root.modulate = Color(1, 1, 1)
	else:
		root.modulate = Color(1.8, 1.8, 1.8)

func alternar(root: Control) -> void:

	modo_oscuro = !modo_oscuro
	aplicar(root)
