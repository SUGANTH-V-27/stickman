extends CharacterBody2D

@export var speed: float = 300.0
@export var max_health: int = 100
@export var knockback_force: float = 200.0
@export var punch_damage: int = 20
@export var kick_damage: int = 30

var health: int
var attacking := false
var hit := false
var dead := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_hitbox: Area2D = $punchhitbox
@onready var kick_hitbox: Area2D = $kickhitbox
@onready var health_bar: TextureProgressBar = $HealthBar

func _ready() -> void:
	health = max_health

	# hitboxes
	punch_hitbox.monitoring = true
	kick_hitbox.monitoring = false

	# health bar
	health_bar.max_value = max_health
	health_bar.value = health

	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if dead:
		return

	if hit or attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	velocity.y = 0
	move_and_slide()

	if dir == 0:
		sprite.play("idle")
	else:
		sprite.flip_h = dir < 0

		# flip hitboxes
		punch_hitbox.position.x = -abs(punch_hitbox.position.x) if dir < 0 else abs(punch_hitbox.position.x)
		kick_hitbox.position.x = -abs(kick_hitbox.position.x) if dir < 0 else abs(kick_hitbox.position.x)

		sprite.play("walk")

func _input(event) -> void:
	if dead or hit or attacking:
		return

	if event.is_action_pressed("attack"):
		punch()

	if event.is_action_pressed("kick"):
		kick()

# --------------------
# PUNCH
# --------------------
func punch() -> void:
	attacking = true
	velocity = Vector2.ZERO

	sprite.play("punch")

	await get_tree().physics_frame

	for body in punch_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			var dir := -1 if sprite.flip_h else 1
			body.take_damage(punch_damage, dir)

	await sprite.animation_finished
	attacking = false

# --------------------
# KICK (FIXED)
# --------------------
func kick() -> void:
	attacking = true
	velocity = Vector2.ZERO

	# 🔥 disable punch during kick
	punch_hitbox.monitoring = false
	kick_hitbox.monitoring = true

	sprite.play("kick")

	await get_tree().physics_frame

	for body in kick_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			var dir := -1 if sprite.flip_h else 1
			body.take_damage(kick_damage, dir)

	await sprite.animation_finished

	kick_hitbox.monitoring = false
	punch_hitbox.monitoring = true
	attacking = false

# --------------------
# DAMAGE / DEATH
# --------------------
func take_damage(amount: int, knockback_dir: int) -> void:
	if dead:
		return

	hit = true
	health -= amount
	health_bar.value = health

	velocity.x = knockback_dir * knockback_force
	move_and_slide()

	if health <= 0:
		die()
		return

	sprite.play("hit")
	await sprite.animation_finished

	hit = false
	sprite.play("idle")

func die() -> void:
	dead = true
	velocity = Vector2.ZERO

	sprite.play("death")
	await sprite.animation_finished
	queue_free()
