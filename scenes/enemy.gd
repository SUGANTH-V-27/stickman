extends CharacterBody2D

@export var ground_y: float = 270.0
@export var speed: float = 120.0
@export var max_health: int = 100
@export var knockback_force: float = 300.0
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.5

var health: int
var player: CharacterBody2D = null
var can_attack := true

enum State { IDLE, MOVE, ATTACK, HIT, DEAD }
var state: State = State.IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range: Area2D = $attack_range
@onready var punch_hitbox: Area2D = $punchhitbox

# -------------------------------------------------

func _ready() -> void:
	health = max_health
	global_position.y = ground_y

	sprite.play("idle")

	attack_range.monitoring = true
	punch_hitbox.monitoring = false

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

# -------------------------------------------------
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	# 🔒 DO NOT override velocity during HIT
	if state == State.HIT:
		move_and_slide()
		return

	# lock enemy to ground line
	global_position.y = ground_y

	# stop completely during attack animation
	if state == State.ATTACK:
		velocity.x = 0
		move_and_slide()
		return

	# face player
	sprite.flip_h = player.global_position.x < global_position.x

	# MOVE until player enters attack_range
	if not attack_range.has_overlapping_bodies():
		state = State.MOVE
		velocity.x = -speed if sprite.flip_h else speed
		move_and_slide()

		if sprite.animation != "walk":
			sprite.play("walk")
		return

	# PLAYER IN RANGE → STOP & ATTACK
	state = State.IDLE
	velocity.x = 0
	move_and_slide()

	if sprite.animation != "idle":
		sprite.play("idle")

	if can_attack:
		attack()

# -------------------------------------------------
# ATTACK PLAYER
# -------------------------------------------------

func attack() -> void:
	state = State.ATTACK
	can_attack = false

	sprite.play("punch")
	punch_hitbox.monitoring = true

	await sprite.animation_finished

	punch_hitbox.monitoring = false
	state = State.IDLE

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_punchhitbox_body_entered(body: Node) -> void:
	if state != State.ATTACK:
		return

	if body.is_in_group("player"):
		var dir := -1 if sprite.flip_h else 1
		body.take_damage(attack_damage, dir,200)

# -------------------------------------------------
# TAKE DAMAGE FROM PLAYER (PUNCH / KICK)
# -------------------------------------------------

func take_damage(amount: int, knockback_dir: int, force: float) -> void:
	if state == State.DEAD or state == State.HIT:
		return

	state = State.HIT
	health -= amount

	# APPLY KNOCKBACK
	velocity.x = knockback_dir * force

	sprite.play("hit")

	# ⏱ allow knockback to actually move
	await get_tree().create_timer(0.15).timeout

	# STOP AFTER KNOCKBACK
	velocity.x = 0

	if health <= 0:
		die()
		return

	await sprite.animation_finished
	state = State.IDLE
	sprite.play("idle")

# -------------------------------------------------
# DEATH
# -------------------------------------------------

func die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO

	sprite.play("death")
	await sprite.animation_finished
	queue_free()
