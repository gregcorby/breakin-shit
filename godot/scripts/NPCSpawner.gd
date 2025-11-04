extends Node3D

## NPCSpawner - Spawns and manages NPC pedestrians throughout the city

@export var npc_scene: PackedScene
@export var max_npcs: int = 50
@export var spawn_radius: float = 100.0
@export var despawn_radius: float = 150.0
@export var spawn_interval: float = 2.0
@export var player: Node3D

@onready var spawn_timer: Timer = $SpawnTimer
@onready var npcs_parent: Node3D = $NPCs

var active_npcs: Array[Node3D] = []
var spawn_points: Array[Vector3] = []

func _ready() -> void:
	# Create NPCs parent node
	if not npcs_parent:
		npcs_parent = Node3D.new()
		npcs_parent.name = "NPCs"
		add_child(npcs_parent)

	# Setup spawn timer
	if not spawn_timer:
		spawn_timer = Timer.new()
		add_child(spawn_timer)
		spawn_timer.wait_time = spawn_interval
		spawn_timer.autostart = true
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# Find player if not set
	if not player:
		player = get_tree().get_first_node_in_group("player")

	# Generate spawn points
	generate_spawn_points()

	# Spawn initial NPCs
	for i in range(max_npcs / 2):
		spawn_npc()

func _process(_delta: float) -> void:
	if not player:
		return

	# Check for NPCs that are too far and should be despawned
	check_despawn_npcs()

func _on_spawn_timer_timeout() -> void:
	if active_npcs.size() < max_npcs:
		spawn_npc()

func spawn_npc() -> void:
	"""Spawn a new NPC at a random spawn point"""
	if not player:
		return

	# Find a valid spawn point near the player
	var spawn_pos = find_spawn_position()

	if spawn_pos == Vector3.ZERO:
		return  # No valid spawn point found

	# Create NPC instance
	var npc = create_npc_instance()
	npc.global_position = spawn_pos

	npcs_parent.add_child(npc)
	active_npcs.append(npc)

	# Connect to NPC signals if needed
	if npc.has_signal("died"):
		npc.died.connect(_on_npc_died.bind(npc))

func create_npc_instance() -> Node3D:
	"""Create an NPC with procedural pedestrian model"""
	var npc = CharacterBody3D.new()

	# Add the NPC script
	var script = load("res://scripts/NPCPedestrian.gd")
	if script:
		npc.set_script(script)

	# Random color for variety
	var colors = [
		Color(0.8, 0.2, 0.2),  # Red
		Color(0.2, 0.8, 0.2),  # Green
		Color(0.2, 0.2, 0.8),  # Blue
		Color(0.8, 0.8, 0.2),  # Yellow
		Color(0.8, 0.2, 0.8),  # Magenta
		Color(0.2, 0.8, 0.8),  # Cyan
	]
	var color = colors[randi() % colors.size()]

	# Create pedestrian model using procedural assets
	var procedural_assets = load("res://scripts/ProceduralAssets.gd")
	var mesh_instance = procedural_assets.create_pedestrian_model(color)
	mesh_instance.name = "Mesh"

	npc.add_child(mesh_instance)

	# Add collision shape
	var collision_shape = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.3
	collision_shape.shape = shape
	collision_shape.position = Vector3(0, 0.9, 0)

	npc.add_child(collision_shape)

	# Add navigation agent
	var nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	npc.add_child(nav_agent)

	# Add animation player (placeholder)
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	npc.add_child(anim_player)

	# Add timers
	var state_timer = Timer.new()
	state_timer.name = "StateTimer"
	npc.add_child(state_timer)

	npc.add_to_group("npc")

	return npc

func find_spawn_position() -> Vector3:
	"""Find a valid spawn position near the player"""
	var attempts = 10

	for i in range(attempts):
		# Random angle around player
		var angle = randf() * TAU
		var distance = randf_range(spawn_radius * 0.5, spawn_radius)

		var spawn_pos = player.global_position + Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)

		# Check if position is valid (on navmesh and not too close to other NPCs)
		if is_valid_spawn_position(spawn_pos):
			return spawn_pos

	return Vector3.ZERO

func is_valid_spawn_position(pos: Vector3) -> bool:
	"""Check if spawn position is valid"""
	# Check distance to other NPCs
	for npc in active_npcs:
		if npc and is_instance_valid(npc):
			if pos.distance_to(npc.global_position) < 3.0:
				return false

	# Position is valid
	return true

func check_despawn_npcs() -> void:
	"""Remove NPCs that are too far from the player"""
	var npcs_to_remove = []

	for npc in active_npcs:
		if not is_instance_valid(npc):
			npcs_to_remove.append(npc)
			continue

		var distance = npc.global_position.distance_to(player.global_position)

		if distance > despawn_radius:
			npcs_to_remove.append(npc)

	# Remove distant NPCs
	for npc in npcs_to_remove:
		active_npcs.erase(npc)
		if is_instance_valid(npc):
			npc.queue_free()

func _on_npc_died(npc: Node3D) -> void:
	"""Handle NPC death"""
	active_npcs.erase(npc)

func generate_spawn_points() -> void:
	"""Generate potential spawn points throughout the city"""
	# This could be more sophisticated, placing spawn points at specific locations
	# For now, we'll spawn dynamically around the player

	pass

func get_npc_count() -> int:
	return active_npcs.size()
