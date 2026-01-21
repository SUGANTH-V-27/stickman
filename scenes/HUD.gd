

extends CanvasLayer

@onready var pause_button   = $Control/MarginContainer/HBoxContainer/PauseButton
@onready var restart_button = $Control/MarginContainer/HBoxContainer/RestartButton
@onready var quit_button    = $Control/MarginContainer/HBoxContainer/QuitButton

var is_paused := false

func _ready():
	# Connect signals
	pause_button.text = "Pause"
	pause_button.pressed.connect(_on_pause_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Apply comet styling
	_style_comet_button(pause_button, "Pause")
	_style_comet_button(restart_button, "Restart")
	_style_comet_button(quit_button, "Quit")


func _on_pause_pressed():
	if is_paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game():
	is_paused = true
	pause_button.text = "Resume"
	# Pause only gameplay nodes, not HUD
	get_tree().call_group("pausable", "_set_paused_state", true)


func _resume_game():
	is_paused = false
	pause_button.text = "Pause"
	# Resume gameplay nodes
	get_tree().call_group("pausable", "_set_paused_state", false)


func _on_restart_pressed():
	# Restart always reloads scene, independent of pause state
	is_paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed():
	# Quit always exits, independent of pause state
	get_tree().quit()


func _style_comet_button(btn: Button, text: String) -> void:
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 80)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("#1A0A0A")
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16

	var hover = normal.duplicate()
	hover.border_color = Color("#FF2E88").lightened(0.1)
	hover.shadow_color = Color(0.78, 0.12, 0.44, 0.35)  # comet glow
	hover.shadow_size = 6

	var pressed = normal.duplicate()
	pressed.bg_color = Color("#1F2121").darkened(0.2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
