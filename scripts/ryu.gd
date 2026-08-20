extends CharacterBody2D

# Estados essenciais para um jogo de luta 1v1
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	ATTACK,
	HURT,
	DEAD
}

# Identificador do jogador (Defina 1 ou 2 no Inspetor)
@export_range(1, 2) var player_id: int = 1

# Sinais para a Interface (UI)
signal health_changed(current_health: int, max_health: int)
signal died

# Atributos de Vida e Movimento
@export var max_health: int = 100
@export var max_speed = 220.0
@export var acceleration = 800.0
@export var deceleration = 800.0
const JUMP_VELOCITY = -380.0

var current_health: int
var direction: float = 0.0
var status: PlayerState = PlayerState.IDLE
var current_attack: String = "punch" # Guarda qual golpe está sendo executado ("punch" ou "kick")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	current_health = max_health
	anim.frame_changed.connect(_on_frame_changed)
	
	if hitbox_collision:
		hitbox_collision.disabled = true
		
	go_to_idle_state()

# ==============================================================================
# LOOP PRINCIPAL E MÁQUINA DE ESTADOS
# ==============================================================================

func _physics_process(delta: float) -> void:
	# Aplica gravidade se não estiver no chão (exceto se estiver morto)
	if status != PlayerState.DEAD and not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		PlayerState.IDLE:
			idle_state(delta)
		PlayerState.WALK:
			walk_state(delta)
		PlayerState.JUMP:
			jump_state(delta)
		PlayerState.FALL:
			fall_state(delta)
		PlayerState.ATTACK:
			attack_state(delta)
		PlayerState.HURT:
			hurt_state(delta)
		PlayerState.DEAD:
			dead_state(delta)

	move_and_slide()

# ==============================================================================
# TRANSIÇÕES DE ESTADO (ENTRADA)
# ==============================================================================

func go_to_idle_state():
	status = PlayerState.IDLE
	anim.play("idle")

func go_to_walk_state():
	status = PlayerState.WALK
	anim.play("walk")

func go_to_jump_state():
	status = PlayerState.JUMP
	anim.play("jump")
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func go_to_fall_state():
	status = PlayerState.FALL
	anim.play("fall")

func go_to_attack_state(attack_type: String = "punch"):
	status = PlayerState.ATTACK
	current_attack = attack_type
	
	# Ajusta o lado da Hitbox com base no espelhamento do sprite
	if has_node("Hitbox"):
		if anim.flip_h:
			$Hitbox.position.x = -abs($Hitbox.position.x)
		else:
			$Hitbox.position.x = abs($Hitbox.position.x)
		
	# Toca a animação correspondente: "punch" ou "kick"
	anim.play(attack_type)
	
	if not anim.animation_finished.is_connected(_on_attack_finished):
		anim.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func go_to_hurt_state():
	status = PlayerState.HURT
	anim.play("hurt")
	
	if hitbox_collision:
		hitbox_collision.disabled = true
		
	if not anim.animation_finished.is_connected(_on_hurt_finished):
		anim.animation_finished.connect(_on_hurt_finished, CONNECT_ONE_SHOT)

func go_to_dead_state():
	status = PlayerState.DEAD
	died.emit()
	
	if hitbox_collision:
		hitbox_collision.disabled = true
		
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	if anim.sprite_frames.has_animation("dead"):
		anim.play("dead")

# ==============================================================================
# LÓGICA DE CADA ESTADO
# ==============================================================================

func idle_state(delta: float):
	move(delta)
	
	if check_attack_input():
		return
	if check_jump_input():
		return
		
	if velocity.x != 0:
		go_to_walk_state()

func walk_state(delta: float):
	move(delta)
	
	if check_attack_input():
		return
	if check_jump_input():
		return
		
	if velocity.x == 0:
		go_to_idle_state()
	elif not is_on_floor():
		go_to_fall_state()

func jump_state(delta: float):
	move(delta)
	
	if check_attack_input():
		return
		
	if velocity.y > 0:
		go_to_fall_state()

func fall_state(delta: float):
	move(delta)
	
	if check_attack_input():
		return
		
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()

func attack_state(delta: float):
	# Desacelera o personagem durante o golpe se estiver no chão
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func hurt_state(delta: float):
	# Recuo leve ao tomar dano
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func dead_state(_delta: float):
	velocity.x = 0

# ==============================================================================
# MÉTODOS AUXILIARES E SISTEMA DE COMBATE
# ==============================================================================

func move(delta: float):
	update_direction()
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func update_direction():
	var prefix := "p" + str(player_id) + "_"
	direction = Input.get_axis(prefix + "left", prefix + "right")
	
	if direction < 0:
		anim.flip_h = false # Mantém original para esquerda
	elif direction > 0:
		anim.flip_h = true  # Espelha para a direita

func check_jump_input() -> bool:
	var prefix := "p" + str(player_id) + "_"
	if Input.is_action_just_pressed(prefix + "jump") and is_on_floor():
		go_to_jump_state()
		return true
	return false

func check_attack_input() -> bool:
	var prefix := "p" + str(player_id) + "_"
	
	if Input.is_action_just_pressed(prefix + "punch"):
		go_to_attack_state("punch")
		return true
	elif Input.is_action_just_pressed(prefix + "kick"):
		go_to_attack_state("kick")
		return true
		
	return false

func _on_frame_changed():
	if status == PlayerState.ATTACK and anim.animation == current_attack:
		if hitbox_collision:
			hitbox_collision.disabled = (anim.frame != 4)

func _on_attack_finished():
	if status == PlayerState.ATTACK:
		if hitbox_collision:
			hitbox_collision.disabled = true
			
		if is_on_floor():
			if velocity.x == 0:
				go_to_idle_state()
			else:
				go_to_walk_state()
		else:
			go_to_fall_state()

func _on_hurt_finished():
	if status == PlayerState.HURT:
		go_to_idle_state()

# Receber Dano
func take_damage(amount: int):
	if status == PlayerState.DEAD:
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		go_to_dead_state()
	else:
		go_to_hurt_state()
