# SpawnSystem.gd - Handles enemy waves and boss spawning
extends Node

signal wave_started(wave_number, enemy_count)
signal wave_completed(wave_number)
signal boss_spawned
signal game_won

# Enemy scene
var enemy_scene = preload("res://scenes/enemy.tscn")
# var boss_scene = preload("res://scenes/boss.tscn")  # Uncomment when you have boss

# Wave configuration
const MAX_WAVES = 10
const BASE_ENEMIES_PER_WAVE = 3
const WAVE_DELAY = 3.0
const ENEMY_SPAWN_INTERVAL = 1.0

# Wave state
var current_wave = 0
var enemies_alive = 0
var total_enemies_killed = 0
var wave_active = false
var boss_spawned_flag = false

# References
var scene_root: Node = null
var spawn_positions = []

func _init(scene):
	scene_root = scene

# Set spawn positions (call this from main scene)
func set_spawn_positions(positions: Array):
	spawn_positions = positions

# Start wave-based gameplay
func start_wave_mode():
	current_wave = 0
	enemies_alive = 0
	total_enemies_killed = 0
	boss_spawned_flag = false
	start_next_wave()

# Start next wave
func start_next_wave():
	current_wave += 1
	
	# Check if boss wave
	if current_wave > MAX_WAVES and not boss_spawned_flag:
		spawn_boss()
		return
	
	var enemy_count = get_enemies_for_wave(current_wave)
	wave_active = true
	
	emit_signal("wave_started", current_wave, enemy_count)
	print("🌊 Wave ", current_wave, " starting with ", enemy_count, " enemies")
	
	# Spawn enemies with delay
	for i in range(enemy_count):
		await scene_root.get_tree().create_timer(ENEMY_SPAWN_INTERVAL).timeout
		spawn_enemy()

# Calculate enemies for wave (scales with difficulty)
func get_enemies_for_wave(wave: int) -> int:
	return BASE_ENEMIES_PER_WAVE + int(wave / 2)

# Spawn single enemy
func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	
	# Get random spawn position
	var spawn_pos = get_random_spawn_position()
	enemy.global_position = spawn_pos
	
	scene_root.add_child(enemy)
	enemies_alive += 1
	
	# Connect death signal
	if not enemy.is_connected("tree_exited", _on_enemy_died):
		enemy.tree_exited.connect(_on_enemy_died)
	
	print("👹 Enemy spawned at ", spawn_pos)
	return enemy

# Get random spawn position
func get_random_spawn_position() -> Vector2:
	if spawn_positions.size() > 0:
		return spawn_positions[randi() % spawn_positions.size()]
	else:
		# Default spawn positions
		var x = randf_range(100, 700)
		return Vector2(x, 270)

# Called when enemy dies
func _on_enemy_died():
	enemies_alive -= 1
	total_enemies_killed += 1
	
	print("💀 Enemy killed! Alive: ", enemies_alive, " | Total killed: ", total_enemies_killed)
	
	# Check if wave complete
	if enemies_alive == 0 and wave_active:
		on_wave_complete()

# Wave completed
func on_wave_complete():
	wave_active = false
	emit_signal("wave_completed", current_wave)
 
	print("✅ Wave ", current_wave, " complete!")

	# Delay before next wave
	scene_root.get_tree().create_timer(WAVE_DELAY).timeout.connect(start_next_wave)


# Spawn boss
func spawn_boss():
	boss_spawned_flag = true
	emit_signal("boss_spawned")
	
	print("🔥 BOSS WAVE!")
	
	# TODO: Spawn boss when you create boss scene
	# var boss = boss_scene.instantiate()
	# boss.global_position = Vector2(600, 270)
	# scene_root.add_child(boss)
	# enemies_alive += 1
	# boss.tree_exited.connect(_on_boss_died)

# Called when boss dies
func _on_boss_died():
	enemies_alive -= 1
	emit_signal("game_won")
	print("🏆 BOSS DEFEATED! YOU WIN!")

# Get wave info (for UI)
func get_wave_info() -> Dictionary:
	return {
		"current_wave": current_wave,
		"max_waves": MAX_WAVES,
		"enemies_alive": enemies_alive,
		"total_killed": total_enemies_killed,
		"is_boss_wave": current_wave > MAX_WAVES
	}

# Reset system
func reset():
	current_wave = 0
	enemies_alive = 0
	total_enemies_killed = 0
	wave_active = false
	boss_spawned_flag = false
