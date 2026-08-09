extends CanvasLayer

@export var player1: CharacterBody2D
@export var player2: CharacterBody2D

@onready var p1_bar: TextureProgressBar = $Player1Health
@onready var p2_bar: TextureProgressBar = $Player2Health

func _ready() -> void:
	if is_instance_valid(player1):
		p1_bar.max_value = player1.max_health
		p1_bar.value = player1.current_health
		player1.health_changed.connect(_on_p1_health_changed)

	if is_instance_valid(player2):
		p2_bar.max_value = player2.max_health
		p2_bar.value = player2.current_health
		player2.health_changed.connect(_on_p2_health_changed)

func _on_p1_health_changed(current: int, _max_hp: int) -> void:
	p1_bar.value = current

func _on_p2_health_changed(current: int, _max_hp: int) -> void:
	p2_bar.value = current
