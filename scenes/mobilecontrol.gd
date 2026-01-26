extends Control

@export var player: CharacterBody2D

@onready var left_button: Button = $LeftButton
@onready var right_button: Button = $RightButton
@onready var jump_button: Button = $JumpButton
@onready var attack_button: Button = $AttackButton
@onready var kick_button: Button = $KickButton

# Shared input state dictionary (same keys as Player.gd)
var input_states := {
	"ui_left": false,
	"ui_right": false,
	"jump": false,
	"attack": false,
	"kick": false
}

func setup_controls():
	if player == null:
		push_error("Player not assigned to MobileControls!")
		return

	# Left movement
	left_button.button_down.connect(func(): input_states["ui_left"] = true)
	left_button.button_up.connect(func(): input_states["ui_left"] = false)

	# Right movement
	right_button.button_down.connect(func(): input_states["ui_right"] = true)
	right_button.button_up.connect(func(): input_states["ui_right"] = false)

	# Jump
	jump_button.button_down.connect(func(): input_states["jump"] = true)
	jump_button.button_up.connect(func(): input_states["jump"] = false)

	# Attack
	attack_button.button_down.connect(func(): input_states["attack"] = true)
	attack_button.button_up.connect(func(): input_states["attack"] = false)

	# Kick
	kick_button.button_down.connect(func(): input_states["kick"] = true)
	kick_button.button_up.connect(func(): input_states["kick"] = false)

func adjust_button_sizes():
	var is_mobile := (OS.get_name() in ["Android", "iOS"]) or DisplayServer.is_touchscreen_available()

	if is_mobile:
		var target_size := Vector2(150, 150)
		for button in [left_button, right_button, jump_button, attack_button, kick_button]:
			button.visible = true
			button.custom_minimum_size = target_size
			button.set_size(target_size)
	else:
		for button in [left_button, right_button, jump_button, attack_button, kick_button]:
			button.visible = false
