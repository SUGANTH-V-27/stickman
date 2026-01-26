extends Control

@export var player: CharacterBody2D

@onready var left_button: Button = $LeftButton
@onready var right_button: Button = $RightButton
@onready var jump_button: Button = $JumpButton
@onready var attack_button: Button = $AttackButton
@onready var kick_button: Button = $KickButton


func setup_controls():
	if player == null:
		push_error("Player not assigned to MobileControls!")
		return

	# Movement buttons
	left_button.button_down.connect(func(): Input.action_press("ui_left"))
	left_button.button_up.connect(func(): Input.action_release("ui_left"))

	right_button.button_down.connect(func(): Input.action_press("ui_right"))
	right_button.button_up.connect(func(): Input.action_release("ui_right"))

	# Jump button
	jump_button.button_down.connect(func(): Input.action_press("jump"))
	jump_button.button_up.connect(func(): Input.action_release("jump"))

	# Attack button
	attack_button.button_down.connect(func(): Input.action_press("attack"))
	attack_button.button_up.connect(func(): Input.action_release("attack"))

	# Kick button
	kick_button.button_down.connect(func(): Input.action_press("kick"))
	kick_button.button_up.connect(func(): Input.action_release("kick"))


func adjust_button_sizes():
	var is_mobile := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

	if is_mobile:
		# Show buttons on mobile with 150x150 size
		var target_size := Vector2(150, 150)
		for button in [left_button, right_button, jump_button, attack_button, kick_button]:
			button.visible = true
			button.custom_minimum_size = target_size
			button.set_size(target_size)
	else:
		# Hide buttons completely on desktop/laptop
		for button in [left_button, right_button, jump_button, attack_button, kick_button]:
			button.visible = false
