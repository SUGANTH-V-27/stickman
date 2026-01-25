# main.gd - Main game scene
extends Node2D

# Systems
var combat_system
var spawn_system
var circular_menu
var instructions_menu
var wave_selection_menu

var selected_waves: int = 0

# Node references
@onready var player = $player  # Your player node
@onready var enemy = $enemy    # Remove this - enemies will be spawned!
@onready var parallax_bg = $ParallaxBackground
@onready var hud = $CanvasLayer/hud
@onready var mobile_controls = $CanvasLayer/Mobilecontrols # ✅ Corrected name (case-sensitive)

func _ready():
	print("🎮 Main scene loaded!")

	# HUD is already instanced in main.tscn as node "hud".
	if not is_instance_valid(hud):
		var HUDScene = preload("res://scenes/HUD.tscn")
		hud = HUDScene.instantiate()
		add_child(hud)

	# Initialize player health
	player.health = player.max_health

	if not player.is_connected("health_changed", Callable(self, "_on_health_changed")):
		player.connect("health_changed", Callable(self, "_on_health_changed"))

	# ✅ Mobile controls setup
	if not is_instance_valid(mobile_controls):
		var MobileControlsScene = preload("res://scenes/mobilecontrols.tscn")
		mobile_controls = MobileControlsScene.instantiate()
		add_child(mobile_controls)

	mobile_controls.visible = true
	mobile_controls.player = player
	mobile_controls.z_index = 10

	# If your MobileControls.gd has a setup_controls() function, call it here:
	if mobile_controls.has_method("setup_controls"):
		mobile_controls.setup_controls()

	# Remove static enemy
	if enemy:
		enemy.queue_free()

	# Initialize systems ONCE
	setup_combat_system()
	setup_spawn_system()
	setup_circular_menu()

	# If player already chose waves (e.g. after Retry), restart immediately from Wave 1
	if get_tree().has_meta("selected_waves"):
		var saved = int(get_tree().get_meta("selected_waves"))
		if saved > 0:
			selected_waves = saved
			print("🔁 Restarting with saved waves: ", selected_waves)
			_start_wave_run(selected_waves)
			return

	# Show instructions first (fresh start)
	show_instructions()

func _process(delta):
	# Handle parallax background scrolling
	if parallax_bg:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			var cam_pos = cam.get_screen_center_position()
			parallax_bg.scroll_offset = cam_pos

func setup_combat_system():
	var CombatSystemScript = preload("res://Scripts/CombatSystem.gd")
	combat_system = CombatSystemScript.new(self)
	combat_system.name = "CombatSystem"
	add_child(combat_system)

	var camera = player.get_node_or_null("Camera2D")
	if camera:
		combat_system.set_camera(camera)

	print("✅ Combat System initialized")

func setup_spawn_system():
	var SpawnSystemScript = load("res://Scripts/SpawnSystem.gd")
	spawn_system = SpawnSystemScript.new(self)
	add_child(spawn_system)

	spawn_system.set_spawn_positions([
		Vector2(4500, 1005),   # Far left off-screen, on ground
		Vector2(6100, 1005),   # Far right off-screen, on ground
	])

	spawn_system.wave_started.connect(_on_wave_started)
	spawn_system.wave_completed.connect(_on_wave_completed)
	spawn_system.boss_spawned.connect(_on_boss_spawned)
	spawn_system.game_won.connect(_on_game_won)

	print("✅ Spawn System initialized")

func show_instructions():
	var InstructionsMenuScene = preload("res://scenes/InstructionsMenu.tscn")
	instructions_menu = InstructionsMenuScene.instantiate()
	instructions_menu.continue_pressed.connect(_on_instructions_continue)
	add_child(instructions_menu)
	print("📖 Instructions Menu shown")

func _on_instructions_continue():
	print("📖 Instructions acknowledged")
	show_wave_selection()

func show_wave_selection():
	var WaveSelectionScene = preload("res://scenes/WaveSelection.tscn")
	wave_selection_menu = WaveSelectionScene.instantiate()
	wave_selection_menu.wave_count_selected.connect(_on_wave_count_selected)
	add_child(wave_selection_menu)
	print("🎮 Wave Selection Menu shown")

func _on_wave_count_selected(wave_count: int):
	print("🎮 Player selected ", wave_count, " waves")
	selected_waves = wave_count
	get_tree().set_meta("selected_waves", selected_waves)
	_start_wave_run(selected_waves)

func _start_wave_run(wave_count: int) -> void:
	if is_instance_valid(instructions_menu):
		instructions_menu.queue_free()
		instructions_menu = null
	if is_instance_valid(wave_selection_menu):
		wave_selection_menu.queue_free()
		wave_selection_menu = null

	spawn_system.set_max_waves(wave_count)
	await get_tree().create_timer(0.1).timeout
	spawn_system.start_wave_mode()

# ==================== SIGNAL HANDLERS ====================

func _on_wave_started(wave_number: int, enemy_count: int):
	print("📢 UI: Wave ", wave_number, " started! Enemies: ", enemy_count)

func _on_wave_completed(wave_number: int):
	print("📢 UI: Wave ", wave_number, " completed!")

func _on_boss_spawned():
	print("📢 UI: BOSS FIGHT!")
	if hud and hud.has_method("show_boss_warning"):
		hud.show_boss_warning()

func _on_game_won():
	print("📢 UI: VICTORY!")
	if hud and hud.has_method("show_victory"):
		hud.show_victory()

func show_game_over():
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()

func show_victory():
	if hud and hud.has_method("show_victory"):
		hud.show_victory()

func setup_circular_menu():
	var CircularMenuScene = preload("res://scenes/CircularMenu.tscn")
	circular_menu = CircularMenuScene.instantiate()
	add_child(circular_menu)
	print("✅ New Circular Menu initialized")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().paused = not get_tree().paused
