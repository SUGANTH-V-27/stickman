

extends CharacterBody2D

# -------------------- CONFIG --------------------
@export var speed := 120.0
@export var max_health := 100
@export var attack_damage := 10
@export var attack_cooldown := 1.5
@export var gravity := 2000.0

# -------------------- STATE --------------------
enum State { IDLE, MOVE, ATTACK, HIT, DEAD }
var state: State = State.IDLE

var health := 0
var player: CharacterBody2D
var can_attack := true

# -------------------- NODES --------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range: Area2D = $attack_range
@onready var punch_hitbox: Area2D = $punchhitbox
@onready var hit_sfx: AudioStreamPlayer = $AudioStreamPlayer/hit_sfx
# ------------------------------------------------

func _ready() -> void:
	health = max_health

	attack_range.monitoring = true
	punch_hitbox.monitoring = false

	sprite.play("idle")

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# ------------------------------------------------

func _physics_process(delta: float) -> void:
	# Safety check for player reference
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return
	
	# ---- gravity ----
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if state in [State.DEAD, State.HIT]:
		move_and_slide()
		return

	if state == State.ATTACK:
		velocity.x = 0
		move_and_slide()
		return
	   
	sprite.flip_h = player.global_position.x < global_position.x

	if not attack_range.has_overlapping_bodies():
		state = State.MOVE
		velocity.x = -speed if sprite.flip_h else speed
		sprite.play("walk")
		move_and_slide()
		return

	state = State.IDLE
	velocity.x = 0
	sprite.play("idle")
	move_and_slide()

	if can_attack:
		attack()


# ------------------------------------------------
# ATTACK
# ------------------------------------------------

func attack() -> void:
	state = State.ATTACK
	can_attack = false

	sprite.play("punch")

	await get_tree().create_timer(0.1).timeout
	punch_hitbox.monitoring = true

	await get_tree().create_timer(0.05).timeout
	punch_hitbox.monitoring = false

	await sprite.animation_finished
	state = State.IDLE

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# ------------------------------------------------
# HITBOX SIGNAL
# ------------------------------------------------

func _on_punchhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return
	if body.is_in_group("player"):
		print("👊 Enemy attacking player! Damage: ", attack_damage)
		hit_sfx.play()  
		var dir := -1 if sprite.flip_h else 1
		if body.has_method("take_damage"):
			body.take_damage(attack_damage, dir, 200)
			print("✅ Damage call successful")
		else:
			print("❌ ERROR: Player doesn't have take_damage method!")
		
		# Show damage effects
		var main = get_tree().current_scene
		if main and main.has_method("get") and main.get("combat_system"):
			main.combat_system.on_hit(
				self,
				body,
				attack_damage,
				body.global_position
			)

# ------------------------------------------------
# DAMAGE
# ------------------------------------------------

func take_damage(amount: int, knockback_dir: int, force: float) -> void:
	if state == State.DEAD:
		return

	punch_hitbox.monitoring = false
	can_attack = false

	state = State.HIT
	health -= amount

	velocity.x = knockback_dir * force
	sprite.play("hit")

	await get_tree().create_timer(0.2).timeout
	velocity.x = 0

	if health <= 0:
		die()
		return

	state = State.IDLE
	sprite.play("idle")
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	

# ------------------------------------------------

func die() -> void:
	state = State.DEAD
	sprite.play("death")
	await sprite.animation_finished
	queue_free()

# ------------------------------------------------
# PAUSE SUPPORT
# ------------------------------------------------

func _set_paused_state(paused: bool) -> void:
	# Stop logic
	set_process(!paused)
	set_physics_process(!paused)
	set_process_input(!paused)

	# Stop or resume animation
	if paused:
		sprite.pause()
	else:
		sprite.play(sprite.animation)

	# Pause timers if any exist
	for child in get_children():
		if child is Timer:
			child.paused = paused
