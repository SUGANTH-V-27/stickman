extends Camera2D

@export var shake_decay := 10.0
var shake_strength := 0.0

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		offset = Vector2.ZERO

func shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)
