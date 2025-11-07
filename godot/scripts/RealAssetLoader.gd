extends Node

## RealAssetLoader - Loads real 3D models from downloaded assets

# List of available building models
var building_models: Array[String] = []
var building_models_loaded: bool = false

func _ready():
	load_building_list()

func load_building_list() -> void:
	"""Scan and cache available building models"""
	var dir = DirAccess.open("res://assets/models/buildings")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".obj"):
				building_models.append("res://assets/models/buildings/" + file_name)
			file_name = dir.get_next()

		dir.list_dir_end()
		building_models_loaded = true
		print("Loaded ", building_models.size(), " building models")
	else:
		print("Could not open buildings directory")

func get_random_building() -> String:
	"""Get a random building model path"""
	if building_models.size() > 0:
		return building_models[randi() % building_models.size()]
	return ""

func load_building_model(model_path: String) -> MeshInstance3D:
	"""Load a building OBJ model"""
	if model_path == "":
		return null

	# In Godot, OBJ files are automatically imported
	# We can load them as resources
	var mesh_instance = MeshInstance3D.new()

	# Try to load the imported mesh
	if ResourceLoader.exists(model_path):
		var mesh_resource = load(model_path)
		if mesh_resource is Mesh:
			mesh_instance.mesh = mesh_resource
		elif mesh_resource is ArrayMesh:
			mesh_instance.mesh = mesh_resource

	return mesh_instance

func load_character_model() -> Node3D:
	"""Load the character model with animations"""
	var character_path = "res://assets/models/characters/Model/characterMedium.fbx"

	if ResourceLoader.exists(character_path):
		var scene = load(character_path)
		if scene:
			return scene.instantiate()

	return null

func has_real_buildings() -> bool:
	"""Check if real building models are available"""
	return building_models.size() > 0
