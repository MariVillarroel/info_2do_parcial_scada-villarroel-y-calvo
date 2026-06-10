# Segundo Parcial — Planta SCADA (Infografía, I/2026)

**Modalidad:** proyecto para casa, individual. **Plazo:** 1 a 2 semanas (la fecha exacta se publica en Moodle).
**Motor:** Godot 4.4 o superior. **Entrega:** URL de tu repositorio (ver *Entrega* al final).

> Esta es la **pista C** del parcial. Hay varias pistas (Match-3, Micromouse,
> Planta SCADA); eliges **una sola**. Todas valen lo mismo y se califican con
> la misma estructura. Esta pista premia sobre todo la **visualización y la
> interfaz** (sinópticos, alarmas, tendencias — el módulo 9 del curso); si
> prefieres algoritmos, mira la pista Micromouse.

---

## 1. Contexto

Un **SCADA/HMI** es la cara visible de casi toda planta industrial: pantallas
sinópticas donde el operador ve tanques, bombas y válvulas en vivo, recibe
alarmas, observa tendencias y actúa. Es software de visualización profesional
— exactamente el tipo de cosa para la que también sirve un motor gráfico como
Godot — y construir uno bien hecho es un oficio real (búscalo: "HMI design",
"high performance HMI").

Recibes un HMI **funcional pero incompleto** sobre una planta simulada de dos
tanques de agua:

```
POZO ──> B-101 (bomba) ──> TK-101 ──> V-102 ──> TK-201 ──> V-201 ──> RED
```

El núcleo ya está resuelto: la **física de la planta** corre sola (caudales,
niveles, rebalses), se opera con una API de tags como un PLC real
(`leer("TK101.pct")`, `comandar("B101.marcha", true)`), los **widgets** de
tanque/bomba/válvula están dibujados con `_draw()`, y un **reproductor de
escenarios** inyecta fallas programadas (válvula atascada, bomba fallada,
sensor con deriva, pico de demanda). Abre el proyecto, presiona Play y verás
TK-101 moverse y la bomba responder a tus clics: ese es el patrón que debes
replicar.

Lo que **no** está hecho es lo que convierte ese núcleo en un SCADA de verdad:
el sinóptico completo, las **alarmas**, el **control automático**, las
**tendencias** y el registro de eventos. Ese es tu trabajo.

> **Detalle importante (y realista):** `leer()` devuelve lo que dicen los
> *sensores*, y `comandar()` puede **no obedecerse** (válvula atascada, bomba
> fallada). Los escenarios inyectan exactamente eso. Un HMI que confía a
> ciegas en sus propios comandos se evalúa solo a medias: tu sistema debe
> decidir y alarmar con las **lecturas**.

> **Aviso de honestidad académica.** No existe un tutorial de "SCADA en
> Godot" que resuelva esto (lo verificamos). Puedes consultar recursos de
> diseño HMI y de Godot — y **debes citarlos** en tu README — pero el código
> es tuyo: la entrega se evalúa **inyectando escenarios de falla que no
> conoces** y revisando tu historial de commits. El plagio entre compañeros y
> el "volcado único" de todo el código en un solo commit se penalizan.

---

## 2. Qué se te entrega

- `scripts/planta_sim.gd` — la planta: física, API de tags, eventos de
  rebalse/vacío y el banco de pruebas de fallas. **Resuelto, no lo modifiques**
  (excepción: M4 te pide externalizar sus parámetros a datos).
- `scripts/reproductor_escenarios.gd` — inyector de fallas desde `.json`.
  **Resuelto.** El formato está documentado en el propio archivo.
- `scripts/tanque_widget.gd`, `bomba_widget.gd`, `valvula_widget.gd` — widgets
  de sinóptico con `_draw()`, con clic incluido. **Resueltos**; úsalos de
  referencia para los tuyos.
- `scripts/hmi.gd` — el controlador del HMI. Trae **dos ejemplos resueltos**
  (nivel de TK-101 en vivo y arranque/parada de B-101 con clic) y marcadores
  `# TODO (PARCIAL · ...)` en todos los huecos.
- `scripts/gestor_alarmas.gd` y `scripts/control_auto.gd` — esqueletos de M1 y
  M2 con el diseño sugerido en comentarios.
- `scripts/tendencia_widget.gd` — esqueleto de M3.
- `scenes/hmi.tscn` — la pantalla: sinóptico, panel de operación, botones ya
  conectados (con cuerpos vacíos).
- `data/escenarios/` — dos escenarios de demostración. La revisión usa otros.
- `assets/sounds/` — `alarma.wav`, `reconocer.wav`, `click.wav`, `trip.wav`.

**Cómo ejecutarlo:** abre esta carpeta en el editor de Godot y presiona `F5`.
La escena principal es `scenes/hmi.tscn`.

---

## 3. Requisitos base — "termina el HMI" (45 pts)

