extends CharacterBody3D

## DonkeyPlayer - Main player controller for the donkey with GTA-style controls

@export var move_speed: float = 8.0
@export var sprint_speed: float = 12.0
@export var rotation_speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 10.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 20.0

@export_group("Kick Settings")
@export var kick_range: float = 3.0
@export var kick_force: float = 15.0
@export var kick_cooldown: float = 0.5
@export var kick_angle: float = 60.0

@onready var kick_area: Area3D = $KickArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var mesh: Node3D = $DonkeyMesh
@onready var kick_timer: Timer = $KickTimer
@onready var footstep_timer: Timer = $FootstepTimer
@onready var audio_player: AudioStreamPlayer3D = $AudioPlayer

var can_kick: bool = true
var is_kicking: bool = false
var current_animation: String = "idle"

# Sound effects
var kick_sound_enabled: bool = true
var footstep_sound_enabled: bool = true

signal kicked(target: Node3D)

func _ready() -> void:
	# Setup kick area
	if not kick_area:
		kick_area = Area3D.new()
		add_child(kick_area)
		var collision_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(kick_range, 2.0, kick_range)
		collision_shape.shape = shape
		kick_area.add_child(collision_shape)
		kick_area.position = Vector3(0, 1, -kick_range/2)

	# Setup kick timer
	if not kick_timer:
		kick_timer = Timer.new()
		add_child(kick_timer)
		kick_timer.wait_time = kick_cooldown
		kick_timer.one_shot = true
		kick_timer.timeout.connect(_on_kick_cooldown_finished)

	# Setup footstep timer
	if not footstep_timer:
		footstep_timer = Timer.new()
		add_child(footstep_timer)
		footstep_timer.wait_time = 0.4
		footstep_timer.timeout.connect(_on_footstep_timer_timeout)

func _physics_process(delta: float) -> void:
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Jump (optional - can be removed if not desired)
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = jump_velocity

	# Handle movement
	if direction:
		# Rotate donkey to face movement direction
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

		# Move with acceleration
		var target_speed = sprint_speed if Input.is_action_pressed("ui_shift") else move_speed
		var target_velocity = direction * target_speed

		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

		# Play walk animation and footsteps
		play_animation("walk")
		if footstep_timer.is_stopped():
			footstep_timer.start()
	else:
		# Apply friction
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

		# Play idle animation
		play_animation("idle")
		footstep_timer.stop()

	# Handle kick action
	if Input.is_action_just_pressed("kick") and can_kick and not is_kicking:
		perform_kick()

	move_and_slide()

func perform_kick() -> void:
	"""Execute a kick attack"""
	can_kick = false
	is_kicking = true

	# Play kick animation
	play_animation("kick")

	# Play kick sound
	play_sound("kick")

	# Check for NPCs in kick range
	var kicked_any = false
	var bodies = kick_area.get_overlapping_bodies()

	for body in bodies:
		if body.is_in_group("npc") and body != self:
			kick_npc(body)
			kicked_any = true

	# Start cooldown timer
	kick_timer.start()

	# Reset kicking state after animation
	await get_tree().create_timer(0.3).timeout
	is_kicking = false

func kick_npc(npc: Node3D) -> void:
	"""Apply kick force to NPC and notify game manager"""
	# Calculate kick direction
	var kick_direction = (npc.global_position - global_position).normalized()
	kick_direction.y = 0.5  # Add upward force

	# Apply force if NPC has physics
	if npc is RigidBody3D:
		npc.apply_central_impulse(kick_direction * kick_force)
	elif npc is CharacterBody3D:
		npc.velocity = kick_direction * kick_force

	# Call NPC's hit method if it exists
	if npc.has_method("on_kicked"):
		npc.on_kicked(kick_direction, kick_force)

	# Notify game manager
	var game_manager = get_node("/root/Main/GameManager")
	if game_manager:
		game_manager.add_kick_score(npc.global_position)

	# Emit signal
	kicked.emit(npc)

	print("Kicked NPC: ", npc.name)

func _on_kick_cooldown_finished() -> void:
	can_kick = true

func _on_footstep_timer_timeout() -> void:
	if velocity.length() > 0.1:
		play_sound("footstep")

func play_animation(anim_name: String) -> void:
	"""Play animation if different from current"""
	if current_animation != anim_name and animation_player:
		if animation_player.has_animation(anim_name):
			animation_player.play(anim_name)
			current_animation = anim_name

func play_sound(sound_name: String) -> void:
	"""Play sound effect"""
	if not audio_player:
		return

	match sound_name:
		"kick":
			if kick_sound_enabled:
				# Play kick sound
				pass
		"footstep":
			if footstep_sound_enabled:
				# Play footstep sound
				pass

func get_forward_direction() -> Vector3:
	"""Get the forward direction of the donkey"""
	return -transform.basis.z.normalized()

func get_speed() -> float:
	"""Get current movement speed"""
	return Vector2(velocity.x, velocity.z).length()
