# Planta SCADA — HMI en Godot 4.6

Proyecto del Segundo Parcial de Infografía I/2026.  
Simulación y visualización de una planta de dos tanques de agua con sistema de alarmas y control automático.

## Cómo correr el HMI

1. Tener instalado **Godot 4.6**.
2. Clonar o descargar este repositorio.
3. Abrir la carpeta del proyecto desde el editor de Godot (no subir la carpeta `.godot/`).
4. Presionar `F5` o el botón **Play**. La escena principal es `scenes/hmi.tscn`.

No se requieren plugins ni dependencias externas.

## Mecánicas implementadas

### B1 — Sinóptico completo en vivo
Todos los elementos de la planta se actualizan en cada tick de simulación: nivel de TK-101 y TK-201, marcha de la bomba B-101, apertura de V-102 y V-201, y los tres caudales (F-101, F-102, F-201) en m³/s con tres decimales.

### B2 — Control manual de válvulas
Las válvulas V-102 y V-201 se operan con clic. Cada clic cicla la apertura en tres pasos: **0% → 50% → 100% → 0%**. Se eligió este esquema por ser simple y representativo de una operación discreta real (cerrada, media apertura, abierta). La bomba B-101 alterna marcha/parada con cada clic.

### B3 — Parada de emergencia y reinicio
Los eventos de rebalse y vacío emitidos por la planta disparan un estado de **TRIP**: la simulación se congela, se muestra una pantalla roja con el motivo, y el operador puede reiniciar con el botón correspondiente. Adicionalmente, se detecta el vacío de TK-101 por lectura directa de sensor (la planta no emite evento para ese caso).

### B4 — Sonidos de operación
- `click.wav` — cada comando de bomba o válvula.
- `alarma.wav` — bocina en bucle mientras haya alarmas activas sin reconocer (loop manual vía señal `finished`).
- `reconocer.wav` — al presionar el botón Reconocer.
- `trip.wav` — al dispararse la parada de emergencia.

### M1 — Sistema de alarmas

**Límites elegidos** (iguales para ambos tanques):
**TK-101 & TK-201 (%)**
- LL -> 5
- L -> 15 
- H -> 85 
- HH -> 95 

Se eligió un rango amplio (15%–85%) para que los escenarios de demostración activen alarmas sin llegar inmediatamente al TRIP, permitiendo observar la escalada L → LL y H → HH.

**Máquina de estados:** cada alarma (id = tag.nivel, p.ej. TK201.pct.L) tiene su propio estado independiente:  
	NORMAL → ACTIVA → RECONOCIDA → NORMAL.  
	Varias alarmas pueden coexistir activas al mismo tiempo.

**Banner:** muestra la alarma más grave sin reconocer según prioridad  
HH=4 > LL=3 > H=2 > L=1  
Parpadea mientras haya alarmas activas sin reconocer; se detiene al reconocer.

**Historial:** cada transición se registra con el tiempo de simulación, por ejemplo: `T=  23.4s  TK201.pct.L  → ACTIVA`.

### M2 — Control automático e interlocks

**Control por histéresis de TK-201 vía V-102:**
- Si TK-201 cae bajo **40%** → V-102 se abre al 100%.
- Si TK-201 sube sobre **60%** → V-102 se cierra.
- Entre ambos umbrales se mantiene el estado anterior, eliminando el chattering.

Se eligió la banda 40%–60% para tener margen suficiente ante el escenario de pico de demanda (2.5x) sin llegar a LL ni HH.

**Interlocks (activos siempre, incluso en MANUAL):**
- TK-101 ≥ 93% → bomba B-101 se apaga forzosamente (previene rebalse de TK-101).
- TK-201 ≥ 93% → V-102 se cierra forzosamente (previene rebalse de TK-201).

Los umbrales de interlock (93%) se fijaron por debajo del límite HH (95%) para actuar antes de que se dispare la alarma de mayor gravedad.

