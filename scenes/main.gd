# main.gd - Main game scene
extends Node2D

# Systems
var combat_system
var spawn_system

# Node references
@onready var player = $player  # Your player node
@onready var enemy = $enemy    # Remove this - enemies will be spawned!
@onready var parallax_bg = $ParallaxBackground

@onready var health_bar: TextureProgressBar = $UI/HealthBar

func _ready():
	print("🎮 Main scene loaded!")

	# Health bar
	player.health = player.max_health
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_player_health_changed)

	# Remove static enemy
	if enemy:
		enemy.queue_free()

	# Initialize systems ONCE
	setup_combat_system()
	setup_spawn_system()

	await get_tree().create_timer(1.0).timeout
	spawn_system.start_wave_mode()

func _on_player_health_changed(current: int, max: int) -> void:
	health_bar.max_value = max
	health_bar.value = current
	
func _process(delta):
	health_bar.value = player.health
	
	# Handle parallax background scrolling
	if parallax_bg:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			var cam_pos = cam.get_screen_center_position()
			parallax_bg.scroll_offset = cam_pos
	
func setup_combat_system():
	# Load and initialize combat system
	var CombatSystemScript = preload("res://Scripts/CombatSystem.gd")

	combat_system = CombatSystemScript.new(self)
	combat_system.name = "CombatSystem"
	add_child(combat_system)
	
	# Set camera from player
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		combat_system.set_camera(camera)

	print("✅ Combat System initialized")


func setup_spawn_system():
	# Load and initialize spawn system
	var SpawnSystemScript = load("res://Scripts/SpawnSystem.gd")

	spawn_system = SpawnSystemScript.new(self) 
	add_child(spawn_system)
	# ✅ FIX: Set scene_root manually
	
	# Set spawn positions (adjust these to your arena size)
	spawn_system.set_spawn_positions([
		Vector2(5100, 359),   # Left spawn (200 units left of player)
		Vector2(5500, 359),   # Right spawn (200 units right of player)
		Vector2(5300, 359)    # Center spawn (at player position)
	])
	
	# Connect signals for UI/events
	spawn_system.wave_started.connect(_on_wave_started)
	spawn_system.wave_completed.connect(_on_wave_completed)
	spawn_system.boss_spawned.connect(_on_boss_spawned)
	spawn_system.game_won.connect(_on_game_won)
	
	print("✅ Spawn System initialized")

# ==================== SIGNAL HANDLERS ====================

func _on_wave_started(wave_number: int, enemy_count: int):
	print("📢 UI: Wave ", wave_number, " started! Enemies: ", enemy_count)
	# TODO: Update UI here
	# Example: $WaveLabel.text = "Wave " + str(wave_number)

func _on_wave_completed(wave_number: int):
	print("📢 UI: Wave ", wave_number, " completed!")
	# TODO: Show wave complete message
	# Example: $MessageLabel.text = "Wave Complete!"

func _on_boss_spawned():
	print("📢 UI: BOSS FIGHT!")
	# TODO: Show boss warning
	# Example: $BossWarning.visible = true

func _on_game_won():
	print("📢 UI: VICTORY!")
	# TODO: Show victory screen
	# Example: $VictoryScreen.visible = true
