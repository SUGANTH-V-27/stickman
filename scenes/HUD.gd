extends CanvasLayer

@onready var menu_button: Button = $Control/MenuButton
@onready var circular_menu: Control = $Control/CircularMenu
@onready var game_over_label: Label = $GameOverLabel
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready():
	# HUD should keep running even when paused
	set_process_mode(Node.PROCESS_MODE_WHEN_PAUSED)

	if circular_menu:
		circular_menu.visible = false
	if game_over_label:
		game_over_label.visible = false

	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed():
	if circular_menu:
		circular_menu.visible = !circular_menu.visible
		get_tree().paused = circular_menu.visible

		if circular_menu.visible:
			_pause_game()
		else:
			_resume_game()

func _pause_game():
	for node in get_tree().get_nodes_in_group("pausable"):
		if node.has_method("_set_paused_state"):
			node._set_paused_state(true)

func _resume_game():
	for node in get_tree().get_nodes_in_group("pausable"):
		if node.has_method("_set_paused_state"):
			node._set_paused_state(false)
