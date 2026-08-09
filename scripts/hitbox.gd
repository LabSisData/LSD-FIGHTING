extends Area2D

@export var damage: int = 15

func _ready() -> void:
	# Conecta o sinal por código caso não esteja conectado no editor
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Evita que o ataque cause dano no próprio jogador que atacou
	if body == owner:
		return
		
	# Se o corpo atingido for o outro jogador, aplica o dano
	if body.has_method("take_damage"):
		body.take_damage(damage)
