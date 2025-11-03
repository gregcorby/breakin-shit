extends Node

## GameManager - Handles game state, scoring, and global game logic

signal score_changed(new_score: int)
signal game_over
signal npc_kicked(npc_position: Vector3)

var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

var combo_multiplier: int = 1
var combo_timer: float = 0.0
var kicked_npcs: int = 0
var game_time: float = 0.0
var is_paused: bool = false

const COMBO_TIMEOUT: float = 3.0
const POINTS_PER_KICK: int = 100

func _ready() -> void:
	print("GameManager initialized")
	reset_game()

func _process(delta: float) -> void:
	if is_paused:
		return

	game_time += delta

	# Handle combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()

func add_kick_score(kick_position: Vector3) -> void:
	"""Called when player successfully kicks an NPC"""
	kicked_npcs += 1

	# Calculate score with combo multiplier
	var points = POINTS_PER_KICK * combo_multiplier
	score += points

	# Increase combo
	combo_multiplier += 1
	combo_timer = COMBO_TIMEOUT

	# Emit signal for effects
	npc_kicked.emit(kick_position)

	print("Kick scored! Points: ", points, " | Combo: x", combo_multiplier, " | Total: ", score)

func reset_combo() -> void:
	"""Reset combo multiplier"""
	if combo_multiplier > 1:
		print("Combo ended at x", combo_multiplier)
	combo_multiplier = 1

func reset_game() -> void:
	"""Reset game state"""
	score = 0
	combo_multiplier = 1
	combo_timer = 0.0
	kicked_npcs = 0
	game_time = 0.0
	print("Game reset")

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false

func get_stats() -> Dictionary:
	"""Return current game statistics"""
	return {
		"score": score,
		"combo": combo_multiplier,
		"kicked_npcs": kicked_npcs,
		"game_time": game_time
	}
