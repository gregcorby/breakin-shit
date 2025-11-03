extends Node3D

## ParticleEffects - Manages visual effects for kicks, impacts, etc.

@export var kick_impact_particles: PackedScene
@export var dust_particles: PackedScene

# Particle pools for performance
var particle_pool: Array[GPUParticles3D] = []
var max_pool_size: int = 20

func _ready() -> void:
	# Pre-create particle systems for pooling
	initialize_particle_pool()

func initialize_particle_pool() -> void:
	"""Create a pool of reusable particle systems"""
	for i in range(max_pool_size):
		var particles = create_kick_particles()
		particles.emitting = false
		particles.one_shot = true
		add_child(particles)
		particle_pool.append(particles)

func create_kick_particles() -> GPUParticles3D:
	"""Create kick impact particle system"""
	var particles = GPUParticles3D.new()

	particles.amount = 20
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.8

	# Create particle material
	var material = ParticleProcessMaterial.new()

	# Emission
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.5

	# Direction
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 6.0

	# Gravity
	material.gravity = Vector3(0, -9.8, 0)

	# Scale
	material.scale_min = 0.1
	material.scale_max = 0.3

	# Color
	material.color = Color(1.0, 0.8, 0.3, 1.0)

	particles.process_material = material

	# Create mesh for particles
	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.1
	draw_pass.height = 0.2
	particles.draw_pass_1 = draw_pass

	return particles

func play_kick_effect(position: Vector3) -> void:
	"""Play kick impact effect at position"""
	var particles = get_available_particle()

	if particles:
		particles.global_position = position
		particles.emitting = true
		particles.restart()

func play_dust_effect(position: Vector3) -> void:
	"""Play dust cloud effect"""
	var particles = create_dust_particles()
	particles.global_position = position
	add_child(particles)

	# Auto-remove after lifetime
	await get_tree().create_timer(particles.lifetime + 0.5).timeout
	particles.queue_free()

func create_dust_particles() -> GPUParticles3D:
	"""Create dust particle effect"""
	var particles = GPUParticles3D.new()

	particles.amount = 15
	particles.lifetime = 0.8
	particles.one_shot = true
	particles.explosiveness = 0.6

	var material = ParticleProcessMaterial.new()

	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.3

	material.direction = Vector3(0, 0.5, 0)
	material.spread = 30.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 2.0

	material.gravity = Vector3(0, -2.0, 0)

	material.scale_min = 0.2
	material.scale_max = 0.5

	material.color = Color(0.6, 0.5, 0.4, 0.5)

	particles.process_material = material

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.15
	particles.draw_pass_1 = draw_pass

	return particles

func get_available_particle() -> GPUParticles3D:
	"""Get an available particle system from the pool"""
	for particles in particle_pool:
		if not particles.emitting:
			return particles

	# If no available particles, return the first one (will restart it)
	return particle_pool[0]

func create_explosion_effect(position: Vector3, size: float = 1.0) -> void:
	"""Create an explosion effect"""
	var particles = GPUParticles3D.new()
	particles.global_position = position

	particles.amount = 30
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 1.0

	var material = ParticleProcessMaterial.new()

	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.1

	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 5.0 * size
	material.initial_velocity_max = 10.0 * size

	material.gravity = Vector3(0, -5.0, 0)

	material.scale_min = 0.2 * size
	material.scale_max = 0.5 * size

	# Gradient for color over lifetime
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.5, 0.0, 1.0))
	gradient.add_point(0.5, Color(1.0, 0.2, 0.0, 0.8))
	gradient.add_point(1.0, Color(0.3, 0.3, 0.3, 0.0))

	material.color_ramp = gradient

	particles.process_material = material

	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.2
	particles.draw_pass_1 = draw_pass

	add_child(particles)
	particles.emitting = true

	# Auto-remove
	await get_tree().create_timer(particles.lifetime + 0.5).timeout
	particles.queue_free()
