extends CanvasLayer

@onready var menu_button: Button = $Control/MenuButton
@onready var circular_menu: Control = $Control/CircularMenu
@onready var game_over_panel: Control = $Control/GameOverPanel
@onready var victory_panel: Control = $Control/VictoryPanel
@onready var go_retry: Button = $Control/GameOverPanel/Panel/VBox/RetryButton
@onready var go_quit: Button = $Control/GameOverPanel/Panel/VBox/QuitButton
@onready var v_continue: Button = $Control/VictoryPanel/Panel/VBox/ContinueButton
@onready var v_quit: Button = $Control/VictoryPanel/Panel/VBox/QuitButton

func _ready():
	# HUD should keep running even when paused
	set_process_mode(Node.PROCESS_MODE_WHEN_PAUSED)

	if circular_menu:
		circular_menu.visible = false

	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)

	# Connect game over and victory buttons
	if go_retry:
		go_retry.pressed.connect(_on_retry_pressed)
	if go_quit:
		go_quit.pressed.connect(_on_quit_pressed)
	if v_continue:
		v_continue.pressed.connect(_on_continue_pressed)
	if v_quit:
		v_quit.pressed.connect(_on_quit_pressed)

	# Ensure panels hidden
	if game_over_panel:
		game_over_panel.visible = false
	if victory_panel:
		victory_panel.visible = false

func _on_menu_button_pressed():
	if circular_menu:
		circular_menu.visible = !circular_menu.visible
		
		# Pause game when menu is open
		var tree := get_tree()
		if tree:
			tree.paused = circular_menu.visible
		
		# Notify pausable nodes
		if circular_menu.visible:
			_pause_game()
		else:
			_resume_game()

func _pause_game():
	var tree := get_tree()
	if not tree:
		return
	# Notify all pausable nodes
	for node in tree.get_nodes_in_group("pausable"):
		if node.has_method("_set_paused_state"):
			node._set_paused_state(true)

func _resume_game():
	var tree := get_tree()
	if not tree:
		return
	# Notify all pausable nodes
	for node in tree.get_nodes_in_group("pausable"):
		if node.has_method("_set_paused_state"):
			node._set_paused_state(false)


func show_game_over():
	var tree := get_tree()
	if tree:
		tree.paused = true
	_pause_game()
	if game_over_panel:
		game_over_panel.visible = true


func show_victory():
	var tree := get_tree()
	if tree:
		tree.paused = true
	_pause_game()
	if victory_panel:
		victory_panel.visible = true


func _on_retry_pressed():
	# Reload current scene to retry
	if game_over_panel:
		game_over_panel.visible = false
	var tree := get_tree()
	if not tree:
		return
	tree.paused = false
	_resume_game()
	# Use call_deferred to reload after current frame
	tree.call_deferred("reload_current_scene")


func _on_continue_pressed():
	# After victory, restart the run (same as Retry)
	if victory_panel:
		victory_panel.visible = false
	var tree := get_tree()
	if not tree:
		return
	tree.paused = false
	_resume_game()
	tree.call_deferred("reload_current_scene")


func _on_quit_pressed():
	var tree := get_tree()
	if tree:
		tree.quit()