| # | Requisito | Pts | Criterio de aceptación |
|---|---|---:|---|
| B1 | Sinóptico completo en vivo | 10 | TK-201, bomba, ambas válvulas y los tres caudales reflejan el estado en cada tick (TK-101 ya está hecho de ejemplo) |
| B2 | Control manual completo | 8 | clic en V-102 y V-201 las opera (ciclo de apertura o slider) con confirmación visual; la bomba ya está hecha de ejemplo |
| B3 | Parada de emergencia + reinicio | 15 | rebalse o tanque vacío disparan un estado de TRIP explícito: pantalla con el motivo, planta detenida, sonido, y reinicio funcional |
| B4 | Sonidos de operación | 7 | clic de comando, bocina de alarma en bucle, reconocimiento y trip, usando los wav provistos |
| B5 | Corre limpio | 5 | sin errores en consola; el núcleo (planta, escenarios, ejemplos) sigue funcionando |

---

## 4. Mecánicas obligatorias — el SCADA de verdad (45 pts)

### M1. Sistema de alarmas — 15 pts
- Límites **LL / L / H / HH** por variable (al menos los niveles de ambos
  tanques) y una **máquina de estados** por alarma:
  NORMAL → ACTIVA → RECONOCIDA → NORMAL.
- Banner con la alarma más grave sin reconocer (parpadeo), **bocina en bucle**
  mientras haya activas sin reconocer, botón **Reconocer**, e **historial**
  con hora de simulación de cada transición.
- *Aceptación:* inyecto un escenario, las alarmas correctas aparecen en el
  orden correcto (L antes que LL...), la bocina suena hasta reconocer y el
  historial cuenta la historia completa.

### M2. Control automático + interlocks — 10 pts
- Modo **MANUAL/AUTO** conmutable. En AUTO, **control por histéresis** del
  nivel de TK-201 operando V-102 (dos umbrales: sin "castañeo").
- **Interlocks activos siempre** (también en MANUAL): bomba bloqueada con
  TK-101 casi lleno; V-102 bloqueada con TK-201 casi lleno.
- *Aceptación:* en AUTO la planta aguanta el escenario del pico de demanda sin
  intervención y sin disparar HH/LL; los interlocks impiden que yo provoque un
  rebalse a mano.

### M3. Tendencias en tiempo real — 14 pts
- Un **strip chart** dibujado por ti (`_draw()`): al menos los niveles de los
  dos tanques, desplazándose, con eje 0–100 %, leyenda y **líneas de
  referencia** (límites de alarma o setpoint).
- *Aceptación:* inyecto un escenario y la historia se lee en el gráfico (caída
  de nivel, recuperación); el buffer no crece sin límite.

### M4. Configuración en datos + log persistente — 6 pts
- Parámetros de la planta **y** límites de alarma cargados desde archivos en
  `data/` (cambiar un límite no debe requerir tocar código).
- **Log de eventos persistente** en `user://`: alarmas, comandos del operador,
  eventos de planta y de escenario, con hora. Sobrevive a cerrar y reabrir.
- *Aceptación:* edito un límite en el archivo y la alarma cambia; reabro el
  juego y el log anterior sigue ahí (y se puede ver o exportar).

---

## 5. Bonus (tope 10 pts)

Suma solo si los requisitos base y obligatorios están sólidos. Ejemplos:
- **Control PID** del nivel (en vez de solo histéresis) con sus ganancias en
  datos y una gráfica del error.
- **Multipantalla**: vista general + vista de detalle por tanque
  (`change_scene_to_file` o pestañas), estilo navegación SCADA real.
- **Reproducción histórica**: volver a ver los últimos N minutos de tendencia
  con un scrubber.
- **Simbología ISA** (P&ID) para los equipos, o tema claro/oscuro con `Theme`.
- **Editor de escenarios** dentro del juego.

---

## 6. Evaluación

**Total:** 90 pts de requisitos + 10 pts de bonus = **100**.

| Bloque | Pts |
|---|---:|
| Base ("termina el HMI") | 45 |
| Mecánicas obligatorias (M1–M4) | 45 |
| Bonus | 10 (tope) |

**Regla de tope:** si tu entrega **no implementa ninguna** de las cuatro
mecánicas obligatorias, tu nota **no supera 50/100**, sin importar cuán pulido
esté lo demás.

**La revisión inyecta 2–3 escenarios ocultos** (mismo formato JSON que los de
demostración) y observa: ¿aparecen las alarmas correctas? ¿los interlocks
aguantan? ¿la tendencia y el log cuentan lo que pasó? Si tu sistema solo
funciona con los dos escenarios incluidos, M1–M3 no cuentan completos.

**Calidad e integridad** (pueden bajar la nota): historial de commits con
"volcado único" de último momento, similitud alta con la entrega de otro
compañero, o lógica que lee el estado interno de la planta en vez de la API de
tags. Cita en tu README todo recurso externo que hayas usado.

---

## 7. Entrega

1. Haz un **fork** (o copia a un repo propio) de este proyecto base.
2. Trabaja con **commits frecuentes y descriptivos**: el historial cuenta y se revisa.
3. En el **README** de tu repo, escribe: cómo correr el HMI, qué mecánicas
   implementaste (y tus decisiones: límites elegidos, interacción de válvulas,
   interlocks extra), y la lista de recursos externos consultados (con enlaces).
4. Entrega la **URL de tu repositorio** por Moodle antes de la fecha límite.

Asegúrate de que el proyecto **abra y corra en Godot 4.4+ sin errores** en una
máquina limpia (no subas la carpeta `.godot/`).
