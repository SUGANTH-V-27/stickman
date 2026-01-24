extends CanvasLayer

# HUD Script
# Handles UI elements like menu button and circular menu

@onready var menu_button: Button = $Control/MenuButton
@onready var circular_menu: Control = $Control/CircularMenu

func _ready():
	# Hide circular menu initially
	if circular_menu:
		circular_menu.visible = false
	
	# Connect menu button
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed():
	# Toggle circular menu visibility
	if circular_menu:
		circular_menu.visible = !circular_menu.visible
		
		# Pause game when menu is open
		get_tree().paused = circular_menu.visible
		
		# Notify pausable nodes
		if circular_menu.visible:
			_pause_game()
		else:
			_resume_game()

func _pause_game():
	# Notify all pausable nodes
	for node in get_tree().get_nodes_in_group("pausable"):
		if node.has_method("_set_paused_state"):
			node._set_paused_state(true)

func _resume_game():
	# Notify all pausable nodes
	for node in get_tree().get_nodes_in_group("pausable"):
		if node.has_method("_set_paused_state"):
			node._set_paused_state(false)
