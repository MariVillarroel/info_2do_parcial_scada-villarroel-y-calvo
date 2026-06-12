class_name ControlAuto
extends Node

# === CONTROL AUTOMÁTICO (M2) — POR IMPLEMENTAR ===
#
# En modo AUTO, el operador suelta el mouse y tu lógica mantiene la planta en
# condición segura comandando la bomba y las válvulas a través de
# planta.comandar(). Dos piezas:
#
# 1) CONTROL POR HISTÉRESIS del nivel de TK-201 (el tanque que alimenta a la
#    red): mantenlo entre un mínimo y un máximo (p. ej. 40 % y 60 %) abriendo
#    y cerrando V-102. Histéresis = dos umbrales distintos para encender y
#    apagar; si usas uno solo, la válvula "castañea" (chattering) — eso resta.
#
# 2) INTERLOCKS (enclavamientos de seguridad), activos SIEMPRE, incluso en
#    modo MANUAL — en una planta real el operador no puede romper la física:
#    - si TK-101 está casi lleno (p. ej. >= 93 %, ANTES de que el nivel llegue
#      al límite HH de la alarma), la bomba NO puede marchar;
#    - si TK-201 está casi lleno, V-102 NO puede estar abierta;
#    - documenta en tu README cualquier otro que añadas.
#
# El botón "Modo" del HMI alterna MANUAL/AUTO. En MANUAL tus clics mandan
# (salvo interlocks); en AUTO manda esta lógica.
#
# Sugerencia de contrato con hmi.gd:
#   var modo_auto := false
#   func procesar(datos: Dictionary) -> void     # llamar en cada tick
#
# Pista: las fallas de los escenarios (válvula atascada, bomba parada) hacen
# que tus comandos no siempre se obedezcan. Tu control debe decidir con las
# LECTURAS, no con lo que cree haber comandado.

#abre V-102 si cae < SET_LOW, cierra si sube > SET_HIGH
const SET_LOW  := 40.0  
const SET_HIGH := 60.0  

#umbrales de bloqueo
const INTERLOCK_TK101_LLENO  := 93.0 #bloquea bomba
const INTERLOCK_TK201_LLENO  := 93.0 #bloquea V-102

#estados
var planta: PlantaSim = null
var modo_auto := false
var _v102_abierta := false

func procesar(datos: Dictionary) -> void:
	if planta == null:
		return
	_aplicar_interlocks(datos)
	if modo_auto:
		_control_histeresis(datos)
		
func _aplicar_interlocks(datos: Dictionary) -> void:
	#TK-101 casi lleno -> apagar bomba
	if datos["TK101.pct"] >= INTERLOCK_TK101_LLENO:
		if datos["B101.marcha"]:
			planta.comandar("B101.marcha", false)

	#TK-201 casi lleno -> cerrar V-102
	if datos["TK201.pct"] >= INTERLOCK_TK201_LLENO:
		if datos["V102.apertura"] > 0.0:
			planta.comandar("V102.apertura", 0.0)
			_v102_abierta = false


func _control_histeresis(datos: Dictionary) -> void:
	var pct_201: float = datos["TK201.pct"]

	if pct_201 <= SET_LOW and not _v102_abierta:
		#nivel bajo -> abrir V-102
		planta.comandar("V102.apertura", 1.0)
		_v102_abierta = true

	elif pct_201 >= SET_HIGH and _v102_abierta:
		#nivel alto →-> cerrar V-102
		planta.comandar("V102.apertura", 0.0)
		_v102_abierta = false
