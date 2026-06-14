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

# Sonidos 
var _sfx_click: AudioStreamPlayer
var _sfx_alarma: AudioStreamPlayer
var _sfx_reconocer: AudioStreamPlayer
var _sfx_trip: AudioStreamPlayer

#trip 
var _en_trip := false
var _panel_trip: PanelContainer # creado por código en _ready
var _lbl_motivo_trip: Label

#valvulas (circulo)
const PASOS_VALVULA := [0.0, 0.5, 1.0]

#alarmas 
var _gestor: GestorAlarmas
var _control: ControlAuto
var _parpadeo_acum := 0.0
var _parpadeo_visible := true
const PARPADEO_INTERVALO := 0.5
var _acum_tendencia := 0.0
const INTERVALO_TENDENCIA := 1.0

#INICIALIZACION 
func _ready() -> void:
	escenarios.planta = planta
	planta.tick.connect(_on_tick_planta)
	planta.evento.connect(_on_evento_planta)
	escenarios.evento_escenario.connect(_on_evento_escenario)
	_poblar_selector_escenarios()
	_init_sonidos()
	_init_panel_trip()
	_init_gestor_alarmas()
	_init_control_auto()
	tendencia.poner_linea_referencia(
	"LL",
	5,
	Color.RED
	)

	tendencia.poner_linea_referencia(
		"L",
		15,
		Color.ORANGE
	)

	tendencia.poner_linea_referencia(
		"H",
		85,
		Color.ORANGE
	)

	tendencia.poner_linea_referencia(
		"HH",
		95,
		Color.RED
	)

func _init_sonidos() -> void:
	_sfx_click     = _crear_player("res://assets/sounds/click.wav")
	_sfx_reconocer = _crear_player("res://assets/sounds/reconocer.wav")
	_sfx_trip      = _crear_player("res://assets/sounds/trip.wav")
	_sfx_alarma = _crear_player("res://assets/sounds/alarma.wav")
	_sfx_alarma.finished.connect(_on_alarma_finished)

func _crear_player(ruta: String) -> AudioStreamPlayer:
	var stream = load(ruta) as AudioStream
	if stream == null:
		push_warning("Sonido no encontrado: " + ruta)
		return null
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p
	
func _on_alarma_finished() -> void:
	# Reinicia el wav manualmente al terminar, si todavía debe sonar
	if _gestor != null and _gestor.hay_activas_sin_reconocer() and not _en_trip:
		_sfx_alarma.play()
		
func _init_panel_trip() -> void:
	#el panel transparente 
	_panel_trip = PanelContainer.new()
	_panel_trip.name = "panel_trip"
	_panel_trip.set_anchors_preset(Control.PRESET_FULL_RECT)
	#fondo rojo oscuro 
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.45, 0.02, 0.02, 0.92)
	_panel_trip.add_theme_stylebox_override("panel", estilo)
	_panel_trip.visible = false
	add_child(_panel_trip)

	var centrado := CenterContainer.new()
	centrado.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_trip.add_child(centrado)

	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 24)
	centrado.add_child(columna)

	var lbl_titulo := Label.new()
	lbl_titulo.name = "lbl_titulo"
	lbl_titulo.text = "PARADA DE EMERGENCIA"
	lbl_titulo.add_theme_font_size_override("font_size", 32)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25)) #rojo vivo porque emergenciaa
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(lbl_titulo)

	var lbl_motivo := Label.new()
	lbl_motivo.name = "lbl_motivo"
	lbl_motivo.text = ""
	lbl_motivo.add_theme_font_size_override("font_size", 20)
	lbl_motivo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
	lbl_motivo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_motivo_trip = lbl_motivo
	columna.add_child(lbl_motivo)

	var btn := Button.new()
	btn.name = "btn_reiniciar"
	btn.text = "Reiniciar planta"
	btn.custom_minimum_size = Vector2(200, 48)
	btn.pressed.connect(_on_reiniciar_pressed)
	columna.add_child(btn)
	
