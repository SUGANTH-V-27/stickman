# CombatSystem.gd - Handles combat visual effects and combo tracking
extends Node

# Combat configuration
const COMBO_WINDOW = 2.0  # seconds to maintain combo
const DAMAGE_NUMBER_DURATION = 0.8
const SCREEN_SHAKE_INTENSITY = 5.0

# References
var scene_root: Node = null
var camera: Camera2D = null

# Combo tracking
var combo_counts = {}  # Dictionary to track combos per entity
var combo_timers = {}

func _init(scene):
	scene_root = scene

func set_camera(cam: Camera2D):
	camera = cam

# ==================== VISUAL EFFECTS ====================

# Show floating damage number
func show_damage_number(position: Vector2, damage: int):
	var label = Label.new()
	label.text = "-" + str(damage)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 50

	
	label.global_position = position - Vector2(0, 30)
	scene_root.add_child(label)
	
	# Animate upward and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, DAMAGE_NUMBER_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, DAMAGE_NUMBER_DURATION)
	
	await tween.finished
	label.queue_free()

# Screen shake effect
func shake_camera(duration: float, intensity: float):
	if camera == null:
		return
	
	var original_offset = camera.offset
	var elapsed = 0.0
	
	while elapsed < duration: 
		camera.offset = original_offset + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		elapsed += get_process_delta_time()
		await scene_root.get_tree().process_frame
	
	camera.offset = original_offset

# Flash sprite red (enhanced hit feedback)
func flash_damage(sprite: AnimatedSprite2D, flash_count: int = 3):
	if sprite == null:
		return
	
	var original_modulate = sprite.modulate
	
	for i in range(flash_count):
		sprite.modulate = Color.RED
		await scene_root.get_tree().create_timer(0.05).timeout 
		sprite.modulate = original_modulate
		await scene_root.get_tree().create_timer(0.05).timeout

# ==================== COMBO SYSTEM ====================

# Update combo for attacker
func update_combo(attacker: Node):
	var attacker_id = attacker.get_instance_id()
	
	# Check if combo timer exists
	if combo_timers.has(attacker_id):
		var time_since_last = Time.get_ticks_msec() - combo_timers[attacker_id]
		
		if time_since_last < COMBO_WINDOW * 1000:
			# Continue combo
			combo_counts[attacker_id] = combo_counts.get(attacker_id, 0) + 1
		else:
			# Reset combo
			combo_counts[attacker_id] = 1
	else:
		# First hit
		combo_counts[attacker_id] = 1
	
	combo_timers[attacker_id] = Time.get_ticks_msec()
	
	return combo_counts[attacker_id]

# Get current combo count
func get_combo(attacker: Node) -> int:
	return combo_counts.get(attacker.get_instance_id(), 0)

# Reset combo
func reset_combo(attacker: Node):
	var attacker_id = attacker.get_instance_id()
	combo_counts.erase(attacker_id)
	combo_timers.erase(attacker_id)

# Show combo text
func show_combo_text(position: Vector2, combo: int):
	if combo < 2:
		return
	
	var label = Label.new()
	label.text = str(combo) + "x COMBO!"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 50

	
	label.global_position = position - Vector2(0, 60)
	scene_root.add_child(label)
	
	# Animate with scale
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.8)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	
	await tween.finished
	label.queue_free()

# Create blood particles on hit
func create_blood_particles(position: Vector2, direction: int = 1):
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(0.8, 0.1, 0.1, 1.0)  # Dark red blood
		particle.global_position = position
		scene_root.add_child(particle)
		
		var angle = randf_range(-PI/3, PI/3) + (0 if direction > 0 else PI)
		var distance = randf_range(20, 50)
		var target = position + Vector2(cos(angle), sin(angle)) * distance
		
		var tween = create_tween()
		var fall_distance = randf_range(30, 60)
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", target + Vector2(0, fall_distance), 0.6)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6)
		
		await tween.finished
		particle.queue_free()

# Create combo particles
func create_combo_particles(position: Vector2, combo: int):
	
	
	if combo < 3:
		return
	
	var colors = [Color.YELLOW, Color.ORANGE, Color.RED]
	var color = colors[min(int(combo / 2), 2)]
	
	
	for i in range(combo * 2):
		var particle = ColorRect.new()
		particle.size = Vector2(6, 6)
		particle.color = color
		particle.global_position = position
		scene_root.add_child(particle)
		
		var angle = randf() * TAU
		var distance = randf_range(30, 80)
		var target = position + Vector2(cos(angle), sin(angle)) * distance
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", target, 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		
		await tween.finished
		particle.queue_free()

# ==================== ENHANCED HIT HANDLER ====================

# Call this when damage is dealt
func on_hit(attacker: Node, target: Node, damage: int, position: Vector2):
	# Update combo
	var combo = update_combo(attacker)
	
	# Show damage number
	show_damage_number(position, damage)
	
	# Blood particles effect
	var direction = 1 if attacker.global_position.x < target.global_position.x else -1
	create_blood_particles(position, direction)
	
	# Flash target red
	if target.has_node("Sprite") or target.has_node("AnimatedSprite2D"):
		var sprite = target.get_node("AnimatedSprite2D") if target.has_node("AnimatedSprite2D") else target.get_node("Sprite")
		flash_damage(sprite)
	
	# Combo effects
	if combo >= 2:
		show_combo_text(position, combo)
	
	if combo >= 3:
		create_combo_particles(position, combo)
		shake_camera(0.15, SCREEN_SHAKE_INTENSITY * (combo * 0.5))
	else:
		shake_camera(0.1, SCREEN_SHAKE_INTENSITY)
