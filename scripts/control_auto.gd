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

var planta: PlantaSim = null

# TODO (PARCIAL · M2): implementa la histéresis y los interlocks.
