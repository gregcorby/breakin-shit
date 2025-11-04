extends Node

## ProceduralAssets - Creates better-looking procedural 3D models
## This provides temporary assets until real 3D models are downloaded

static func create_donkey_model() -> MeshInstance3D:
	"""Create a simple but recognizable donkey model"""
	var root = Node3D.new()
	root.name = "DonkeyModel"

	# Body
	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.8, 0.6, 1.2)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.5, 0)

	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.6, 0.5, 0.4)  # Brown
	body.material_override = body_mat
	root.add_child(body)

	# Head
	var head = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.5, 0.6)
	head.mesh = head_mesh
	head.position = Vector3(0, 0.7, -0.8)
	head.rotation_degrees = Vector3(20, 0, 0)
	head.material_override = body_mat
	root.add_child(head)

	# Ears (long donkey ears!)
	for i in range(2):
		var ear = MeshInstance3D.new()
		var ear_mesh = BoxMesh.new()
		ear_mesh.size = Vector3(0.1, 0.4, 0.1)
		ear.mesh = ear_mesh
		var x_offset = -0.15 if i == 0 else 0.15
		ear.position = Vector3(x_offset, 1.0, -0.8)
		ear.rotation_degrees = Vector3(-30, 0, 0)

		var ear_mat = StandardMaterial3D.new()
		ear_mat.albedo_color = Color(0.7, 0.6, 0.5)
		ear.material_override = ear_mat
		root.add_child(ear)

	# Legs
	for i in range(4):
		var leg = MeshInstance3D.new()
		var leg_mesh = CylinderMesh.new()
		leg_mesh.height = 0.7
		leg_mesh.top_radius = 0.08
		leg_mesh.bottom_radius = 0.1
		leg.mesh = leg_mesh

		var x = 0.25 if i % 2 == 0 else -0.25
		var z = -0.3 if i < 2 else 0.3
		leg.position = Vector3(x, 0.15, z)

		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.5, 0.4, 0.3)
		leg.material_override = leg_mat
		root.add_child(leg)

	# Tail
	var tail = MeshInstance3D.new()
	var tail_mesh = CylinderMesh.new()
	tail_mesh.height = 0.4
	tail_mesh.top_radius = 0.02
	tail_mesh.bottom_radius = 0.05
	tail.mesh = tail_mesh
	tail.position = Vector3(0, 0.6, 0.7)
	tail.rotation_degrees = Vector3(45, 0, 0)
	tail.material_override = body_mat
	root.add_child(tail)

	# Eyes
	for i in range(2):
		var eye = MeshInstance3D.new()
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.06
		eye_mesh.height = 0.12
		eye.mesh = eye_mesh

		var x_offset = -0.12 if i == 0 else 0.12
		eye.position = Vector3(x_offset, 0.75, -1.0)

		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(0.1, 0.1, 0.1)
		eye.material_override = eye_mat
		root.add_child(eye)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.add_child(root)
	return mesh_instance

static func create_pedestrian_model(color: Color = Color.WHITE) -> MeshInstance3D:
	"""Create a simple person model"""
	var root = Node3D.new()
	root.name = "PedestrianModel"

	# Body (torso)
	var body = MeshInstance3D.new()
	var body_mesh = CapsuleMesh.new()
	body_mesh.height = 0.8
	body_mesh.radius = 0.2
	body.mesh = body_mesh
	body.position = Vector3(0, 0.9, 0)

	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = color
	body.material_override = body_mat
	root.add_child(body)

	# Head
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.15
	head.mesh = head_mesh
	head.position = Vector3(0, 1.45, 0)

	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.9, 0.8, 0.7)  # Skin tone
	head.material_override = head_mat
	root.add_child(head)

	# Arms
	for i in range(2):
		var arm = MeshInstance3D.new()
		var arm_mesh = CapsuleMesh.new()
		arm_mesh.height = 0.6
		arm_mesh.radius = 0.08
		arm.mesh = arm_mesh

		var x_offset = -0.25 if i == 0 else 0.25
		arm.position = Vector3(x_offset, 1.0, 0)
		arm.rotation_degrees = Vector3(0, 0, 15 if i == 0 else -15)
		arm.material_override = head_mat
		root.add_child(arm)

	# Legs
	for i in range(2):
		var leg = MeshInstance3D.new()
		var leg_mesh = CapsuleMesh.new()
		leg_mesh.height = 0.9
		leg_mesh.radius = 0.1
		leg.mesh = leg_mesh

		var x_offset = -0.1 if i == 0 else 0.1
		leg.position = Vector3(x_offset, 0.45, 0)

		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.2, 0.2, 0.3)  # Pants
		leg.material_override = leg_mat
		root.add_child(leg)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.add_child(root)
	return mesh_instance

