extends Control

func _ready():
	# Make sure the root fills the screen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	# === Instruction Card ===
	var card = ColorRect.new()
	card.name = "InstructionCard"
	card.color = Color("#FFBFCB99") # translucent pink
	card.anchor_left = 0.33
	card.anchor_top = 0.33
	card.anchor_right = 0.66
	card.anchor_bottom = 0.66

	# StyleBox for maroon border
	var style = StyleBoxFlat.new()
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color("#800000") # maroon
	card.add_theme_stylebox_override("panel", style)

	add_child(card)

	# === VBoxContainer for instructions ===
	var vbox = VBoxContainer.new()
	vbox.name = "InstructionText"
	vbox.anchor_left = 0.05
	vbox.anchor_top = 0.05
	vbox.anchor_right = 0.95
	vbox.anchor_bottom = 0.85
	card.add_child(vbox)

	# Keyboard controls label
	var keyboard_label = Label.new()
	keyboard_label.text = "KEYBOARD CONTROLS:\nP - PUNCH\nK - KICK"
	vbox.add_child(keyboard_label)

	# Mobile controls label
	var mobile_label = Label.new()
	mobile_label.text = "MOBILE CONTROLS:\nTHE ICONS"
	vbox.add_child(mobile_label)

	# === Start Button ===
	var start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "Start Game"
	start_button.anchor_left = 0.7
	start_button.anchor_top = 0.85
	start_button.anchor_right = 0.95
	start_button.anchor_bottom = 0.95
	card.add_child(start_button)

	# Connect button signal
	start_button.connect("pressed", Callable(self, "_on_start_pressed"))

func _on_start_pressed():
	var main_scene = preload("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	queue_free()
