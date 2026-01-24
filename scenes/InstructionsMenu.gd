extends CanvasLayer

signal continue_pressed

@onready var continue_button: Button = $Control/Panel/VBoxContainer/ContinueButton

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)

func _on_continue_pressed():
	# Disconnect to prevent multiple presses
	continue_button.pressed.disconnect(_on_continue_pressed)
	
	# Emit signal and hide
	emit_signal("continue_pressed")
	hide()
	
	# Queue free after signal is processed
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		queue_free()
