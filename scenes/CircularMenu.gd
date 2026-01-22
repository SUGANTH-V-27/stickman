# CircularMenu.gd - Exact implementation matching React circular menu
extends CanvasLayer

# Menu configuration - matching original
const MENU_ITEMS = [
	{"label": "HOME", "icon": "🏠", "action": "resume"},
	{"label": "PROFILE", "icon": "👤", "action": "profile"},
	{"label": "EVENTS", "icon": "📅", "action": "events"},
	{"label": "SCHEDULE", "icon": "🕐", "action": "schedule"},
	{"label": "WORKSHOPS", "icon": "🔧", "action": "workshops"},
	{"label": "PAPERS", "icon": "📄", "action": "papers"},
	{"label": "ABOUT", "icon": "ℹ", "action": "about"}
]

# Colors - matching CSS
const PRIMARY_COLOR = Color("#c72071")
const SECONDARY_COLOR = Color("#1a020b")
const WHITE_COLOR = Color("#eeeeee")
const DARK_BG = Color(0.08, 0.08, 0.10, 0.9)

# State
var is_open = false
var active_index = 0
var selected_index = 0
var hovered_index = -1
var mouse_angle = -1.0
var rotation_angle = 0.0
var is_dragging = false
var show_hint = true

# Touch/drag tracking
var touch_start_angle = 0.0
var touch_start_rotation = 0.0
var center_pos = Vector2.ZERO

# Radii - Desktop
const INNER_RADIUS = 65.0
const OUTER_RADIUS = 195.0
const ICON_RADIUS = 130.0

# Node references
@onready var backdrop = $Backdrop
@onready var toggle_btn = $ToggleButton
@onready var pie_container = $PieMenuContainer
@onready var rotating_container = $PieMenuContainer/RotatingContainer
@onready var center_button = $PieMenuContainer/CenterButton
@onready var hint_label = $ToggleButton/HintLabel
@onready var segments_canvas = $PieMenuContainer/RotatingContainer/SegmentsCanvas

# Sound
var rotate_sound: AudioStreamPlayer
var open_sound: AudioStreamPlayer