func _init_gestor_alarmas() -> void:
	_gestor = GestorAlarmas.new()
	add_child(_gestor)
	_gestor.alarma_activada.connect(_on_alarma_activada)
	_gestor.alarma_reconocida.connect(_on_alarma_reconocida)
	_gestor.alarma_normalizada.connect(_on_alarma_normalizada)
	banner_alarma.text = "— sin alarmas —"
	banner_alarma.add_theme_color_override("font_color", Color(0.55, 0.65, 0.55))

func _init_control_auto() -> void:
	_control = ControlAuto.new()
	_control.planta = planta
	add_child(_control)
	boton_modo.text = "Modo: MANUAL"

#helpers sonido
func _play(player: AudioStreamPlayer) -> void:
	if player != null and not player.playing:
		player.play()
		
func _stop(player: AudioStreamPlayer) -> void:
	if player != null:
		player.stop()

#trip funciones 
func _disparar_trip(motivo: String) -> void:
	if _en_trip:
		return
	_en_trip = true
	planta.set_physics_process(false)   # congela la simulación
	escenarios.detener()
	planta.comandar("B101.marcha", false)
	_stop(_sfx_alarma)
	_play(_sfx_trip)
	# Mostrar pantalla
	_lbl_motivo_trip.text = motivo
	_panel_trip.visible = true


func _on_reiniciar_pressed() -> void:
	_en_trip = false
	_panel_trip.visible = false
	_stop(_sfx_trip)
	planta.reiniciar()
	planta.set_physics_process(true)
	# Limpiar historial visual
	historial.clear()
	banner_alarma.text = "— sin alarmas (M1) —"
	banner_alarma.add_theme_color_override("font_color", Color(0.55, 0.60, 0.65))
	_control.modo_auto = false
	_control._v102_abierta = false
	boton_modo.text = "Modo: MANUAL"
	boton_modo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

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

#parpadeo del banner: 
func _process(delta: float) -> void:
	if _gestor == null or not _gestor.hay_activas_sin_reconocer():
		banner_alarma.modulate.a = 1.0
		return
	_parpadeo_acum += delta
	if _parpadeo_acum >= PARPADEO_INTERVALO:
		_parpadeo_acum = 0.0
		_parpadeo_visible = not _parpadeo_visible
	banner_alarma.modulate.a = 1.0 if _parpadeo_visible else 0.15
	
func _on_tick_planta(datos: Dictionary) -> void:
	if _en_trip:
		return
	# B1 
	tanque_tk101.set_pct(datos["TK101.pct"])
	tanque_tk201.set_pct(datos["TK201.pct"])
	bomba_b101.set_marcha(datos["B101.marcha"])
	valvula_v102.set_apertura(datos["V102.apertura"])
	valvula_v201.set_apertura(datos["V201.apertura"])
	f101_label.text = "F-101: %.3f m³/s" % datos["F101.caudal"]
	f102_label.text = "F-102: %.3f m³/s" % datos["F102.caudal"]
	f201_label.text = "F-201: %.3f m³/s" % datos["F201.caudal"]
	
	# TODO (PARCIAL · M1): pasa `datos` a tu gestor de alarmas y refleja el
	# resultado: banner con la alarma más grave sin reconocer, parpadeo,
	# bocina (alarma.wav en bucle mientras haya activas sin reconocer) y cada
	# transición agregada al historial (ItemList).
	_gestor.evaluar(datos)
	if datos["TK101.pct"] <= 0.5:
		_disparar_trip("TANQUE VACÍO — TK-101 sin nivel")
	_actualizar_bocina()
	_actualizar_banner()
	
	# TODO (PARCIAL · M2): en modo AUTO, pasa `datos` a tu control; los
	# interlocks se aplican SIEMPRE.
	_control.procesar(datos)
	
	# TODO (PARCIAL · M3): alimenta la tendencia (tendencia.agregar_muestra).
	_acum_tendencia += get_process_delta_time()

	if _acum_tendencia >= INTERVALO_TENDENCIA:

		_acum_tendencia = 0.0

		tendencia.agregar_muestra(
			"TK101",
			datos["TK101.pct"]
		)

	tendencia.agregar_muestra(
		"TK201",
		datos["TK201.pct"]
	)
