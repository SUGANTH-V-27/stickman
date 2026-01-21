

extends CharacterBody2D

# -------------------- CONFIG --------------------
@export var speed := 300.0
@export var max_health := 100
@export var punch_damage := 20
@export var kick_damage := 30
@export var gravity := 2000.0

# -------------------- STATE --------------------
enum State { IDLE, MOVE, ATTACK, HIT, DEAD }
var state: State = State.IDLE
var health := 0

# -------------------- NODES --------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_hitbox: Area2D = $punchhitbox
@onready var kick_hitbox: Area2D = $kickhitbox
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var camera: Camera2D = $Camera2D
@onready var air_sfx: AudioStreamPlayer = $AudioStreamPlayer/air_sfx
@onready var hit_sfx: AudioStreamPlayer = $AudioStreamPlayer/hit_sfx
@onready var walk_sfx: AudioStreamPlayer = $AudioStreamPlayer/walk_sfx

const CAMERA_Y := 540.0

# ------------------------------------------------

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

	punch_hitbox.monitoring = false
	kick_hitbox.monitoring = false

	sprite.play("idle")

# ------------------------------------------------

func _physics_process(delta: float) -> void:
	# ---- gravity & floor ----
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# ---- locked states ----
	if state in [State.DEAD, State.HIT, State.ATTACK]:
		velocity.x = 0
		move_and_slide()
		return

	# ---- movement ----
	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	move_and_slide()

	if dir == 0:
		state = State.IDLE
		sprite.play("idle")
	else:
		state = State.MOVE
		sprite.flip_h = dir < 0
		sprite.play("walk")

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

	await sprite.animation_finished
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

	await sprite.animation_finished
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
		body.take_damage(punch_damage, dir, 200)
		camera.shake(5)

func _on_kickhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return
	if body.is_in_group("enemy"):
		hit_sfx.play()
		var dir := -1 if sprite.flip_h else 1
		body.take_damage(kick_damage, dir, 450)
		camera.shake(10)

# ------------------------------------------------
# DAMAGE
# ------------------------------------------------

func take_damage(amount: int, knockback_dir: int, force: float) -> void:
	if state == State.DEAD:
		return

	state = State.HIT
	health -= amount
	health_bar.value = health

	velocity.x = knockback_dir * force
	move_and_slide()

	if health <= 0:
		die()
		return

	sprite.play("hit")
	await sprite.animation_finished
	state = State.IDLE
	sprite.play("idle")

func die() -> void:
	state = State.DEAD
	sprite.play("death")
	await sprite.animation_finished
	queue_free()


# ------------------------------------------------
# PAUSE SUPPORT
# ------------------------------------------------

func _set_paused_state(paused: bool) -> void:
	set_process(!paused)
	set_physics_process(!paused)
	set_process_input(!paused)

	
func _on_AttackButton_pressed() -> void:
	if state not in [State.DEAD, State.HIT, State.ATTACK]:
		punch()

func _on_KickButton_pressed() -> void:
	if state not in [State.DEAD, State.HIT, State.ATTACK]:
		kick()