El botón **Modo** alterna entre MANUAL y AUTO. En MANUAL el operador controla todo con clics (respetando los interlocks). En AUTO la histéresis gestiona V-102 automáticamente.


### M3 — Tendencias en tiempo real

Se implementó un widget de tendencias personalizado (`TendenciaWidget`) dibujado completamente mediante `_draw()`.

Características:

* Visualización simultánea de los niveles de **TK-101** y **TK-201**.
* Escala vertical fija de **0% a 100%**.
* Buffer circular limitado a **300 muestras** para evitar crecimiento indefinido de memoria.
* Leyenda con colores diferenciados:

  * TK-101 → Cyan
  * TK-201 → Verde
* Líneas de referencia correspondientes a los límites de alarma:

  * LL = 5%
  * L = 15%
  * H = 85%
  * HH = 95%

La tendencia se alimenta periódicamente desde el HMI mediante `agregar_muestra()` y permite visualizar claramente la evolución de los niveles durante los escenarios de falla.

Por ejemplo, en el escenario de pico de demanda puede observarse la caída progresiva de TK-201 y su posterior recuperación cuando la demanda vuelve a la normalidad.

---

### M4 — Configuración en datos y log persistente

#### Configuración externa

Los parámetros físicos de la planta fueron extraídos a:

`res://data/planta.json`

Incluye:

* Altura de tanques
* Área de tanques
* Caudal de bomba
* Constantes hidráulicas de válvulas

Los límites de alarma fueron extraídos a:

`res://data/alarmas.json`

De esta forma es posible modificar el comportamiento de la planta o de las alarmas sin recompilar ni modificar código fuente.

#### Log persistente

Se implementó un sistema de registro mediante la clase `EventLogger`.

Archivo generado:

`user://eventos.log`

Eventos registrados:

* Alarmas activadas
* Alarmas reconocidas
* Alarmas normalizadas
* Eventos de escenario
* Eventos de planta
* Estados de TRIP

El archivo permanece entre ejecuciones, permitiendo revisar eventos históricos incluso después de cerrar y volver a abrir la aplicación.

---

## Decisiones de diseño

### Alarmas

Se utilizó prioridad:

HH > LL > H > L

porque en operación industrial una condición HH suele representar un riesgo inmediato de rebalse, mientras que LL representa riesgo de pérdida de suministro.

### Tendencias

Se eligió una escala fija 0–100% para facilitar la comparación visual entre tanques y evitar cambios dinámicos de escala que dificulten la interpretación del operador.

### Control automático

Se utilizó histéresis en lugar de control proporcional o PID para mantener la simplicidad del sistema y evitar oscilaciones frecuentes de la válvula V-102.

### Interlocks

Los enclavamientos fueron colocados antes del límite HH para actuar preventivamente y no reactivamente.

---

## Archivos de configuración

### planta.json

Contiene la parametrización física de la planta:

* Altura de tanques
* Área de tanques
* Caudal de bomba
* Constantes hidráulicas

### alarmas.json

Contiene los límites:

* LL
* L
* H
* HH

para cada variable supervisada.

Modificar estos archivos cambia inmediatamente el comportamiento de la simulación sin necesidad de modificar código.

---

## Estado del proyecto

Requisitos implementados:

* ✅ B1 — Sinóptico completo
* ✅ B2 — Control manual
* ✅ B3 — TRIP y reinicio
* ✅ B4 — Sonidos
* ✅ B5 — Sin errores en consola
* ✅ M1 — Alarmas
* ✅ M2 — Control automático e interlocks
* ✅ M3 — Tendencias en tiempo real
* ✅ M4 — Configuración externa y log persistente

Proyecto desarrollado sobre Godot 4.6.

## Recursos externos consultados

- Documentación oficial de Godot 4: https://docs.godotengine.org/en/stable/
- Referencia de GDScript (tipos, señales, _physics_process): https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- Referencia de AudioStreamPlayer y loop en WAV: https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html
