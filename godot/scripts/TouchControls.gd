extends CanvasLayer

## TouchControls - Mobile touch controls for player movement and actions

signal move_vector(direction: Vector2)
signal kick_pressed
signal kick_released

@onready var joystick: Control = $Joystick
@onready var joystick_base: TextureRect = $Joystick/Base
@onready var joystick_knob: TextureRect = $Joystick/Knob
@onready var kick_button: Button = $KickButton

var joystick_held: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2
var joystick_radius: float = 60.0
var current_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Create joystick if not in scene
	if not joystick:
		setup_joystick()

	# Create kick button if not in scene
	if not kick_button:
		setup_kick_button()

	# Connect signals
	if kick_button:
		kick_button.button_down.connect(_on_kick_button_down)
		kick_button.button_up.connect(_on_kick_button_up)

func setup_joystick() -> void:
	"""Create virtual joystick"""
	joystick = Control.new()
	joystick.name = "Joystick"
	add_child(joystick)

	# Base
	joystick_base = TextureRect.new()
	joystick_base.name = "Base"
	joystick_base.custom_minimum_size = Vector2(150, 150)
	joystick_base.position = Vector2(50, 400)

	# Create a circle texture for base
	var base_color = ColorRect.new()
	base_color.color = Color(1, 1, 1, 0.3)
	base_color.size = Vector2(150, 150)
	joystick_base.add_child(base_color)

	joystick.add_child(joystick_base)

	# Knob
	joystick_knob = TextureRect.new()
	joystick_knob.name = "Knob"
	joystick_knob.custom_minimum_size = Vector2(70, 70)
	joystick_knob.position = Vector2(40, 40)

	# Create a circle texture for knob
	var knob_color = ColorRect.new()
	knob_color.color = Color(1, 1, 1, 0.6)
	knob_color.size = Vector2(70, 70)
	joystick_knob.add_child(knob_color)

	joystick_base.add_child(joystick_knob)

	joystick_center = joystick_base.position + joystick_base.size / 2

func setup_kick_button() -> void:
	"""Create kick button"""
	kick_button = Button.new()
	kick_button.name = "KickButton"
	kick_button.text = "KICK"
	kick_button.custom_minimum_size = Vector2(120, 120)
	kick_button.position = Vector2(650, 430)

	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.3, 0.3, 0.7)
	style.corner_radius_bottom_left = 60
	style.corner_radius_bottom_right = 60
	style.corner_radius_top_left = 60
	style.corner_radius_top_right = 60

	kick_button.add_theme_stylebox_override("normal", style)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(1.0, 0.5, 0.5, 0.9)
	style_pressed.corner_radius_bottom_left = 60
	style_pressed.corner_radius_bottom_right = 60
	style_pressed.corner_radius_top_left = 60
	style_pressed.corner_radius_top_right = 60

	kick_button.add_theme_stylebox_override("pressed", style_pressed)

	add_child(kick_button)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_drag(event)

func handle_touch(event: InputEventScreenTouch) -> void:
	var touch_pos = event.position

	# Check if touch is on joystick area
	var joystick_area = Rect2(
		joystick_base.global_position,
		joystick_base.size
	)

	if event.pressed:
		if joystick_area.has_point(touch_pos) and joystick_touch_index == -1:
			joystick_held = true
			joystick_touch_index = event.index
			update_joystick(touch_pos)
	else:
		if event.index == joystick_touch_index:
			joystick_held = false
			joystick_touch_index = -1
			reset_joystick()

func handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_index and joystick_held:
		update_joystick(event.position)

func update_joystick(touch_pos: Vector2) -> void:
	var offset = touch_pos - joystick_center
	var distance = offset.length()

	# Clamp to radius
	if distance > joystick_radius:
		offset = offset.normalized() * joystick_radius
		distance = joystick_radius

	# Update knob position
	joystick_knob.position = joystick_base.size / 2 + offset - joystick_knob.size / 2

	# Calculate direction
	current_direction = offset / joystick_radius
	move_vector.emit(current_direction)

func reset_joystick() -> void:
	# Center the knob
	joystick_knob.position = (joystick_base.size - joystick_knob.size) / 2
	current_direction = Vector2.ZERO
	move_vector.emit(Vector2.ZERO)

func _on_kick_button_down() -> void:
	kick_pressed.emit()

func _on_kick_button_up() -> void:
	kick_released.emit()

func get_current_direction() -> Vector2:
	return current_direction

func set_visible_state(visible: bool) -> void:
	"""Show or hide touch controls"""
	visible = visible
