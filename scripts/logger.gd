class_name EventLogger
extends Node

const LOG_PATH := "user://eventos.log"

func _ready() -> void:
	print("LOG:", ProjectSettings.globalize_path(LOG_PATH))

func escribir(texto: String) -> void:

	var archivo := FileAccess.open(
		LOG_PATH,
		FileAccess.READ_WRITE
	)

	if archivo == null:

		archivo = FileAccess.open(
			LOG_PATH,
			FileAccess.WRITE
		)

	if archivo == null:
		push_error("No se pudo abrir el log")
		return

	archivo.seek_end()

	archivo.store_line(texto)