static func create_building_model(width: float, height: float, depth: float, color: Color) -> MeshInstance3D:
	"""Create a detailed building with windows"""
	var root = Node3D.new()
	root.name = "BuildingModel"

	# Main building structure
	var building = MeshInstance3D.new()
	var building_mesh = BoxMesh.new()
	building_mesh.size = Vector3(width, height, depth)
	building.mesh = building_mesh
	building.position = Vector3(0, height / 2, 0)

	var building_mat = StandardMaterial3D.new()
	building_mat.albedo_color = color
	building_mat.metallic = 0.1
	building_mat.roughness = 0.9
	building.material_override = building_mat
	root.add_child(building)

	# Windows
	var window_mat = StandardMaterial3D.new()
	window_mat.albedo_color = Color(0.4, 0.5, 0.6, 0.7)
	window_mat.emission_enabled = true
	window_mat.emission = Color(1.0, 0.95, 0.8)
	window_mat.emission_energy = 0.2
	window_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var window_size = 1.2
	var window_spacing = 2.5
	var floors = int(height / window_spacing)
	var windows_per_side = int(depth / window_spacing)

	# Add windows on front and back
	for floor in range(1, floors):
		for win in range(windows_per_side):
			for side in [-1, 1]:
				var window = MeshInstance3D.new()
				var window_mesh = BoxMesh.new()
				window_mesh.size = Vector3(0.05, window_size, window_size)
				window.mesh = window_mesh
				window.material_override = window_mat

				var x_offset = side * (width / 2 + 0.02)
				var y_offset = floor * window_spacing
				var z_offset = (win - windows_per_side / 2) * window_spacing

				window.position = Vector3(x_offset, y_offset, z_offset)
				root.add_child(window)

	# Roof detail
	var roof = MeshInstance3D.new()
	var roof_mesh = BoxMesh.new()
	roof_mesh.size = Vector3(width + 0.2, 0.3, depth + 0.2)
	roof.mesh = roof_mesh
	roof.position = Vector3(0, height + 0.15, 0)

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = color.darkened(0.3)
	roof.material_override = roof_mat
	root.add_child(roof)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.add_child(root)
	return mesh_instance

static func create_lamppost_model() -> MeshInstance3D:
	"""Create a lamppost with light"""
	var root = Node3D.new()
	root.name = "LamppostModel"

	# Pole
	var pole = MeshInstance3D.new()
	var pole_mesh = CylinderMesh.new()
	pole_mesh.height = 4.0
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.12
	pole.mesh = pole_mesh
	pole.position = Vector3(0, 2.0, 0)

	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.3, 0.3, 0.3)
	pole_mat.metallic = 0.6
	pole.material_override = pole_mat
	root.add_child(pole)

	# Light housing
	var housing = MeshInstance3D.new()
	var housing_mesh = BoxMesh.new()
	housing_mesh.size = Vector3(0.3, 0.3, 0.3)
	housing.mesh = housing_mesh
	housing.position = Vector3(0, 4.2, 0)

	var housing_mat = StandardMaterial3D.new()
	housing_mat.albedo_color = Color(0.2, 0.2, 0.2)
	housing_mat.emission_enabled = true
	housing_mat.emission = Color(1.0, 0.95, 0.8)
	housing_mat.emission_energy = 0.5
	housing.material_override = housing_mat
	root.add_child(housing)

	# Add actual light
	var light = OmniLight3D.new()
	light.position = Vector3(0, 4.2, 0)
	light.light_energy = 0.8
	light.light_color = Color(1.0, 0.95, 0.8)
	light.omni_range = 12.0
	light.shadow_enabled = true
	root.add_child(light)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.add_child(root)
	return mesh_instance