func _actualizar_bocina() -> void:
	if _gestor.hay_activas_sin_reconocer():
		_play(_sfx_alarma)
	else:
		_stop(_sfx_alarma)

func _actualizar_banner() -> void:
	var texto := _gestor.alarma_mas_grave()
	if texto == "":
		banner_alarma.text = "— sin alarmas —"
		banner_alarma.add_theme_color_override("font_color", Color(0.55, 0.65, 0.55))
	else:
		banner_alarma.text = "⚠  " + texto
		banner_alarma.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1))

func _on_evento_planta(tipo: String, mensaje: String) -> void:
	print("EVENTO [", tipo, "]: ", mensaje)
	match tipo:
		"rebalse":
			_disparar_trip("REBALSE — " + mensaje)
		"vacio":
			_disparar_trip("TANQUE VACÍO — " + mensaje)
	# TODO (PARCIAL · M4): registra todo evento en tu log persistente.

func _on_evento_escenario(mensaje: String) -> void:
	print("ESCENARIO: ", mensaje)
	# TODO (PARCIAL · M4): al historial y al log persistente también.
	
#historial visual 
func _on_alarma_activada(id: String, mensaje: String) -> void:
	var linea: String = _gestor.obtener_historial().back()
	historial.add_item(linea)
	historial.set_item_custom_fg_color(historial.item_count - 1, Color(1.0, 0.35, 0.35))
	_scroll_historial()

func _on_alarma_reconocida(id: String) -> void:
	var linea: String = _gestor.obtener_historial().back()
	historial.add_item(linea)
	historial.set_item_custom_fg_color(historial.item_count - 1, Color(1.0, 0.85, 0.2))
	_scroll_historial()

func _on_alarma_normalizada(id: String) -> void:
	var linea: String = _gestor.obtener_historial().back()
	historial.add_item(linea)
	historial.set_item_custom_fg_color(historial.item_count - 1, Color(0.4, 0.9, 0.4))
	_scroll_historial()


func _scroll_historial() -> void:
	# Mantiene el historial anclado al último evento
	historial.ensure_current_is_visible()

#clicks 
	
func _ciclar_valvula(tag: String) -> void:
	if _en_trip:
		return
	var actual = planta.leer(tag + ".apertura")
	# Encontrar el siguiente paso en el ciclo
	var siguiente := PASOS_VALVULA[0]
	for i in PASOS_VALVULA.size():
		if actual < PASOS_VALVULA[i] - 0.05:
			siguiente = PASOS_VALVULA[i]
			break
		elif i == PASOS_VALVULA.size() - 1:
			siguiente = PASOS_VALVULA[0]
	planta.comandar(tag + ".apertura", siguiente)
	_play(_sfx_click)

func _on_bomba_b101_presionada() -> void:
	if _en_trip:
		return
	planta.comandar("B101.marcha", not planta.leer("B101.marcha"))
	_play(_sfx_click)

func _on_valvula_v102_presionada() -> void:
	_ciclar_valvula("V102")


func _on_valvula_v201_presionada() -> void:
	_ciclar_valvula("V201")

# --- panel de operación ---

func _on_boton_reconocer_pressed() -> void:
	_gestor.reconocer_todas()
	_play(_sfx_reconocer)
	_actualizar_bocina()
	_actualizar_banner()


func _on_boton_modo_pressed() -> void:
	_control.modo_auto = not _control.modo_auto
	if _control.modo_auto:
		boton_modo.text = "Modo: AUTO"
		boton_modo.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		boton_modo.text = "Modo: MANUAL"
		boton_modo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))



func _on_boton_escenario_pressed() -> void:
	if selector_escenario.selected < 0:
		return
	var archivo = selector_escenario.get_item_text(selector_escenario.selected)
	escenarios.cargar_y_ejecutar("res://data/escenarios/" + archivo)
	