func _ready():
	visible = true
	backdrop.modulate = Color(0, 0, 0, 0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie_container.scale = Vector2.ZERO
	pie_container.modulate.a = 0
	
	setup_sounds()
	style_buttons()
	check_first_time_hint()
	setup_menu_items()
	
	toggle_btn.pressed.connect(_on_toggle_pressed)
	center_button.pressed.connect(_on_center_pressed)
	backdrop.gui_input.connect(_on_backdrop_input)
	
	set_process_input(true)
	
	# Connect for mouse tracking
	pie_container.gui_input.connect(_on_pie_container_input)

func setup_sounds():
	rotate_sound = AudioStreamPlayer.new()
	open_sound = AudioStreamPlayer.new()
	add_child(rotate_sound)
	add_child(open_sound)
	rotate_sound.volume_db = -10
	open_sound.volume_db = -12

func style_buttons():
	# Toggle button - pause icon
	toggle_btn.text = "⏸"
	var toggle_style = StyleBoxFlat.new()
	toggle_style.bg_color = PRIMARY_COLOR
	toggle_style.corner_radius_top_left = 30
	toggle_style.corner_radius_top_right = 30
	toggle_style.corner_radius_bottom_left = 30
	toggle_style.corner_radius_bottom_right = 30
	toggle_btn.add_theme_stylebox_override("normal", toggle_style)
	toggle_btn.add_theme_color_override("font_color", WHITE_COLOR)
	toggle_btn.add_theme_font_size_override("font_size", 32)
	
	# Center button
	center_button.text = "✕"
	var center_style = StyleBoxFlat.new()
	center_style.bg_color = Color("#151518")
	center_style.border_width_left = 2
	center_style.border_width_right = 2
	center_style.border_width_top = 2
	center_style.border_width_bottom = 2
	center_style.border_color = Color(PRIMARY_COLOR.r, PRIMARY_COLOR.g, PRIMARY_COLOR.b, 0.5)
	center_style.corner_radius_top_left = 55
	center_style.corner_radius_top_right = 55
	center_style.corner_radius_bottom_left = 55
	center_style.corner_radius_bottom_right = 55
	center_button.add_theme_stylebox_override("normal", center_style)
	center_button.add_theme_color_override("font_color", PRIMARY_COLOR)
	center_button.add_theme_font_size_override("font_size", 32)

func check_first_time_hint():
	if not FileAccess.file_exists("user://menu_hint_seen.dat"):
		show_hint = true
		hint_label.visible = true
		hint_label.text = "Click to navigate"
	else:
		hint_label.visible = false

func setup_menu_items():
	# Setup canvas for drawing segments
	segments_canvas.draw.connect(_draw_segments)
	segments_canvas.queue_redraw()  # Force initial draw
	
	# Create icon buttons
	for i in range(MENU_ITEMS.size()):
		create_icon_button(i)

func create_icon_button(index: int):
	var item = MENU_ITEMS[index]
	var total = MENU_ITEMS.size()
	var segment_angle = 360.0 / total
	var angle = index * segment_angle
	
	# Position calculation - relative to center (210, 210)
	var rad = deg_to_rad(angle - 90)
	var x = cos(rad) * ICON_RADIUS
	var y = sin(rad) * ICON_RADIUS
	
	# Create container - position relative to center of RotatingContainer
	var container = Control.new()
	container.name = "Icon_" + str(index)
	container.position = Vector2(210 + x - 26, 210 + y - 26)  # Offset to center
	container.custom_minimum_size = Vector2(52, 52)
	container.pivot_offset = Vector2(26, 26)
	
	# Background panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(52, 52)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#141419")
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.2)
	style.corner_radius_top_left = 26
	style.corner_radius_top_right = 26
	style.corner_radius_bottom_left = 26
	style.corner_radius_bottom_right = 26
	panel.add_theme_stylebox_override("panel", style)
	container.add_child(panel)
	
	# Icon label
	var icon_label = Label.new()
	icon_label.text = item.icon
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.add_theme_color_override("font_color", WHITE_COLOR)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.size = Vector2(52, 52)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon_label)
	
	# Text label
	var text_label = Label.new()
	text_label.text = item.label
	text_label.add_theme_font_size_override("font_size", 9)
	text_label.add_theme_color_override("font_color", WHITE_COLOR)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.position = Vector2(-20, 56)
	text_label.size = Vector2(92, 20)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(text_label)
	
	# Button for interaction
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(52, 52)
	btn.flat = true
	btn.pressed.connect(_on_icon_clicked.bind(index))
	btn.mouse_entered.connect(func(): _on_icon_hovered(index))
	btn.mouse_exited.connect(func(): _on_icon_unhovered())
	container.add_child(btn)
	
	rotating_container.add_child(container)

func _draw_segments():
	for i in range(MENU_ITEMS.size()):
		draw_segment(i)

func draw_segment(index: int):
	var total = MENU_ITEMS.size()
	var segment_angle = 360.0 / total
	var start_angle = index * segment_angle - segment_angle / 2 - 90
	var end_angle = start_angle + segment_angle
	
	# Determine color
	var color = DARK_BG
	if index == hovered_index:
		color = Color(PRIMARY_COLOR.r, PRIMARY_COLOR.g, PRIMARY_COLOR.b, 0.2)
	elif index == active_index:
		color = Color(PRIMARY_COLOR.r, PRIMARY_COLOR.g, PRIMARY_COLOR.b, 0.35)
	elif index == selected_index:
		color = Color(PRIMARY_COLOR.r, PRIMARY_COLOR.g, PRIMARY_COLOR.b, 0.25)
	
	# Draw filled segment
	var points = PackedVector2Array()
	var steps = 30
	
	for i in range(steps + 1):
		var t = float(i) / steps
		var angle = start_angle + t * segment_angle
		var rad = deg_to_rad(angle)
		points.append(Vector2(cos(rad) * OUTER_RADIUS, sin(rad) * OUTER_RADIUS))
	
	for i in range(steps, -1, -1):
		var t = float(i) / steps
		var angle = start_angle + t * segment_angle
		var rad = deg_to_rad(angle)
		points.append(Vector2(cos(rad) * INNER_RADIUS, sin(rad) * INNER_RADIUS))
	
	segments_canvas.draw_colored_polygon(points, color)
	
	# Draw borders
	var border_color = Color(1, 1, 1, 0.15)
	
	# Outer arc
	for i in range(steps):
		var t1 = float(i) / steps
		var t2 = float(i + 1) / steps
		var a1 = deg_to_rad(start_angle + t1 * segment_angle)
		var a2 = deg_to_rad(start_angle + t2 * segment_angle)
		segments_canvas.draw_line(
			Vector2(cos(a1) * OUTER_RADIUS, sin(a1) * OUTER_RADIUS),
			Vector2(cos(a2) * OUTER_RADIUS, sin(a2) * OUTER_RADIUS),
			border_color, 1.0
		)
	
	# Inner arc
	for i in range(steps):
		var t1 = float(i) / steps
		var t2 = float(i + 1) / steps
		var a1 = deg_to_rad(start_angle + t1 * segment_angle)
		var a2 = deg_to_rad(start_angle + t2 * segment_angle)
		segments_canvas.draw_line(
			Vector2(cos(a1) * INNER_RADIUS, sin(a1) * INNER_RADIUS),
			Vector2(cos(a2) * INNER_RADIUS, sin(a2) * INNER_RADIUS),
			border_color, 1.0
		)
	
	# Side borders
	var start_rad = deg_to_rad(start_angle)
	var end_rad = deg_to_rad(end_angle)
	segments_canvas.draw_line(
		Vector2(cos(start_rad) * INNER_RADIUS, sin(start_rad) * INNER_RADIUS),
		Vector2(cos(start_rad) * OUTER_RADIUS, sin(start_rad) * OUTER_RADIUS),
		border_color, 1.0
	)
	segments_canvas.draw_line(
		Vector2(cos(end_rad) * INNER_RADIUS, sin(end_rad) * INNER_RADIUS),
		Vector2(cos(end_rad) * OUTER_RADIUS, sin(end_rad) * OUTER_RADIUS),
		border_color, 1.0
	)

