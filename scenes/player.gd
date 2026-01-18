extends CharacterBody2D

# -------------------- CONFIG --------------------
@export var speed := 300.0
@export var max_health := 100
@export var punch_damage := 20
@export var kick_damage := 30
@export var ground_y := 270.0

# -------------------- STATE --------------------
enum State { IDLE, MOVE, ATTACK, HIT, DEAD }
var state: State = State.IDLE

var health := 0

# -------------------- NODES --------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_hitbox: Area2D = $punchhitbox
@onready var kick_hitbox: Area2D = $kickhitbox
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var camera := get_viewport().get_camera_2d()

# ------------------------------------------------

func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

	punch_hitbox.monitoring = false
	kick_hitbox.monitoring = false

	sprite.play("idle")

# ------------------------------------------------

func _physics_process(_delta: float) -> void:
	if state in [State.DEAD, State.HIT, State.ATTACK]:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	global_position.y = ground_y

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
		var dir := -1 if sprite.flip_h else 1
		body.take_damage(punch_damage, dir, 200)
		camera.shake(5)

func _on_kickhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return
	if body.is_in_group("enemy"):
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
