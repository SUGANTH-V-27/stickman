extends CharacterBody2D

@export var speed: float = 300.0
@export var max_health: int = 100
@export var knockback_force: float = 200.0
@export var punch_damage: int = 20
@export var kick_damage: int = 30

var health: int

enum State { IDLE, MOVE, ATTACK, HIT, DEAD }
var state: State = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_hitbox: Area2D = $punchhitbox
@onready var kick_hitbox: Area2D = $kickhitbox
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var camera := get_viewport().get_camera_2d()

# -------------------------------------------------

func _ready() -> void:
	health = max_health

	punch_hitbox.monitoring = true
	kick_hitbox.monitoring = false

	health_bar.max_value = max_health
	health_bar.value = health

	sprite.play("idle")

# -------------------------------------------------

func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return

	if state in [State.HIT, State.ATTACK]:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	velocity.y = 0
	move_and_slide()

	if dir == 0:
		if state != State.IDLE:
			state = State.IDLE
			sprite.play("idle")
	else:
		state = State.MOVE
		sprite.flip_h = dir < 0

		punch_hitbox.position.x = -abs(punch_hitbox.position.x) if dir < 0 else abs(punch_hitbox.position.x)
		kick_hitbox.position.x = -abs(kick_hitbox.position.x) if dir < 0 else abs(kick_hitbox.position.x)

		if sprite.animation != "walk":
			sprite.play("walk")

# -------------------------------------------------

func _input(event) -> void:
	if state in [State.DEAD, State.HIT, State.ATTACK]:
		return

	if event.is_action_pressed("attack"):
		punch()

	if event.is_action_pressed("kick"):
		kick()

# -------------------------------------------------
# PUNCH
# -------------------------------------------------

func punch() -> void:
	state = State.ATTACK
	velocity = Vector2.ZERO

	sprite.play("punch")

	# impact frame
	await get_tree().create_timer(0.08, false, true).timeout

	for body in punch_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			var dir := -1 if sprite.flip_h else 1
			body.take_damage(punch_damage, dir, 200)
			camera.shake(5)

	await sprite.animation_finished
	state = State.IDLE
	sprite.play("idle")
# -------------------------------------------------
# KICK
# -------------------------------------------------

func kick() -> void:
	state = State.ATTACK
	velocity = Vector2.ZERO

	punch_hitbox.monitoring = false
	kick_hitbox.monitoring = false

	sprite.play("kick")

	# wait for impact frame
	await get_tree().create_timer(0.20, false, true).timeout

	kick_hitbox.monitoring = true

	for body in kick_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			var dir := -1 if sprite.flip_h else 1
			body.take_damage(kick_damage, dir, 450)
			camera.shake(10)

	await get_tree().create_timer(0.1, false, true).timeout

	kick_hitbox.monitoring = false
	punch_hitbox.monitoring = true

	await sprite.animation_finished
	state = State.IDLE
	sprite.play("idle")
# -------------------------------------------------
# DAMAGE / DEATH
# -------------------------------------------------

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
	velocity = Vector2.ZERO

	sprite.play("death")
	await sprite.animation_finished
	queue_free()


func _on_kickhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return

	if body.is_in_group("enemy"):
		var dir := -1 if sprite.flip_h else 1
		body.take_damage(kick_damage, dir,450)
		camera.shake(10)
