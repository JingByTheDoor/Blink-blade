extends Node
## Manages all game audio - SFX and music

const MASTER_BUS := "Master"
const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

var sounds: Dictionary = {}
var music_tracks: Dictionary = {}
var current_music: String = ""


func _ready() -> void:
	_setup_audio_players()
	_load_audio_files()


func _setup_audio_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		sfx_players.append(player)


func _load_audio_files() -> void:
	var sfx_path := "res://assets/audio/sfx/"
	var music_path := "res://assets/audio/music/"
	
	var sfx_files := [
		"attack_1", "attack_2", "attack_3",
		"blink", "dash",
		"hit_player", "hit_enemy", "enemy_death",
		"combo_milestone", "combo_break",
		"upgrade_select", "door_open",
		"menu_select", "menu_hover"
	]
	
	for sfx_name in sfx_files:
		var path = sfx_path + sfx_name + ".wav"
		if ResourceLoader.exists(path):
			sounds[sfx_name] = load(path)
	
	var music_files := ["menu", "combat", "results"]
	for track_name in music_files:
		var path = music_path + track_name + ".ogg"
		if ResourceLoader.exists(path):
			music_tracks[track_name] = load(path)


func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	if not sounds.has(sound_name):
		return
	
	var player = _get_available_sfx_player()
	if player:
		player.stream = sounds[sound_name]
		player.volume_db = volume_db
		player.play()


func play_sfx_3d(sound_name: String, position: Vector3, volume_db: float = 0.0) -> void:
	play_sfx(sound_name, volume_db)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]


func play_music(track_name: String, fade_time: float = 1.0) -> void:
	if current_music == track_name:
		return
	
	if not music_tracks.has(track_name):
		stop_music(fade_time)
		return
	
	current_music = track_name
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, fade_time * 0.5)
	tween.tween_callback(func():
		music_player.stream = music_tracks[track_name]
		music_player.play()
	)
	tween.tween_property(music_player, "volume_db", 0.0, fade_time * 0.5)


func stop_music(fade_time: float = 1.0) -> void:
	current_music = ""
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, fade_time)
	tween.tween_callback(music_player.stop)


func set_master_volume(volume: float) -> void:
	var db = linear_to_db(clamp(volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), db)


func set_sfx_volume(volume: float) -> void:
	var db = linear_to_db(clamp(volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), db)


func set_music_volume(volume: float) -> void:
	var db = linear_to_db(clamp(volume, 0.0, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), db)
