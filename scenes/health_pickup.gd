# health_pickup.gd - Health restoration pickup
extends Area2D

@export var heal_amount := 50  # Amount of health restored
@export var pickup_sound: AudioStream  # Optional pickup sound

var is_collected := false
var bob_tween: Tween

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true
	
	# Add visual feedback (bobbing animation)
	start_bobbing()

func start_bobbing():
	bob_tween = create_tween()
	bob_tween.set_loops()
	var start_y = position.y
	bob_tween.tween_property(self, "position:y", start_y - 10, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(self, "position:y", start_y + 10, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D):
	if is_collected:
		return
		
	# Check if it's the player
	if body.is_in_group("player"):
		is_collected = true
		
		# Stop bobbing animation
		if bob_tween:
			bob_tween.kill()
		
		# Heal the player
		if body.health < body.max_health:
			body.health = min(body.health + heal_amount, body.max_health)
			
			# Update health bar if it exists
			if body.has_node("HealthBar"):
				body.get_node("HealthBar").value = body.health
			
			# Emit signal if available
			if body.has_signal("health_changed"):
				body.emit_signal("health_changed", body.health, body.max_health)
			
			print("💊 Health restored! +", heal_amount, " HP")
		
		# Disable collision
		monitoring = false
		
		# Remove pickup immediately (no fade to avoid tween issues)
		queue_free()