func _on_pie_container_input(event):
	if not is_open:
		return
	
	if event is InputEventMouseMotion:
		handle_mouse_move(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			handle_touch_start(event.position)
		else:
			handle_touch_end()
	elif event is InputEventScreenDrag:
		handle_touch_move(event.position)

func handle_mouse_move(pos: Vector2):
	center_pos = pie_container.size / 2
	var dx = pos.x - center_pos.x
	var dy = pos.y - center_pos.y
	var distance = sqrt(dx * dx + dy * dy)
	
	if distance > 50 and distance < 250:
		var angle = atan2(dx, -dy) * 180.0 / PI
		if angle < 0:
			angle += 360
		mouse_angle = angle
		
		var segment_angle = 360.0 / MENU_ITEMS.size()
		var adjusted_angle = fmod(angle - rotation_angle + segment_angle / 2 + 360, 360)
		var segment_index = int(adjusted_angle / segment_angle)
		hovered_index = segment_index % MENU_ITEMS.size()
		update_visuals()
	else:
		hovered_index = -1
		mouse_angle = -1
		update_visuals()

func handle_touch_start(pos: Vector2):
	center_pos = pie_container.size / 2
	var dx = pos.x - center_pos.x
	var dy = pos.y - center_pos.y
	var distance = sqrt(dx * dx + dy * dy)
	
	if distance > 40 and distance < 180:
		var angle = atan2(dy, dx) * 180.0 / PI
		touch_start_angle = angle
		touch_start_rotation = rotation_angle
		is_dragging = true

func handle_touch_move(pos: Vector2):
	if not is_dragging:
		return
	
	center_pos = pie_container.size / 2
	var dx = pos.x - center_pos.x
	var dy = pos.y - center_pos.y
	var current_angle = atan2(dy, dx) * 180.0 / PI
	
	var delta_angle = current_angle - touch_start_angle
	if delta_angle > 180:
		delta_angle -= 360
	if delta_angle < -180:
		delta_angle += 360
	
	rotation_angle = touch_start_rotation + delta_angle
	rotating_container.rotation_degrees = rotation_angle
	update_icon_rotation()

func handle_touch_end():
	if not is_dragging:
		return
	
	is_dragging = false
	
	# Snap to nearest
	var segment_angle = 360.0 / MENU_ITEMS.size()
	var nearest_index = int(round(-rotation_angle / segment_angle)) % MENU_ITEMS.size()
	var snapped_rotation = -nearest_index * segment_angle
	
	var delta = snapped_rotation - rotation_angle
	while delta > 180:
		delta -= 360
	while delta < -180:
		delta += 360
	
	var final_rotation = rotation_angle + delta
	animate_rotation(final_rotation)
	selected_index = nearest_index

func update_visuals():
	segments_canvas.queue_redraw()
	update_icon_styles()

func update_icon_styles():
	for i in range(MENU_ITEMS.size()):
		var container = rotating_container.get_node_or_null("Icon_" + str(i))
		if container:
			var panel = container.get_child(0) as Panel
			var style = StyleBoxFlat.new()
			
			if i == hovered_index or i == active_index:
				style.bg_color = PRIMARY_COLOR
				style.border_color = PRIMARY_COLOR
				container.scale = Vector2(1.15, 1.15)
			else:
				style.bg_color = Color("#141419")
				style.border_color = Color(1, 1, 1, 0.2)
				container.scale = Vector2(1.0, 1.0)
			
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
			style.corner_radius_top_left = 26
			style.corner_radius_top_right = 26
			style.corner_radius_bottom_left = 26
			style.corner_radius_bottom_right = 26
			panel.add_theme_stylebox_override("panel", style)

func update_icon_rotation():
	for i in range(MENU_ITEMS.size()):
		var container = rotating_container.get_node_or_null("Icon_" + str(i))
		if container:
			container.rotation_degrees = -rotation_angle

func animate_rotation(target: float):
	var tween = create_tween()
	tween.tween_property(rotating_container, "rotation_degrees", target, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(val): 
		rotation_angle = val
		update_icon_rotation()
	, rotation_angle, target, 0.5)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			toggle_menu()
			get_viewport().set_input_as_handled()
		
		if is_open:
			if event.keycode == KEY_LEFT:
				rotate_menu(-1)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_RIGHT:
				rotate_menu(1)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ENTER:
				execute_action(selected_index)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ESCAPE:
				close_menu()
				get_viewport().set_input_as_handled()

func rotate_menu(direction: int):
	var segment_angle = 360.0 / MENU_ITEMS.size()
	selected_index = (selected_index + direction + MENU_ITEMS.size()) % MENU_ITEMS.size()
	var target = -selected_index * segment_angle
	animate_rotation(target)
	if rotate_sound.stream:
		rotate_sound.play()

func _on_icon_clicked(index: int):
	if is_dragging:
		return
	
	var segment_angle = 360.0 / MENU_ITEMS.size()
	var target = -index * segment_angle
	
	var delta = target - rotation_angle
	while delta > 180:
		delta -= 360
	while delta < -180:
		delta += 360
	
	animate_rotation(rotation_angle + delta)
	selected_index = index
	active_index = index
	
	if rotate_sound.stream:
		rotate_sound.play()
	
	await get_tree().create_timer(0.5).timeout
	execute_action(index)

func _on_icon_hovered(index: int):
	hovered_index = index
	update_visuals()

func _on_icon_unhovered():
	hovered_index = -1
	update_visuals()

func _on_toggle_pressed():
	toggle_menu()

func toggle_menu():
	if is_open:
		close_menu()
	else:
		open_menu()

func open_menu():
	is_open = true
	
	# Pause the game
	get_tree().paused = true
	
	if open_sound.stream:
		open_sound.play()
	
	if show_hint:
		show_hint = false
		hint_label.visible = false
		var file = FileAccess.open("user://menu_hint_seen.dat", FileAccess.WRITE)
		file.store_8(1)
		file.close()
	
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(backdrop, "modulate", Color(0, 0, 0, 0.85), 0.4)
	tween.tween_property(pie_container, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(pie_container, "modulate:a", 1.0, 0.3)
	tween.tween_property(toggle_btn, "modulate:a", 0.0, 0.4)
	
	# Redraw segments when menu opens
	await get_tree().create_timer(0.1).timeout
	segments_canvas.queue_redraw()

func close_menu():
	is_open = false
	hovered_index = -1
	
	# Resume the game
	get_tree().paused = false
	
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(backdrop, "modulate", Color(0, 0, 0, 0), 0.4)
	tween.tween_property(pie_container, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(pie_container, "modulate:a", 0.0, 0.3)
	tween.tween_property(toggle_btn, "modulate:a", 1.0, 0.4)

func _on_center_pressed():
	close_menu()

func _on_backdrop_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_menu()

func execute_action(index: int):
	var action = MENU_ITEMS[index].action
	print("Action: ", action)
	
	match action:
		"resume":
			close_menu()
		"restart":
			get_tree().reload_current_scene()
		"quit":
			get_tree().quit()
		_:
			print("Action not implemented: ", action)
	
	close_menu()
