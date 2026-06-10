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
