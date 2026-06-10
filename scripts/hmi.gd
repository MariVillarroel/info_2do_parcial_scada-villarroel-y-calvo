extends Control

# Controlador del HMI: conecta la planta con los widgets del sinóptico y el
# panel de operación. El núcleo (planta, escenarios, widgets de tanque/bomba/
# válvula) ya está resuelto; los huecos del parcial están marcados con
# "TODO (PARCIAL · ...)".
#
# COMO EJEMPLO, ya están conectados y funcionando: el nivel de TK-101 en el
# sinóptico, y el arranque/parada de B-101 con clic. Replica el patrón para
# todo lo demás.

@onready var planta: PlantaSim = $planta
@onready var escenarios: ReproductorEscenarios = $escenarios

@onready var tanque_tk101: TanqueWidget = $sinoptico/tanque_tk101
@onready var tanque_tk201: TanqueWidget = $sinoptico/tanque_tk201
@onready var bomba_b101: BombaWidget = $sinoptico/bomba_b101
@onready var valvula_v102: ValvulaWidget = $sinoptico/valvula_v102
@onready var valvula_v201: ValvulaWidget = $sinoptico/valvula_v201
@onready var f101_label: Label = $sinoptico/f101_label
@onready var f102_label: Label = $sinoptico/f102_label
@onready var f201_label: Label = $sinoptico/f201_label

@onready var banner_alarma: Label = $panel/margen/columna/banner_alarma
@onready var historial: ItemList = $panel/margen/columna/historial
@onready var boton_reconocer: Button = $panel/margen/columna/fila_alarmas/boton_reconocer
@onready var boton_modo: Button = $panel/margen/columna/fila_alarmas/boton_modo
@onready var selector_escenario: OptionButton = $panel/margen/columna/fila_escenario/selector_escenario
@onready var tendencia: TendenciaWidget = $panel/margen/columna/tendencia

# === ALARMAS (M1) Y CONTROL (M2) ===
# Los esqueletos están en scripts/gestor_alarmas.gd y scripts/control_auto.gd.
# TODO (PARCIAL · M1/M2): instáncialos aquí (o como nodos hijos) y conéctalos
# al tick de la planta.


func _ready() -> void:
	escenarios.planta = planta
	planta.tick.connect(_on_tick_planta)
	planta.evento.connect(_on_evento_planta)
	escenarios.evento_escenario.connect(_on_evento_escenario)
	_poblar_selector_escenarios()


# Lista los .json de res://data/escenarios/ en el selector. Este patrón
# (recorrer una carpeta de datos en vez de codificar la lista) es el mismo
# que te pide M4 para los parámetros de la planta.
func _poblar_selector_escenarios() -> void:
	var dir = DirAccess.open("res://data/escenarios")
	if dir == null:
		return
	for archivo in dir.get_files():
		if archivo.ends_with(".json"):
			selector_escenario.add_item(archivo)


func _on_tick_planta(datos: Dictionary) -> void:
	# EJEMPLO (resuelto): el sinóptico refleja el nivel de TK-101.
	tanque_tk101.set_pct(datos["TK101.pct"])
	# TODO (PARCIAL · B1): refleja TODO el resto del estado en cada tick:
	# TK-201, marcha de la bomba, apertura de ambas válvulas y los tres
	# caudales (f101_label, f102_label, f201_label, en m³/s con 3 decimales).
	# TODO (PARCIAL · M1): pasa `datos` a tu gestor de alarmas y refleja el
	# resultado: banner con la alarma más grave sin reconocer, parpadeo,
	# bocina (alarma.wav en bucle mientras haya activas sin reconocer) y cada
	# transición agregada al historial (ItemList).
	# TODO (PARCIAL · M2): en modo AUTO, pasa `datos` a tu control; los
	# interlocks se aplican SIEMPRE.
	# TODO (PARCIAL · M3): alimenta la tendencia (tendencia.agregar_muestra).


func _on_evento_planta(tipo: String, mensaje: String) -> void:
	print("EVENTO [", tipo, "]: ", mensaje)
	# TODO (PARCIAL · B3): "rebalse" y "vacio" son eventos críticos: pasa a un
	# estado de PARADA DE EMERGENCIA explícito (bomba fuera, pantalla de trip
	# con el motivo, sonido trip.wav) y ofrece reiniciar (planta.reiniciar()).
	# TODO (PARCIAL · M4): registra todo evento en tu log persistente.


func _on_evento_escenario(mensaje: String) -> void:
	print("ESCENARIO: ", mensaje)
	# TODO (PARCIAL · M4): al historial y al log persistente también.


# --- clics en el sinóptico ---

func _on_bomba_b101_presionada() -> void:
	# EJEMPLO (resuelto): control manual de la bomba.
	planta.comandar("B101.marcha", not planta.leer("B101.marcha"))
	# TODO (PARCIAL · B4): clic con sonido (click.wav).


func _on_valvula_v102_presionada() -> void:
	# TODO (PARCIAL · B2): control manual de V-102. Decide la interacción:
	# ciclar 0 % → 50 % → 100 % → 0 % con cada clic, o un pequeño popup con
	# slider. Recuerda que una válvula atascada NO obedece (verás el comando
	# ignorado en la lectura: eso es correcto y tus alarmas deben delatarlo).
	pass


func _on_valvula_v201_presionada() -> void:
	# TODO (PARCIAL · B2): igual que V-102.
	pass


# --- panel de operación ---

func _on_boton_reconocer_pressed() -> void:
	# TODO (PARCIAL · M1): reconoce las alarmas activas (silencia la bocina;
	# las alarmas siguen visibles hasta normalizarse).
	pass


func _on_boton_modo_pressed() -> void:
	# TODO (PARCIAL · M2): alterna MANUAL/AUTO y refléjalo en el texto del
	# botón y en algún lugar visible del sinóptico.
	pass


func _on_boton_escenario_pressed() -> void:
	# Resuelto: inyecta el escenario seleccionado. Tus alarmas y tu control
	# deben reaccionar solos a lo que venga.
	if selector_escenario.selected < 0:
		return
	var archivo = selector_escenario.get_item_text(selector_escenario.selected)
	escenarios.cargar_y_ejecutar("res://data/escenarios/" + archivo)
