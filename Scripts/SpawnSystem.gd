extends Node

signal wave_started(wave_number, enemy_count)
signal wave_completed(wave_number)
signal boss_spawned
signal game_won

# Enemy scene
var enemy_scene = preload("res://scenes/enemy.tscn")
var health_pickup_scene = preload("res://scenes/health_pickup.tscn")
var boss_scene = preload("res://scenes/boss.tscn")

# Wave configuration
var max_waves: int = 5  # Default, can be set dynamically
const BASE_ENEMIES_PER_WAVE = 3
const WAVE_DELAY = 3.0
const ENEMY_SPAWN_INTERVAL = 1.0

# Wave state
var current_wave: int = 0
var enemies_alive: int = 0
var total_enemies_killed: int = 0
var wave_active: bool = false
var boss_spawned_flag: bool = false
var paused: bool = false   # <-- pause flag

# References
var scene_root: Node = null
var spawn_positions: Array = []

func _ready():
	add_to_group("pausable")   # HUD can now pause/resume this system

func _init(scene):
	scene_root = scene

# Called by HUD pause menu
func _set_paused_state(state: bool) -> void:
	paused = state

# Set spawn positions (call this from main scene)
func set_spawn_positions(positions: Array):
	spawn_positions = positions

# Set maximum waves (call this before starting wave mode)
func set_max_waves(waves: int):
	max_waves = waves
	print("🎮 Max waves set to: ", max_waves)

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
	
	# Boss wave check
	if current_wave > max_waves and not boss_spawned_flag:
		spawn_boss()
		return
	
	var enemy_count = get_enemies_for_wave(current_wave)
	wave_active = true
	
	emit_signal("wave_started", current_wave, enemy_count)
	print("🌊 Wave ", current_wave, " starting with ", enemy_count, " enemies")
	
	# Run spawn loop
	_spawn_loop(enemy_count)

# Pause-aware spawn loop
func _spawn_loop(enemy_count: int) -> void:
	for i in range(enemy_count):
		# Freeze while paused
		while paused:
			await get_tree().process_frame
		
		# Timer that halts when paused
		var timer = scene_root.get_tree().create_timer(ENEMY_SPAWN_INTERVAL, false)
		await timer.timeout
		
		# Double-check pause before spawning
		while paused:
			await get_tree().process_frame
		
		spawn_enemy()

# Calculate enemies for wave
func get_enemies_for_wave(wave: int) -> int:
	return BASE_ENEMIES_PER_WAVE + int(wave / 2)

# Spawn single enemy
func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var spawn_pos = get_random_spawn_position()
	enemy.global_position = spawn_pos
	
	scene_root.add_child(enemy)
	enemies_alive += 1
	
	if not enemy.is_connected("tree_exited", _on_enemy_died):
		enemy.tree_exited.connect(_on_enemy_died)
	
	print("👹 Enemy spawned at ", spawn_pos)
	return enemy

# Get random spawn position
func get_random_spawn_position() -> Vector2:
	if spawn_positions.size() > 0:
		return spawn_positions[randi() % spawn_positions.size()]
	else:
		var x = randf_range(100, 700)
		return Vector2(x, 270)

# Called when enemy dies
func _on_enemy_died():
	enemies_alive -= 1
	total_enemies_killed += 1
	
	print("💀 Enemy killed! Alive: ", enemies_alive, " | Total killed: ", total_enemies_killed)
	
	if enemies_alive == 0 and wave_active:
		on_wave_complete()

# Wave completed
func on_wave_complete():
	wave_active = false
	emit_signal("wave_completed", current_wave)
	print("✅ Wave ", current_wave, " complete!")
	
	# Spawn health pickup as reward
	spawn_health_pickup()
	_delayed_next_wave()

# Pause-aware delay before next wave
func _delayed_next_wave() -> void:
	while paused:
		await get_tree().process_frame
	
	var timer = scene_root.get_tree().create_timer(WAVE_DELAY, false)
	await timer.timeout
	
	while paused:
		await get_tree().process_frame
	
	start_next_wave()

# Spawn boss
func spawn_boss():
	boss_spawned_flag = true
	emit_signal("boss_spawned")
	print("🔥 BOSS WAVE!")
	
	# Spawn boss at center or random spawn position
	var boss = boss_scene.instantiate()
	var spawn_pos = get_random_spawn_position()
	boss.global_position = spawn_pos
	
	scene_root.add_child(boss)
	enemies_alive += 1
	
	# Connect death signal
	if not boss.is_connected("tree_exited", _on_boss_died):
		boss.tree_exited.connect(_on_boss_died)
	
	print("🔥 BOSS SPAWNED at ", spawn_pos, "!")

# Called when boss dies
func _on_boss_died():
	enemies_alive -= 1
	emit_signal("game_won")
	print("🏆 BOSS DEFEATED! YOU WIN!")

# Get wave info (for UI)
func get_wave_info() -> Dictionary:
	return {
		"current_wave": current_wave,
		"max_waves": max_waves,
		"enemies_alive": enemies_alive,
		"total_killed": total_enemies_killed,
		"is_boss_wave": current_wave > max_waves
	}

# Spawn health pickup after wave
func spawn_health_pickup():
	var health_pickup = health_pickup_scene.instantiate()
	
	# Spawn at center of arena, on ground
	var player = scene_root.get_node_or_null("player")
	if player:
		health_pickup.global_position = Vector2(player.global_position.x, 1005)
	else:
		health_pickup.global_position = Vector2(5300, 1005)
	
	scene_root.add_child(health_pickup)
	print("💊 Health pickup spawned!")

# Reset system
func reset():
	current_wave = 0
	enemies_alive = 0
	total_enemies_killed = 0
	wave_active = false
	boss_spawned_flag = false
