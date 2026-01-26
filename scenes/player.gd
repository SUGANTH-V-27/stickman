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
@onready var air_sfx: AudioStreamPlayer = $AudioStreamPlayer/air_sfx
@onready var hit_sfx: AudioStreamPlayer = $AudioStreamPlayer/hit_sfx
@onready var walk_sfx: AudioStreamPlayer = $AudioStreamPlayer/walk_sfx

# -------------------- INPUT STATE --------------------
# Shared flags for keyboard + mobile buttons
var input_states := {
	"ui_left": false,
	"ui_right": false,
	"jump": false,
	"attack": false,
	"kick": false
}

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

	punch_hitbox.monitoring = false
	kick_hitbox.monitoring = false
	sprite.play("idle")

# ------------------------------------------------
# KEYBOARD INPUT
# ------------------------------------------------
func _input(event) -> void:
	if event.is_action_pressed("attack"): input_states["attack"] = true
	if event.is_action_released("attack"): input_states["attack"] = false

	if event.is_action_pressed("kick"): input_states["kick"] = true
	if event.is_action_released("kick"): input_states["kick"] = false

	if event.is_action_pressed("jump"): input_states["jump"] = true
	if event.is_action_released("jump"): input_states["jump"] = false

	if event.is_action_pressed("ui_left"): input_states["ui_left"] = true
	if event.is_action_released("ui_left"): input_states["ui_left"] = false

	if event.is_action_pressed("ui_right"): input_states["ui_right"] = true
	if event.is_action_released("ui_right"): input_states["ui_right"] = false

# ------------------------------------------------
# MAIN LOOP
# ------------------------------------------------
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y > 0:
		velocity.y = 0

	# Jump
	if input_states["jump"] and is_on_floor():
		velocity.y = -jump_force
		input_states["jump"] = false
		state = State.MOVE
		sprite.play("jump")

	# Restrict movement when hit/dead
	if state in [State.DEAD, State.HIT]:
		velocity.x = 0
		move_and_slide()
		return

	# Movement
	var dir := 0
	if input_states["ui_left"]: dir -= 1
	if input_states["ui_right"]: dir += 1
	velocity.x = dir * speed
	move_and_slide()

	# Animations
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

	# Attacks (can overlap with movement/jump)
	if input_states["attack"] and state not in [State.DEAD, State.HIT]:
		punch()
		input_states["attack"] = false
	if input_states["kick"] and state not in [State.DEAD, State.HIT]:
		kick()
		input_states["kick"] = false

# ------------------------------------------------
# ATTACKS
# ------------------------------------------------
func _do_attack(hitbox: Area2D, anim: String, active_time: float, cooldown: float) -> void:
	state = State.ATTACK
	sprite.play(anim)
	air_sfx.play()

	await get_tree().create_timer(0.08).timeout
	hitbox.monitoring = true

	await get_tree().create_timer(active_time).timeout
	hitbox.monitoring = false

	await get_tree().create_timer(cooldown).timeout
	if not is_dying and state == State.ATTACK:
		state = State.IDLE
		sprite.play("idle")

func punch() -> void:
	_do_attack(punch_hitbox, "punch", 0.05, 0.25)

func kick() -> void:
	_do_attack(kick_hitbox, "kick", 0.08, 0.25)

func jump() -> void:
	if is_on_floor():
		velocity.y = -jump_force
		state = State.MOVE
		sprite.play("jump")

# ------------------------------------------------
# HITBOX SIGNALS
# ------------------------------------------------
func _on_punchhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK: return
	if body.is_in_group("enemy"):
		hit_sfx.play()
		var dir := -1 if sprite.flip_h else 1
		var damage = aerial_punch_damage if not is_on_floor() else punch_damage
		var knockback = 350 if not is_on_floor() else 200
		body.take_damage(damage, dir, knockback)

func _on_kickhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK: return
	if body.is_in_group("enemy"):
		hit_sfx.play()
		var dir := -1 if sprite.flip_h else 1
		body.take_damage(kick_damage, dir, 450)

# ------------------------------------------------
# DAMAGE
# ------------------------------------------------
func take_damage(amount: int, knockback_dir: int, force: float) -> void:
	if state == State.DEAD or is_dying: return

	health = max(health - amount, 0)
	if health_bar: health_bar.value = health
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
	if not _hit_recovering: return
	await get_tree().create_timer(0.25).timeout
	if not is_instance_valid(self) or state == State.DEAD or is_dying: return
	_hit_recovering = false
	state = State.IDLE
	sprite.play("idle")

func die() -> void:
	if state == State.DEAD or is_dying: return
	health = 0
	if health_bar: health_bar.value = health
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
func _on_AttackButton_pressed(): input_states["attack"] = true
func _on_KickButton_pressed(): input_states["kick"] = true
func _on_JumpButton_pressed(): input_states["jump"] = true

func _on_LeftButton_pressed(): input_states["ui_left"] = true
func _on_LeftButton_released(): input_states["ui_left"] = true

func _on_RightButton_pressed(): input_states["ui_left"] = true
func _on_RightButton_released(): input_states["ui_left"] = true
