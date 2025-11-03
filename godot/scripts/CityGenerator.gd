extends Node3D

## CityGenerator - Procedurally generates a city environment with buildings and streets

@export var city_size: int = 20  # Size in blocks
@export var block_size: float = 30.0  # Size of each city block
@export var street_width: float = 10.0
@export var building_min_height: float = 10.0
@export var building_max_height: float = 50.0
@export var buildings_per_block: int = 4

@onready var buildings_parent: Node3D = $Buildings
@onready var streets_parent: Node3D = $Streets
@onready var props_parent: Node3D = $Props

# Building materials
var building_colors = [
	Color(0.8, 0.8, 0.8),  # Light gray
	Color(0.9, 0.85, 0.7),  # Beige
	Color(0.7, 0.7, 0.75),  # Blue-gray
	Color(0.85, 0.75, 0.65),  # Tan
	Color(0.6, 0.6, 0.6),  # Dark gray
]

func _ready() -> void:
	# Create parent nodes if they don't exist
	if not buildings_parent:
		buildings_parent = Node3D.new()
		buildings_parent.name = "Buildings"
		add_child(buildings_parent)

	if not streets_parent:
		streets_parent = Node3D.new()
		streets_parent.name = "Streets"
		add_child(streets_parent)

	if not props_parent:
		props_parent = Node3D.new()
		props_parent.name = "Props"
		add_child(props_parent)

	generate_city()

func generate_city() -> void:
	print("Generating city...")

	# Generate ground plane
	generate_ground()

	# Generate grid of buildings
	for x in range(-city_size, city_size):
		for z in range(-city_size, city_size):
			var block_pos = Vector3(
				x * (block_size + street_width),
				0,
				z * (block_size + street_width)
			)

			# Randomly decide if this block has a building
			if randf() > 0.3:  # 70% chance of building
				generate_building(block_pos)

			# Generate street
			generate_street(block_pos)

	# Generate city props (lampposts, benches, etc.)
	generate_props()

	print("City generation complete!")

func generate_ground() -> void:
	"""Create the ground plane"""
	var ground = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(city_size * block_size * 3, city_size * block_size * 3)

	ground.mesh = plane_mesh

	# Create ground material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.35, 0.3)  # Dark green
	ground.material_override = material

	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(city_size * block_size * 3, 0.1, city_size * block_size * 3)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0, -0.05, 0)

	static_body.add_child(collision_shape)
	static_body.collision_layer = 1
	static_body.collision_mask = 0

	ground.add_child(static_body)
	streets_parent.add_child(ground)

func generate_building(position: Vector3) -> void:
	"""Generate a single building at the given position"""
	var building = StaticBody3D.new()
	building.position = position
	building.collision_layer = 8  # Buildings layer

	# Random building dimensions
	var width = randf_range(block_size * 0.3, block_size * 0.8)
	var depth = randf_range(block_size * 0.3, block_size * 0.8)
	var height = randf_range(building_min_height, building_max_height)

	# Create building mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, height, depth)
	mesh_instance.mesh = box_mesh
	mesh_instance.position = Vector3(0, height / 2, 0)

	# Random building color
	var material = StandardMaterial3D.new()
	material.albedo_color = building_colors[randi() % building_colors.size()]
	material.metallic = 0.2
	material.roughness = 0.8
	mesh_instance.material_override = material

	# Add collision
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, height, depth)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0, height / 2, 0)

	building.add_child(mesh_instance)
	building.add_child(collision_shape)

	# Add windows (detail)
	add_building_windows(building, width, height, depth)

	buildings_parent.add_child(building)

func add_building_windows(building: Node3D, width: float, height: float, depth: float) -> void:
	"""Add window details to buildings"""
	var window_material = StandardMaterial3D.new()
	window_material.albedo_color = Color(0.3, 0.4, 0.6, 0.8)
	window_material.emission_enabled = true
	window_material.emission = Color(1.0, 0.95, 0.8)
	window_material.emission_energy = 0.3

	var window_size = 1.5
	var window_spacing = 3.0

	# Add windows on front and back
	for side in [-1, 1]:
		var x_offset = side * (width / 2 + 0.05)

		for y in range(int(height / window_spacing)):
			for z in range(int(depth / window_spacing)):
				var window = MeshInstance3D.new()
				var window_mesh = BoxMesh.new()
				window_mesh.size = Vector3(0.1, window_size, window_size)
				window.mesh = window_mesh
				window.material_override = window_material

				window.position = Vector3(
					x_offset,
					y * window_spacing + window_spacing,
					(z - depth / window_spacing / 2) * window_spacing
				)

				building.add_child(window)

func generate_street(position: Vector3) -> void:
	"""Generate street segments"""
	var street = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(street_width, block_size + street_width)

	street.mesh = plane_mesh
	street.position = position + Vector3(block_size / 2 + street_width / 2, 0.01, 0)
	street.rotation_degrees = Vector3(-90, 0, 0)

	# Street material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.22)  # Dark asphalt
	street.material_override = material

	streets_parent.add_child(street)

func generate_props() -> void:
	"""Generate city props like lampposts, benches, etc."""
	# This would add decorative elements to make the city feel alive
	# For now, we'll add some simple placeholder props

	for i in range(50):
		var prop_pos = Vector3(
			randf_range(-city_size * block_size, city_size * block_size),
			0,
			randf_range(-city_size * block_size, city_size * block_size)
		)

		# Simple lamppost
		create_lamppost(prop_pos)

func create_lamppost(position: Vector3) -> void:
	"""Create a simple lamppost"""
	var lamppost = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 5.0
	cylinder_mesh.top_radius = 0.1
	cylinder_mesh.bottom_radius = 0.15

	lamppost.mesh = cylinder_mesh
	lamppost.position = position + Vector3(0, 2.5, 0)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	lamppost.material_override = material

	# Add light
	var light = OmniLight3D.new()
	light.position = Vector3(0, 2.0, 0)
	light.light_energy = 0.5
	light.light_color = Color(1.0, 0.95, 0.8)
	light.omni_range = 10.0
	lamppost.add_child(light)

	props_parent.add_child(lamppost)
