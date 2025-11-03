extends Camera3D

## FollowCamera - GTA-style third-person camera that follows the player

@export var target: Node3D
@export var follow_distance: float = 10.0
@export var follow_height: float = 4.0
@export var camera_speed: float = 5.0
@export var look_ahead: float = 2.0
@export var mouse_sensitivity: float = 0.3
@export var rotation_speed: float = 3.0

@export_group("Camera Collision")
@export var enable_collision: bool = true
@export var min_distance: float = 2.0

var camera_rotation: float = 0.0
var camera_pitch: float = -20.0
var target_position: Vector3
var current_distance: float = 0.0

# Camera shake
var shake_amount: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	if not target:
		target = get_parent().get_node_or_null("DonkeyPlayer")

	current_distance = follow_distance

func _process(delta: float) -> void:
	if not target:
		return

	# Handle camera rotation input
	handle_camera_input(delta)

	# Calculate desired camera position
	var desired_position = calculate_camera_position()

	# Handle camera collision
	if enable_collision:
		desired_position = check_camera_collision(desired_position)

	# Smooth camera movement
	global_position = global_position.lerp(desired_position, camera_speed * delta)

	# Look at target with look-ahead
	var look_at_pos = calculate_look_at_position()
	var direction = (look_at_pos - global_position).normalized()

	if direction.length() > 0.01:
		look_at(look_at_pos, Vector3.UP)

	# Apply camera shake
	if shake_amount > 0:
		apply_camera_shake(delta)

func handle_camera_input(delta: float) -> void:
	# Keyboard camera rotation
	if Input.is_action_pressed("camera_left"):
		camera_rotation += rotation_speed * delta
	if Input.is_action_pressed("camera_right"):
		camera_rotation -= rotation_speed * delta

	# Mouse camera rotation (for desktop testing)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_rotation -= event.relative.x * mouse_sensitivity * 0.01
		camera_pitch = clamp(camera_pitch - event.relative.y * mouse_sensitivity * 0.01, -60, 0)

func calculate_camera_position() -> Vector3:
	if not target:
		return global_position

	# Calculate position based on rotation and pitch
	var offset = Vector3.ZERO
	offset.x = sin(camera_rotation) * follow_distance * cos(deg_to_rad(camera_pitch))
	offset.z = cos(camera_rotation) * follow_distance * cos(deg_to_rad(camera_pitch))
	offset.y = follow_height + sin(deg_to_rad(camera_pitch)) * follow_distance

	return target.global_position + offset

func calculate_look_at_position() -> Vector3:
	if not target:
		return global_position + Vector3.FORWARD

	# Look ahead based on player velocity
	var look_ahead_offset = Vector3.ZERO

	if target is CharacterBody3D:
		var velocity = target.velocity
		look_ahead_offset = velocity.normalized() * look_ahead

	return target.global_position + Vector3(0, 1.5, 0) + look_ahead_offset

func check_camera_collision(desired_pos: Vector3) -> Vector3:
	"""Check if camera would collide with geometry and adjust position"""
	if not target:
		return desired_pos

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		target.global_position + Vector3(0, 1, 0),
		desired_pos
	)
	query.exclude = [target]

	var result = space_state.intersect_ray(query)

	if result:
		# Camera would collide, pull it closer
		var collision_point = result.position
		var pull_back = (target.global_position - collision_point).normalized() * 0.5
		return collision_point + pull_back
	else:
		# No collision, smoothly return to desired distance
		current_distance = lerp(current_distance, follow_distance, 0.1)
		return desired_pos

func add_shake(amount: float) -> void:
	"""Add camera shake effect"""
	shake_amount = amount

func apply_camera_shake(delta: float) -> void:
	"""Apply shake to camera rotation"""
	var shake_offset = Vector3(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount, shake_amount),
		0
	)

	rotation_degrees += shake_offset

	# Decay shake
	shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)

func set_target(new_target: Node3D) -> void:
	target = new_target

func get_forward_direction() -> Vector3:
	"""Get camera forward direction (useful for relative controls)"""
	return -transform.basis.z.normalized()
