class_name PlantaSim
extends Node

# === NÚCLEO RESUELTO: NO NECESITAS MODIFICAR ESTE ARCHIVO ===
# (la única excepción es la mecánica M4, que te pide mover los parámetros a
# un archivo de datos)
#
# Simula una pequeña planta de agua de dos tanques:
#
#   POZO ──> B-101 (bomba) ──> TK-101 ──> V-102 ──> TK-201 ──> V-201 ──> RED
#
# La bomba entrega caudal constante; los tanques drenan por gravedad a través
# de las válvulas (caudal proporcional a apertura * sqrt(nivel)). La planta
# avanza sola en _physics_process y emite:
#
#   tick(datos)            cada paso de simulación, con todas las lecturas
#   evento(tipo, mensaje)  al rebalsar o vaciarse un tanque, y eventos de escenario
#
# Tu HMI habla con la planta SOLO mediante leer() y comandar(), como un SCADA
# real habla con un PLC por tags:
#
#   leer("TK101.pct")        nivel de TK-101 en %        (también "TK201.pct")
#   leer("TK101.nivel")      nivel en metros
#   leer("B101.marcha")      bomba en marcha (bool)
#   leer("V102.apertura")    apertura REAL de la válvula, 0..1 (también V201)
#   leer("F101.caudal")      caudal bomba→TK101 en m³/s
#   leer("F102.caudal")      caudal TK101→TK201
#   leer("F201.caudal")      caudal TK201→red
#
#   comandar("B101.marcha", true/false)
#   comandar("V102.apertura", 0.0..1.0)   (también V201)
#
# OJO: leer() devuelve lo que dicen los SENSORES y los comandos pueden NO
# obedecerse (válvula atascada, bomba fallada, sensor con deriva): el
# reproductor de escenarios inyecta exactamente ese tipo de fallas. Tu sistema
# de alarmas (M1) y tu control automático (M2) deben sobrevivir a eso.

signal tick(datos: Dictionary)
signal evento(tipo: String, mensaje: String)

# === PARÁMETROS DE LA PLANTA ===
# TODO (PARCIAL · M4): mueve estos parámetros (y tus límites de alarma) a un
# archivo de datos en res://data/ y cárgalos aquí; cambiar la planta no debe
# requerir tocar código.
var params := {}

# múltiplo de velocidad de la simulación (los controles de tu HMI pueden cambiarlo)
@export var velocidad := 1.0

var tiempo := 0.0

# estado físico
var _nivel := {"TK101": 1.5, "TK201": 1.0}
var _bomba_comando := true
var _apertura_comando := {"V102": 1.0, "V201": 1.0}

# fallas inyectadas por escenarios (banco de pruebas; tu lógica no las toca)
var _valvulas_atascadas := {}   # tag -> apertura física congelada
var _bomba_fallada := false
var _derivas := {}              # tag de lectura -> offset sumado al sensor
var _factor_demanda := 1.0

# para emitir eventos de rebalse/vacío solo en la transición
var _rebalsando := {"TK101": false, "TK201": false}
var _vacio := {"TK201": false}
func _ready() -> void:
	_cargar_parametros()

func _cargar_parametros() -> void:

	var archivo := FileAccess.open(
		"res://data/planta.json",
		FileAccess.READ
	)

	if archivo == null:
		push_error("No se pudo abrir planta.json")
		return

	var texto := archivo.get_as_text()

	print(texto)

	var json = JSON.parse_string(texto)

	print(json)

	if json == null:
		push_error("planta.json inválido")
		return

	params = json

	print("PARAMS CARGADOS:")
	print(params)
	
func _physics_process(delta: float) -> void:
	var dt = delta * velocidad
	tiempo += dt

	var q_bomba = params["B101"]["caudal_m3s"] if _bomba_marcha() else 0.0
	var q_102 = _apertura_real("V102") * params["V102"]["k"] * sqrt(maxf(_nivel["TK101"], 0.0))
	var q_201 = _apertura_real("V201") * params["V201"]["k"] * _factor_demanda \
			* sqrt(maxf(_nivel["TK201"], 0.0))

	_nivel["TK101"] += (q_bomba - q_102) / params["TK101"]["area_m2"] * dt
	_nivel["TK201"] += (q_102 - q_201) / params["TK201"]["area_m2"] * dt

	_vigilar_limites("TK101")
	_vigilar_limites("TK201")
	if _nivel["TK201"] <= 0.0 and _apertura_real("V201") > 0.0:
		if not _vacio["TK201"]:
			_vacio["TK201"] = true
			evento.emit("vacio", "TK-201 vacío: la red se quedó sin suministro")
	elif _nivel["TK201"] > 0.05:
		_vacio["TK201"] = false
	_nivel["TK101"] = clampf(_nivel["TK101"], 0.0, params["TK101"]["altura_m"])
	_nivel["TK201"] = clampf(_nivel["TK201"], 0.0, params["TK201"]["altura_m"])

	tick.emit(snapshot())


