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

	# Random building color
	var color = building_colors[randi() % building_colors.size()]

	# Create building using procedural asset system
	var procedural_assets = load("res://scripts/ProceduralAssets.gd")
	var building_model = procedural_assets.create_building_model(width, height, depth, color)

	# Add collision
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, height, depth)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0, height / 2, 0)

	building.add_child(building_model)
	building.add_child(collision_shape)

	buildings_parent.add_child(building)

# Windows are now created in ProceduralAssets.create_building_model()
# This function is no longer needed but kept for compatibility
func add_building_windows(building: Node3D, width: float, height: float, depth: float) -> void:
	pass  # Now handled by ProceduralAssets

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
	"""Create a lamppost using procedural model"""
	var procedural_assets = load("res://scripts/ProceduralAssets.gd")
	var lamppost = procedural_assets.create_lamppost_model()
	lamppost.position = position

	props_parent.add_child(lamppost)
