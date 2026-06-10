class_name ReproductorEscenarios
extends Node

# === NÚCLEO RESUELTO: NO MODIFICAR ===
#
# Reproduce un "escenario de perturbación": una lista de fallas programadas en
# el tiempo que se inyectan a la planta (válvula atascada, bomba fallada,
# deriva de sensor, pico de demanda). Así se prueba que tus alarmas (M1) y tu
# control automático (M2) reaccionan a problemas que no conoces de antemano —
# la revisión del parcial corre escenarios OCULTOS con este mismo formato.
#
# Formato (res://data/escenarios/*.json):
# {
#   "nombre": "Válvula atascada",
#   "descripcion": "V-102 se atasca cerrada a los 15 s",
#   "eventos": [
#     {"t": 15, "accion": "valvula_atascada", "tag": "V102", "valor": 0.0},
#     {"t": 90, "accion": "valvula_liberada", "tag": "V102"}
#   ]
# }
#
# Acciones: valvula_atascada (tag, valor), valvula_liberada (tag),
# fallo_bomba, bomba_ok, deriva_sensor (tag, valor), demanda (valor = factor),
# mensaje (texto).

signal evento_escenario(mensaje: String)

var planta: PlantaSim = null

var _eventos: Array = []
var _indice := 0
var _t := 0.0
var _nombre := ""
var activo := false


func cargar_y_ejecutar(ruta: String) -> bool:
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir el escenario: " + ruta)
		return false
	var json = JSON.parse_string(archivo.get_as_text())
	if json == null or not json.has("eventos"):
		push_error("Escenario inválido: " + ruta)
		return false
	_nombre = json.get("nombre", ruta.get_file())
	_eventos = json["eventos"]
	_eventos.sort_custom(func(a, b): return a["t"] < b["t"])
	_indice = 0
	_t = 0.0
	activo = true
	evento_escenario.emit("escenario iniciado: " + _nombre)
	return true


func detener() -> void:
	activo = false


func _physics_process(delta: float) -> void:
	if not activo or planta == null:
		return
	_t += delta * planta.velocidad
	while _indice < _eventos.size() and _eventos[_indice]["t"] <= _t:
		_aplicar(_eventos[_indice])
		_indice += 1
	if _indice >= _eventos.size():
		activo = false
		evento_escenario.emit("escenario terminado: " + _nombre)


func _aplicar(ev: Dictionary) -> void:
	var tag = ev.get("tag", "")
	var valor = ev.get("valor", 0.0)
	match ev["accion"]:
		"valvula_atascada":
			planta.atascar_valvula(tag, valor)
			evento_escenario.emit("FALLA: %s atascada en %.0f%%" % [tag, valor * 100])
		"valvula_liberada":
			planta.liberar_valvula(tag)
			evento_escenario.emit("%s liberada" % tag)
		"fallo_bomba":
			planta.fallar_bomba()
			evento_escenario.emit("FALLA: B101 detenida (falla eléctrica)")
		"bomba_ok":
			planta.reparar_bomba()
			evento_escenario.emit("B101 reparada")
		"deriva_sensor":
			planta.poner_deriva(tag, valor)
			evento_escenario.emit("FALLA: deriva de %+.2f m en sensor %s" % [valor, tag])
		"demanda":
			planta.poner_demanda(valor)
			evento_escenario.emit("demanda de la red: factor %.1f" % valor)
		"mensaje":
			evento_escenario.emit(str(ev.get("texto", "")))
		_:
			push_warning("acción de escenario desconocida: " + str(ev["accion"]))
