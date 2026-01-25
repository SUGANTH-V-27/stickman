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
	left_button.button_down.connect(player._on_LeftButton_pressed)
	left_button.button_up.connect(player._on_LeftButton_released)

	right_button.button_down.connect(player._on_RightButton_pressed)
	right_button.button_up.connect(player._on_RightButton_released)

	# Jump button
	jump_button.pressed.connect(player._on_JumpButton_pressed)

	# Combat buttons
	attack_button.pressed.connect(player._on_AttackButton_pressed)
	kick_button.pressed.connect(player._on_KickButton_pressed)
