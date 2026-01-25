

extends CharacterBody2D

# -------------------- CONFIG --------------------
@export var speed := 300.0
@export var jump_force := 600.0
@export var max_health := 100
@export var punch_damage := 20
@export var kick_damage := 30
@export var aerial_punch_damage := 35  # Jump + Punch combo
@export var gravity := 2000.0

# -------------------- STATE --------------------
enum State { IDLE, MOVE, ATTACK, HIT, DEAD }
var state: State = State.IDLE
var health := 0
var is_dying := false
signal health_changed(current: int, max: int)

var _hit_recovering := false

# -------------------- NODES --------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_hitbox: Area2D = $punchhitbox
@onready var kick_hitbox: Area2D = $kickhitbox
@onready var health_bar: ProgressBar = $HealthBar

@onready var camera: Camera2D = $Camera2D
@onready var air_sfx: AudioStreamPlayer = $AudioStreamPlayer/air_sfx
@onready var hit_sfx: AudioStreamPlayer = $AudioStreamPlayer/hit_sfx
@onready var walk_sfx: AudioStreamPlayer = $AudioStreamPlayer/walk_sfx

const CAMERA_Y := 540.0

# ------------------------------------------------
func _ready() -> void:
	health = max_health
	z_index = 10
	add_to_group("player")
	state = State.IDLE
	is_dying = false
	_hit_recovering = false

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	set_process_mode(Node.PROCESS_MODE_INHERIT)

	punch_hitbox.monitoring = false
	kick_hitbox.monitoring = false

	sprite.play("idle") 

# ------------------------------------------------
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = -jump_force

	if state in [State.DEAD, State.HIT]:
		velocity.x = 0
		move_and_slide()
		return

	if state == State.ATTACK and is_on_floor():
		velocity.x = 0
		move_and_slide()
		return

	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	move_and_slide()

	if dir == 0 and is_on_floor() and state != State.ATTACK:
		state = State.IDLE
		sprite.play("idle")
	elif dir != 0 and is_on_floor() and state != State.ATTACK:
		state = State.MOVE
		sprite.flip_h = dir < 0
		sprite.play("walk")

	if dir != 0:
		punch_hitbox.position.x = abs(punch_hitbox.position.x) * sign(dir)
		kick_hitbox.position.x = abs(kick_hitbox.position.x) * sign(dir)
		if not walk_sfx.playing:
			walk_sfx.play()

# ------------------------------------------------
func _input(event) -> void:
	if state in [State.DEAD, State.HIT, State.ATTACK]:
		return

	if event.is_action_pressed("attack"):
		punch()
	elif event.is_action_pressed("kick"):
		kick()

# ------------------------------------------------
# ATTACKS
# ------------------------------------------------
func punch() -> void:
	state = State.ATTACK
	sprite.play("punch")
	air_sfx.play()

	await get_tree().create_timer(0.08).timeout
	punch_hitbox.monitoring = true

	await get_tree().create_timer(0.05).timeout
	punch_hitbox.monitoring = false

	await get_tree().create_timer(0.25).timeout
	state = State.IDLE
	sprite.play("idle")

func kick() -> void:
	state = State.ATTACK
	sprite.play("kick")
	air_sfx.play()

	await get_tree().create_timer(0.22).timeout
	kick_hitbox.monitoring = true

	await get_tree().create_timer(0.06).timeout
	kick_hitbox.monitoring = false

	await get_tree().create_timer(0.35).timeout
	state = State.IDLE
	sprite.play("idle")
	
	
   # ------------------------------------------------
# HITBOX SIGNALS
# ------------------------------------------------

func _on_punchhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return
	if body.is_in_group("enemy"):
		hit_sfx.play()
		var dir := -1 if sprite.flip_h else 1
		
		# Aerial punch combo - more damage!
		var damage = aerial_punch_damage if not is_on_floor() else punch_damage
		var knockback = 350 if not is_on_floor() else 200
		
		body.take_damage(damage, dir, knockback)

		var main = get_tree().current_scene
		if main and main.has_method("get") and main.get("combat_system"):
			main.combat_system.on_hit(
				self,
				body,
				damage,
				body.global_position
			)

		

func _on_kickhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return
	if body.is_in_group("enemy"):
		hit_sfx.play()
		var dir := -1 if sprite.flip_h else 1
		body.take_damage(kick_damage, dir, 450)

		var main = get_tree().current_scene
		if main and main.has_method("get") and main.get("combat_system"):
			main.combat_system.on_hit(
				self,
				body,
				kick_damage,
				body.global_position
			)

		

# ------------------------------------------------
# DAMAGE
# ------------------------------------------------
func take_damage(amount: int, knockback_dir: int, force: float) -> void:
	if state == State.DEAD or is_dying:
		return

	health = max(health - amount, 0)
	if health_bar:
		health_bar.value = health
	emit_signal("health_changed", health, max_health)

	if health <= 0:
		is_dying = true
		state = State.DEAD
		velocity = Vector2.ZERO
		punch_hitbox.monitoring = false
		kick_hitbox.monitoring = false
		sprite.play("death")

		var main = get_tree().current_scene
		if is_instance_valid(main) and main.has_method("show_game_over"):
			main.show_game_over()
		return

	if state != State.HIT:
		state = State.HIT
		_hit_recovering = true
		velocity.x = knockback_dir * force
		move_and_slide()
		sprite.play("hit")
		_call_hit_recover()
	else:
		velocity.x = knockback_dir * force * 0.2
		move_and_slide()

func _call_hit_recover() -> void:
	if not _hit_recovering:
		return
	await get_tree().create_timer(0.25).timeout
	if not is_instance_valid(self) or state == State.DEAD or is_dying:
		return
	_hit_recovering = false
	state = State.IDLE
	sprite.play("idle")

func die() -> void:
	if state == State.DEAD or is_dying:
		return
	health = 0
	if health_bar:
		health_bar.value = health
	take_damage(0, 0, 0)

# ------------------------------------------------
# PAUSE SUPPORT
# ------------------------------------------------
func _set_paused_state(paused: bool) -> void:
	set_process(!paused)
	set_physics_process(!paused)
	set_process_input(!paused)

# ------------------------------------------------
# MOBILE CONTROL HOOKS
# ------------------------------------------------
func _on_AttackButton_pressed() -> void:
	if state not in [State.DEAD, State.HIT, State.ATTACK]:
		punch()

func _on_KickButton_pressed() -> void:
	if state not in [State.DEAD, State.HIT, State.ATTACK]:
		kick()

func _on_JumpButton_pressed() -> void:
	if is_on_floor() and state not in [State.DEAD, State.HIT]:
		velocity.y = -jump_force

func _on_LeftButton_pressed() -> void:
	Input.action_press("ui_left")

func _on_LeftButton_released() -> void:
	Input.action_release("ui_left")

func _on_RightButton_pressed() -> void:
	Input.action_press("ui_right")

func _on_RightButton_released() -> void:
	Input.action_release("ui_right")
