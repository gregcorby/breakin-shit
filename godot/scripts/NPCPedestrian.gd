extends CharacterBody3D

## NPCPedestrian - AI-controlled pedestrian that walks around the city

@export var walk_speed: float = 2.0
@export var run_speed: float = 5.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0
@export var wander_radius: float = 20.0
@export var health: float = 100.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var mesh: Node3D = $Mesh
@onready var state_timer: Timer = $StateTimer
@onready var ragdoll: Node3D = $Ragdoll

enum State {
	IDLE,
	WALKING,
	RUNNING,
	KICKED,
	RAGDOLL
}

var current_state: State = State.IDLE
var spawn_position: Vector3
var target_position: Vector3
var is_fleeing: bool = false
var ragdoll_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("npc")
	spawn_position = global_position

	# Setup navigation
	if not navigation_agent:
		navigation_agent = NavigationAgent3D.new()
		add_child(navigation_agent)

	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	# Setup state timer
	if not state_timer:
		state_timer = Timer.new()
		add_child(state_timer)
		state_timer.timeout.connect(_on_state_timer_timeout)

	# Start with idle state
	change_state(State.IDLE)

	# Randomize initial appearance
	randomize_appearance()

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALKING:
			_process_walking(delta)
		State.RUNNING:
			_process_running(delta)
		State.KICKED:
			_process_kicked(delta)
		State.RAGDOLL:
			_process_ragdoll(delta)

func _process_idle(delta: float) -> void:
	# Just stand still, occasionally play idle animation
	velocity = velocity.move_toward(Vector3.ZERO, 5.0 * delta)
	move_and_slide()

func _process_walking(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		change_state(State.IDLE)
		return

	# Move towards target
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	# Rotate to face direction
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5.0 * delta)

	velocity = direction * walk_speed
	move_and_slide()

func _process_running(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		change_state(State.IDLE)
		is_fleeing = false
		return

	# Run away from player
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	# Rotate to face direction
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 8.0 * delta)

	velocity = direction * run_speed
	move_and_slide()

func _process_kicked(delta: float) -> void:
	# Apply physics when kicked
	velocity.y -= 20.0 * delta  # Gravity
	velocity = velocity.move_toward(Vector3.ZERO, 2.0 * delta)

	move_and_slide()

	# Check if landed
	if is_on_floor() and velocity.length() < 1.0:
		change_state(State.RAGDOLL)

func _process_ragdoll(delta: float) -> void:
	# Stay on ground in ragdoll state
	velocity = Vector3.ZERO
	move_and_slide()

func change_state(new_state: State) -> void:
	current_state = new_state

	match new_state:
		State.IDLE:
			state_timer.start(randf_range(idle_time_min, idle_time_max))
			play_animation("idle")
		State.WALKING:
			pick_random_destination()
			play_animation("walk")
		State.RUNNING:
			play_animation("run")
		State.KICKED:
			play_animation("hit")
			state_timer.start(2.0)
		State.RAGDOLL:
			play_animation("ragdoll")
			state_timer.start(5.0)

func _on_state_timer_timeout() -> void:
	match current_state:
		State.IDLE:
			# Randomly decide to walk or stay idle
			if randf() > 0.3:
				change_state(State.WALKING)
			else:
				change_state(State.IDLE)
		State.RAGDOLL:
			# Get up and resume walking
			change_state(State.IDLE)

func pick_random_destination() -> void:
	# Pick a random point within wander radius
	var random_offset = Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	target_position = spawn_position + random_offset
	navigation_agent.target_position = target_position

func on_kicked(direction: Vector3, force: float) -> void:
	"""Called when NPC is kicked by player"""
	if current_state == State.RAGDOLL:
		return

	change_state(State.KICKED)

	# Apply kick velocity
	velocity = direction * force

	# Play hit sound
	play_sound("hit")

	print("NPC ", name, " was kicked!")

func flee_from(threat_position: Vector3) -> void:
	"""Make NPC run away from a position"""
	if current_state == State.RAGDOLL or current_state == State.KICKED:
		return

	is_fleeing = true

	# Calculate flee direction
	var flee_direction = (global_position - threat_position).normalized()
	var flee_target = global_position + flee_direction * wander_radius

	navigation_agent.target_position = flee_target
	change_state(State.RUNNING)

func randomize_appearance() -> void:
	"""Randomize NPC colors and scale for variety"""
	if mesh:
		# Random scale variation
		var scale_factor = randf_range(0.9, 1.1)
		mesh.scale = Vector3.ONE * scale_factor

		# Random color tint (for clothing)
		# This would be applied to materials when we have actual models

func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func play_sound(sound_name: String) -> void:
	# Play sound effects
	pass
