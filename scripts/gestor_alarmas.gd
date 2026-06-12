class_name GestorAlarmas
extends Node

# === SISTEMA DE ALARMAS (M1) — POR IMPLEMENTAR ===
#
# El corazón de un SCADA. Para cada variable vigilada hay hasta cuatro
# límites: LL (bajo-bajo), L (bajo), H (alto), HH (alto-alto). Cada alarma es
# una pequeña máquina de estados:
#
#   NORMAL ──(se viola el límite)──> ACTIVA ──(operador reconoce)──> RECONOCIDA
#     ^                                |                                  |
#     └────────(vuelve a rango)────────┴──────────(vuelve a rango)────────┘
#
#   - ACTIVA: parpadea en el banner y suena la bocina (assets/sounds/alarma.wav).
#   - RECONOCIDA: deja de sonar, pero sigue visible hasta normalizarse.
#   - Cada transición se registra en el historial con hora de simulación.
#
# Sugerencia de contrato con hmi.gd:
#   signal alarma_activada(id: String, mensaje: String)
#   signal alarma_reconocida(id: String)
#   signal alarma_normalizada(id: String)
#   func evaluar(datos: Dictionary) -> void      # llamar en cada tick
#   func reconocer_todas() -> void               # botón "Reconocer"
#   func hay_activas_sin_reconocer() -> bool     # ¿debe sonar la bocina?
#   func historial() -> Array                    # para el ItemList y para M4

# TODO (PARCIAL · M1): define los límites por tag. Empieza en código y, para
# M4, llévalos al mismo archivo de datos que los parámetros de la planta:
# var limites := {
# 	"TK101.pct": {"LL": 5.0, "L": 15.0, "H": 85.0, "HH": 95.0},
# 	"TK201.pct": {"LL": 5.0, "L": 15.0, "H": 85.0, "HH": 95.0},
# }

# TODO (PARCIAL · M1): implementa la evaluación, los estados y el historial.
#señales 
signal alarma_activada(id: String, mensaje: String)
signal alarma_reconocida(id: String)
signal alarma_normalizada(id: String)

#const 
enum Estado { NORMAL, ACTIVA, RECONOCIDA }

#prioridades de alarmas 
const PRIORIDAD := { "HH": 4, "LL": 3, "H": 2, "L": 1 }

#limites
var limites := {
	"TK101.pct": { "LL": 5.0, "L": 15.0, "H": 85.0, "HH": 95.0 },
	"TK201.pct": { "LL": 5.0, "L": 15.0, "H": 85.0, "HH": 95.0 },
}

var _alarmas := {}
var _historial: Array = [] 

func evaluar(datos: Dictionary) -> void:
	for tag in limites:
		if not datos.has(tag):
			continue
		var valor: float = datos[tag]
		var lims: Dictionary = limites[tag]

		for nivel in ["HH", "LL", "H", "L"]:
			var id: String = tag + "." + nivel
			var violado := _esta_violado(valor, nivel, lims[nivel])
			_actualizar_alarma(id, tag, nivel, valor, violado, datos.get("t", 0.0))


func reconocer_todas() -> void:
	for id in _alarmas:
		if _alarmas[id]["estado"] == Estado.ACTIVA:
			_alarmas[id]["estado"] = Estado.RECONOCIDA
			var t: float = _alarmas[id].get("t_ultima", 0.0)
			_agregar_historial(id, "RECONOCIDA", t)
			alarma_reconocida.emit(id)


func hay_activas_sin_reconocer() -> bool:
	for id in _alarmas:
		if _alarmas[id]["estado"] == Estado.ACTIVA:
			return true
	return false


func alarma_mas_grave() -> String:
	var mejor_id := ""
	var mejor_prio := 0
	for id in _alarmas:
		var a: Dictionary = _alarmas[id]
		if a["estado"] == Estado.NORMAL:
			continue
		var prio: int = PRIORIDAD.get(a["nivel"], 0)
		if prio > mejor_prio:
			mejor_prio = prio
			mejor_id = id
	if mejor_id == "":
		return ""
	var a: Dictionary = _alarmas[mejor_id]
	return "[%s] %s = %.1f%%" % [a["nivel"], a["tag"], a["valor"]]


func obtener_historial() -> Array:
	return _historial.duplicate()


func reiniciar() -> void:
	_alarmas.clear()
	_historial.clear()
	

func _esta_violado(valor: float, nivel: String, limite: float) -> bool:
	match nivel:
		"HH", "H": return valor >= limite
		"LL", "L": return valor <= limite
	return false


func _actualizar_alarma(id: String, tag: String, nivel: String,
						valor: float, violado: bool, t: float) -> void:
	if not _alarmas.has(id):
		_alarmas[id] = { "estado": Estado.NORMAL, "nivel": nivel,
						 "tag": tag, "valor": valor, "t_ultima": t }

	var a: Dictionary = _alarmas[id]
	a["valor"] = valor
	a["t_ultima"] = t

	match a["estado"]:
		Estado.NORMAL:
			if violado:
				a["estado"] = Estado.ACTIVA
				_agregar_historial(id, "ACTIVA", t)
				alarma_activada.emit(id, "[%s] %s = %.1f%%" % [nivel, tag, valor])

		Estado.ACTIVA, Estado.RECONOCIDA:
			if not violado:
				a["estado"] = Estado.NORMAL
				_agregar_historial(id, "NORMAL", t)
				alarma_normalizada.emit(id)


func _agregar_historial(id: String, estado: String, t: float) -> void:
	var linea := "T=%6.1fs  %-30s → %s" % [t, id, estado]
	_historial.append(linea)
