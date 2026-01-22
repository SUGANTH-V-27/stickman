extends CharacterBody2D

# -------------------- CONFIG --------------------
@export var speed := 80.0  # Slower than normal enemies
@export var max_health := 300  # Much more health
@export var attack_damage := 40  # More damage
@export var attack_cooldown := 2.0  # Slower attacks
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
	add_to_group("boss")  # Tag as boss
	
	attack_range.monitoring = true
	punch_hitbox.monitoring = false
	
	sprite.play("boss_idle")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	print("🔥 BOSS SPAWNED with ", health, " HP!")

# ------------------------------------------------

func _physics_process(delta: float) -> void:
	# Safety check for player
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
		sprite.play("boss_walk")
		move_and_slide()
		return
	
	state = State.IDLE
	velocity.x = 0
	sprite.play("boss_idle")
	move_and_slide()
	
	if can_attack:
		attack()


# ------------------------------------------------
# ATTACK
# ------------------------------------------------

func attack() -> void:
	if not is_instance_valid(self):
		return
		
	state = State.ATTACK
	can_attack = false
	
	sprite.play("boss_punch")
	
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self):
		return
	punch_hitbox.monitoring = true
	
	await get_tree().create_timer(0.05).timeout
	if not is_instance_valid(self):
		return
	punch_hitbox.monitoring = false
	
	await sprite.animation_finished
	if not is_instance_valid(self):
		return
	state = State.IDLE
	
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	can_attack = true

# ------------------------------------------------
# HITBOX SIGNAL
# ------------------------------------------------

func _on_punchhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return
	if not is_instance_valid(body) or not body.is_in_group("player"):
		return
		
	if body.has_method("take_damage"):
		hit_sfx.play()
		var dir := -1 if sprite.flip_h else 1
		body.take_damage(attack_damage, dir, 300)  # More knockback
		
		# Show damage effects - with safety checks
		var main = get_tree().current_scene
		if is_instance_valid(main) and main.has_method("get"):
			var combat_sys = main.get("combat_system")
			if is_instance_valid(combat_sys) and combat_sys.has_method("on_hit"):
				combat_sys.on_hit(
					self,
					body,
					attack_damage,
					body.global_position
				)

# ------------------------------------------------
# DAMAGE
# ------------------------------------------------

func take_damage(amount: int, knockback_dir: int, force: float) -> void:
	if not is_instance_valid(self) or state == State.DEAD:
		return
	
	punch_hitbox.monitoring = false
	can_attack = false
	
	state = State.HIT
	health -= amount
	
	velocity.x = knockback_dir * force * 0.5  # Boss is heavier, less knockback
	sprite.play("hit")
	
	print("🔥 BOSS HIT! Health: ", health, "/", max_health)
	
	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(self):
		return
	velocity.x = 0
	
	if health <= 0:
		die()
		return
	
	state = State.IDLE
	sprite.play("boss_idle")
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	can_attack = true


# ------------------------------------------------
# DEATH
# ------------------------------------------------

func die() -> void:
	state = State.DEAD
	punch_hitbox.monitoring = false
	attack_range.monitoring = false
	sprite.play("death")
	print("💀 BOSS DEFEATED!")
	await sprite.animation_finished
	if is_instance_valid(self):
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
