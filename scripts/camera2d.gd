extends Camera2D

# Arraste os dois nós de jogador para cá no Inspetor
@export var player1: Node2D
@export var player2: Node2D

# Configurações de Zoom
@export var min_zoom: float = 1  # Zoom quando estão LONGE (visão mais ampla)
@export var max_zoom: float = 1.3  # Zoom quando estão PERTO (visão aproximada)
@export var min_distance: float = 200.0  # Distância para aplicar zoom máximo
@export var max_distance: float = 800.0  # Distância para aplicar zoom mínimo
@export var zoom_speed: float = 5.0     # Suavidade da transição de zoom
@export var move_speed: float = 5.0     # Suavidade do movimento da câmera

func _process(delta: float) -> void:
	if not is_instance_valid(player1) or not is_instance_valid(player2):
		return
	# No seu _process ou _physics_process da Camera2D:
	var center_x: float = (player1.global_position.x + player2.global_position.x) / 2.0

	# Centraliza suavemente apenas no X
	global_position.x = lerp(global_position.x, center_x, move_speed * delta)

	# Trave o Y na altura média ideal da sua arena
	global_position.y = 450.0  # Ajuste este valor até a câmera ficar na altura perfeita

	# Mantém o X dinâmico, mas trava o Y em um valor fixo (ex: altura do chão)
	global_position.x = lerp(global_position.x, center_x, move_speed * delta)
	global_position.y = 920.0 # Substitua 360.0 pela altura central ideal da sua arena no editor

	# 2. Distância entre os jogadores
	var distance: float = player1.global_position.distance_to(player2.global_position)

	# 3. Cálculo proporcional do Zoom (inverso: mais longe = menor zoom)
	var target_zoom_value: float = remap(distance, min_distance, max_distance, max_zoom, min_zoom)
	target_zoom_value = clamp(target_zoom_value, min_zoom, max_zoom)

	# 4. Aplica o Zoom de forma suave
	var target_zoom := Vector2(target_zoom_value, target_zoom_value)
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
