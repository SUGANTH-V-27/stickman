# main.gd - Main game scene
extends Node2D

# Systems
var combat_system
var spawn_system
var circular_menu
var instructions_menu
var wave_selection_menu

# Node references
@onready var player = $player  # Your player node
@onready var enemy = $enemy    # Remove this - enemies will be spawned!
@onready var parallax_bg = $ParallaxBackground

func _ready():
	print("🎮 Main scene loaded!")

	# Initialize player health
	player.health = player.max_health

	# Remove static enemy
	if enemy:
		enemy.queue_free()

	# Initialize systems ONCE
	setup_combat_system()
	setup_spawn_system()
	setup_circular_menu()

	# Show instructions first
	show_instructions()
	
func _process(delta):
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
	# Enemies spawn off-screen on left and right sides, then walk in
	# Y=1005 is ground level (just above the collision floor)
	spawn_system.set_spawn_positions([
		Vector2(4500, 1005),   # Far left off-screen, on ground
		Vector2(6100, 1005),   # Far right off-screen, on ground
	])
	
	# Connect signals for UI/events
	spawn_system.wave_started.connect(_on_wave_started)
	spawn_system.wave_completed.connect(_on_wave_completed)
	spawn_system.boss_spawned.connect(_on_boss_spawned)
	spawn_system.game_won.connect(_on_game_won)
	
	print("✅ Spawn System initialized")

# Show instructions menu
func show_instructions():
	var InstructionsMenuScene = preload("res://scenes/InstructionsMenu.tscn")
	instructions_menu = InstructionsMenuScene.instantiate()
	instructions_menu.continue_pressed.connect(_on_instructions_continue)
	add_child(instructions_menu)
	print("📖 Instructions Menu shown")

# Called when player clicks continue on instructions
func _on_instructions_continue():
	print("📖 Instructions acknowledged")
	show_wave_selection()

# Show wave selection menu
func show_wave_selection():
	var WaveSelectionScene = preload("res://scenes/WaveSelection.tscn")
	wave_selection_menu = WaveSelectionScene.instantiate()
	wave_selection_menu.wave_count_selected.connect(_on_wave_count_selected)
	add_child(wave_selection_menu)
	print("🎮 Wave Selection Menu shown")

# Called when player selects wave count
func _on_wave_count_selected(wave_count: int):
	print("🎮 Player selected ", wave_count, " waves")
	spawn_system.set_max_waves(wave_count)
	await get_tree().create_timer(0.5).timeout
	spawn_system.start_wave_mode()

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

# Setup circular menu
func setup_circular_menu():
	# Load NEW circular menu scene (advanced rotating wheel)
	var CircularMenuScene = preload("res://scenes/CircularMenu.tscn")
	circular_menu = CircularMenuScene.instantiate()
	add_child(circular_menu)
	print("✅ New Circular Menu initialized")

# Handle pause/resume (called from menu)
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().paused = not get_tree().paused
