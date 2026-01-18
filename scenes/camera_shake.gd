extends Camera2D

@export var shake_decay := 5.0   # lower = longer shake duration
var shake_strength := 0.0
var shake_offset := Vector2.ZERO

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		# decay shake strength gradually
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)

		# pick a random offset within current strength
		var target_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

		# smooth interpolation toward target offset
		shake_offset = shake_offset.lerp(target_offset, 0.5)
	else:
		shake_offset = Vector2.ZERO

	# apply shake visually
	offset = shake_offset

func shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)
