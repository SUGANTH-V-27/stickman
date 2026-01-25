extends CharacterBody2D

# -------------------- CONFIG --------------------
@export var speed := 120.0  # Base move speed
@export var max_health := 450  # Tankier boss
@export var attack_damage := 45  # Base damage
@export var attack_cooldown := 0.85  # Base cooldown
@export var gravity := 2000.0

# Attack timing (seconds)
@export var attack_windup := 0.18
@export var hitbox_active_time := 0.22
@export var lunge_speed := 240.0

# Hit reaction tuning
@export var hit_stun_time := 0.12
@export var min_hit_interval := 0.18  # prevents stunlock

# Enrage phase
@export var enrage_threshold := 0.5  # < 50% HP
@export var enrage_speed_multiplier := 1.35
@export var enrage_cooldown_multiplier := 0.65
@export var enrage_damage_bonus := 10

# -------------------- STATE --------------------
enum State { IDLE, MOVE, ATTACK, HIT, DEAD }
var state: State = State.IDLE

var health := 0
var player: CharacterBody2D
var can_attack := true
var _last_hit_ms := 0
var _enraged := false

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


func _is_enraged() -> bool:
	return float(health) <= float(max_health) * enrage_threshold


func _current_speed() -> float:
	return speed * (enrage_speed_multiplier if _is_enraged() else 1.0)


func _current_damage() -> int:
	return attack_damage + (enrage_damage_bonus if _is_enraged() else 0)


func _current_cooldown() -> float:
	return attack_cooldown * (enrage_cooldown_multiplier if _is_enraged() else 1.0)

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
		# Attack movement handled inside attack()
		move_and_slide()
		return
	
	sprite.flip_h = player.global_position.x < global_position.x
	
	# Phase swap message (one-time)
	if _is_enraged() and not _enraged:
		_enraged = true
		print("😡 BOSS ENRAGED!")

	if not attack_range.has_overlapping_bodies():
		state = State.MOVE
		var move_speed := _current_speed()
		velocity.x = -move_speed if sprite.flip_h else move_speed
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
	
	# Enable hitbox mid-animation (impact frame)
	await get_tree().create_timer(attack_windup).timeout  # Faster windup
	if not is_instance_valid(self):
		return

	# Lunge forward for pressure
	var dir := -1 if sprite.flip_h else 1
	velocity.x = dir * lunge_speed
	punch_hitbox.monitoring = true

	await get_tree().create_timer(hitbox_active_time).timeout
	if not is_instance_valid(self):
		return
	punch_hitbox.monitoring = false
	velocity.x = 0

	# Wait for animation to complete
	await sprite.animation_finished
	if not is_instance_valid(self):
		return
	state = State.IDLE

	await get_tree().create_timer(_current_cooldown()).timeout
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
		body.take_damage(_current_damage(), dir, 320)
		
		# Show damage effects - with safety checks
		var main = get_tree().current_scene
		if is_instance_valid(main) and main.has_method("get"):
			var combat_sys = main.get("combat_system")
			if is_instance_valid(combat_sys) and combat_sys.has_method("on_hit"):
				combat_sys.on_hit(
					self,
					body,
					_current_damage(),
					body.global_position
				)

# ------------------------------------------------
# DAMAGE
# ------------------------------------------------

func take_damage(amount: int, knockback_dir: int, force: float) -> void:
	if not is_instance_valid(self) or state == State.DEAD:
		return

	# Anti-stunlock: ignore ultra-rapid hits
	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_hit_ms < int(min_hit_interval * 1000.0):
		return
	_last_hit_ms = now_ms
	
	punch_hitbox.monitoring = false
	can_attack = false
	
	state = State.HIT
	health -= amount
	
	velocity.x = knockback_dir * force * 0.5  # Boss is heavier, less knockback
	sprite.play("hit")
	
	print("🔥 BOSS HIT! Health: ", health, "/", max_health)
	
	await get_tree().create_timer(hit_stun_time).timeout
	if not is_instance_valid(self):
		return
	velocity.x = 0
	
	if health <= 0:
		die()
		return
	
	state = State.IDLE
	sprite.play("boss_idle")
	await get_tree().create_timer(_current_cooldown()).timeout
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
	# Notify main scene of victory
	var main = get_tree().current_scene
	if is_instance_valid(main) and main.has_method("show_victory"):
		main.show_victory()
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