func _vigilar_limites(tanque: String) -> void:
	if _nivel[tanque] >= params[tanque]["altura_m"]:
		if not _rebalsando[tanque]:
			_rebalsando[tanque] = true
			evento.emit("rebalse", tanque.replace("TK", "TK-") + " REBALSANDO")
	elif _nivel[tanque] < params[tanque]["altura_m"] * 0.98:
		_rebalsando[tanque] = false


# --- API pública (lo que tu HMI usa) ---

func leer(tag: String):
	match tag:
		"TK101.nivel": return _sensor("TK101.nivel", _nivel["TK101"])
		"TK201.nivel": return _sensor("TK201.nivel", _nivel["TK201"])
		"TK101.pct": return _sensor("TK101.nivel", _nivel["TK101"]) / params["TK101"]["altura_m"] * 100.0
		"TK201.pct": return _sensor("TK201.nivel", _nivel["TK201"]) / params["TK201"]["altura_m"] * 100.0
		"B101.marcha": return _bomba_marcha()
		"V102.apertura": return _apertura_real("V102")
		"V201.apertura": return _apertura_real("V201")
		"F101.caudal": return params["B101"]["caudal_m3s"] if _bomba_marcha() else 0.0
		"F102.caudal": return _apertura_real("V102") * params["V102"]["k"] * sqrt(maxf(_nivel["TK101"], 0.0))
		"F201.caudal": return _apertura_real("V201") * params["V201"]["k"] * _factor_demanda * sqrt(maxf(_nivel["TK201"], 0.0))
	push_warning("leer(): tag desconocido " + tag)
	return null


func comandar(tag: String, valor) -> void:
	match tag:
		"B101.marcha": _bomba_comando = bool(valor)
		"V102.apertura": _apertura_comando["V102"] = clampf(valor, 0.0, 1.0)
		"V201.apertura": _apertura_comando["V201"] = clampf(valor, 0.0, 1.0)
		_: push_warning("comandar(): tag desconocido " + tag)


func snapshot() -> Dictionary:
	var datos := {"t": tiempo}
	for tag in ["TK101.pct", "TK201.pct", "TK101.nivel", "TK201.nivel",
			"B101.marcha", "V102.apertura", "V201.apertura",
			"F101.caudal", "F102.caudal", "F201.caudal"]:
		datos[tag] = leer(tag)
	return datos


# Vuelve la planta a su estado inicial (útil para B3: reinicio tras un trip).
func reiniciar() -> void:
	tiempo = 0.0
	_nivel = {"TK101": 1.5, "TK201": 1.0}
	_bomba_comando = true
	_apertura_comando = {"V102": 1.0, "V201": 1.0}
	_valvulas_atascadas.clear()
	_bomba_fallada = false
	_derivas.clear()
	_factor_demanda = 1.0
	_rebalsando = {"TK101": false, "TK201": false}
	_vacio = {"TK201": false}


# --- banco de pruebas (usado por el reproductor de escenarios) ---
# Tu lógica de alarmas/control NO debe llamar a esto: en la revisión se
# inyectan fallas que tu código no conoce de antemano.

func atascar_valvula(tag: String, apertura_fija: float) -> void:
	_valvulas_atascadas[tag] = clampf(apertura_fija, 0.0, 1.0)

func liberar_valvula(tag: String) -> void:
	_valvulas_atascadas.erase(tag)

func fallar_bomba() -> void:
	_bomba_fallada = true

func reparar_bomba() -> void:
	_bomba_fallada = false

func poner_deriva(tag: String, offset: float) -> void:
	_derivas[tag] = offset

func poner_demanda(factor: float) -> void:
	_factor_demanda = maxf(factor, 0.0)


# --- interno ---

func _bomba_marcha() -> bool:
	return _bomba_comando and not _bomba_fallada

func _apertura_real(tag: String) -> float:
	if tag in _valvulas_atascadas:
		return _valvulas_atascadas[tag]
	return _apertura_comando[tag]

func _sensor(tag: String, valor_real: float) -> float:
	return valor_real + _derivas.get(tag, 0.0)
