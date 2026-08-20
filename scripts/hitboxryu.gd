extends Area2D

@export var dano_soco: int = 10
@export var dano_chute: int = 15

@onready var col_shape = $CollisionShape2D
@onready var sprite = $"../AnimatedSprite2D" # Pega o AnimatedSprite2D do nó pai

var dano_atual: int = 0

func _ready() -> void:
	# A hitbox sempre inicia desativada
	col_shape.disabled = true
	# Conecta a detecção de impacto
	area_entered.connect(_on_area_entered)

func _process(_delta: float) -> void:
	# Ajusta a posição e o tamanho da Hitbox baseando-se no frame do ataque
	atualizar_hitbox()

func atualizar_hitbox() -> void:
	var anim = sprite.animation
	var frame = sprite.frame
	var lado = -1.0 if sprite.flip_h else 1.0 # Inverte o X se o Ryu estiver olhando para a esquerda
	var formato = col_shape.shape as RectangleShape2D

	match anim:
		"punch":
			if frame >= 2 and frame <= 4:
				col_shape.disabled = false
				dano_atual = dano_soco
				formato.size = Vector2(35, 20)
				col_shape.position = Vector2(40 * lado, -20)
			else:
				col_shape.disabled = true

		"kick":
			if frame >= 3 and frame <= 4:
				col_shape.disabled = false
				dano_atual = dano_chute
				formato.size = Vector2(45, 25)
				col_shape.position = Vector2(45 * lado, 5)
			else:
				col_shape.disabled = true

		_:
			# Desativa em qualquer outra animação (Idle, Run, Fall, etc.)
			col_shape.disabled = true

func _on_area_entered(area_inimiga: Area2D) -> void:
	# Verifica se a área atingida tem uma função para receber dano
	if area_inimiga.has_method("receber_dano"):
		area_inimiga.receber_dano(dano_atual)
	elif area_inimiga.owner.has_method("receber_dano"):
		area_inimiga.owner.receber_dano(dano_atual)
