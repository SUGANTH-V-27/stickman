extends CanvasLayer

signal wave_count_selected(wave_count: int)

@onready var spinbox: SpinBox = $Control/Panel/VBoxContainer/SpinBox
@onready var start_button: Button = $Control/Panel/VBoxContainer/StartButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	# Set default/range
	spinbox.min_value = 1
	spinbox.max_value = 20
	spinbox.value = 5
	spinbox.step = 1

func _on_start_pressed():
	var selected_waves = int(spinbox.value)
	
	# Disconnect button to prevent multiple presses
	start_button.pressed.disconnect(_on_start_pressed)
	
	# Emit signal and hide immediately
	emit_signal("wave_count_selected", selected_waves)
	hide()
	
	# Queue free after a short delay to ensure signal is processed
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		queue_free()
