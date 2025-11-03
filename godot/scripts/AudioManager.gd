extends Node

## AudioManager - Handles all audio playback including music and sound effects

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var music_volume: float = 0.7
var sfx_volume: float = 0.8

# Music tracks (would be actual audio files in production)
var music_tracks: Array[String] = [
	"res://audio/music/city_theme_1.ogg",
	"res://audio/music/city_theme_2.ogg",
	"res://audio/music/action_theme.ogg"
]

var current_track_index: int = 0

# Sound effects
var sound_effects: Dictionary = {
	"kick": "res://audio/sfx/kick.ogg",
	"hit": "res://audio/sfx/hit.ogg",
	"footstep": "res://audio/sfx/footstep.ogg",
	"donkey_bray": "res://audio/sfx/donkey_bray.ogg",
	"score": "res://audio/sfx/score.ogg",
	"combo": "res://audio/sfx/combo.ogg"
}

func _ready() -> void:
	# Create audio players if they don't exist
	if not music_player:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		music_player.bus = "Music"
		add_child(music_player)

	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		sfx_player.bus = "SFX"
		add_child(sfx_player)

	# Setup music player
	music_player.finished.connect(_on_music_finished)

	# Start playing music
	play_random_music()

func play_music(track_name: String) -> void:
	"""Play a specific music track"""
	if music_player.stream:
		music_player.stop()

	# In production, load actual audio file
	# For now, just start playing
	music_player.volume_db = linear_to_db(music_volume)
	music_player.play()

func play_random_music() -> void:
	"""Play a random music track"""
	if music_tracks.size() == 0:
		return

	current_track_index = randi() % music_tracks.size()
	play_music(music_tracks[current_track_index])

func play_next_music() -> void:
	"""Play the next music track in sequence"""
	if music_tracks.size() == 0:
		return

	current_track_index = (current_track_index + 1) % music_tracks.size()
	play_music(music_tracks[current_track_index])

func _on_music_finished() -> void:
	"""Called when a music track finishes"""
	play_next_music()

func play_sound(sound_name: String, position: Vector3 = Vector3.ZERO) -> void:
	"""Play a sound effect"""
	if not sound_effects.has(sound_name):
		print("Sound effect not found: ", sound_name)
		return

	# Create a 3D audio player for positional sound
	if position != Vector3.ZERO:
		play_3d_sound(sound_name, position)
	else:
		# Play 2D sound
		# In production, load actual audio file
		sfx_player.volume_db = linear_to_db(sfx_volume)
		sfx_player.play()

func play_3d_sound(sound_name: String, position: Vector3) -> void:
	"""Play a 3D positional sound effect"""
	var audio_player = AudioStreamPlayer3D.new()
	get_tree().root.add_child(audio_player)

	audio_player.global_position = position
	audio_player.volume_db = linear_to_db(sfx_volume)
	audio_player.max_distance = 50.0
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	# In production, load actual audio file
	audio_player.play()

	# Auto-remove when finished
	audio_player.finished.connect(func(): audio_player.queue_free())

func set_music_volume(volume: float) -> void:
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume)

func set_sfx_volume(volume: float) -> void:
	"""Set sound effects volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	if sfx_player:
		sfx_player.volume_db = linear_to_db(sfx_volume)

func stop_music() -> void:
	"""Stop music playback"""
	if music_player:
		music_player.stop()

func pause_music() -> void:
	"""Pause music playback"""
	if music_player:
		music_player.stream_paused = true

func resume_music() -> void:
	"""Resume music playback"""
	if music_player:
		music_player.stream_paused = false

func linear_to_db(linear: float) -> float:
	"""Convert linear volume to decibels"""
	if linear <= 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)
