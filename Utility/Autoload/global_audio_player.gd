@icon("res://Assets/Packs/Kenney/Game Icons/gear.png")
extends Node
#AUTOLOAD

enum LevelMusicID {
    MENU_MUSIC = 0,
}

var global_poly_playback: AudioStreamPlaybackPolyphonic
var global_ui_poly_playback: AudioStreamPlaybackPolyphonic

@onready var music: AudioStreamPlayer = %MusicPlayer
@onready var global_sounds: Node = %GlobalSounds
@onready var global_poly: AudioStreamPlayer = %GlobalPolyphonic
@onready var global_ui_poly: AudioStreamPlayer = %UiPolyphonic
@onready var positional_sounds: Node = %PositionalSounds


func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS


func _ready():
    global_poly.play()
    global_poly_playback = global_poly.get_stream_playback()
    global_ui_poly.play()
    global_ui_poly_playback = global_ui_poly.get_stream_playback()


func play_music() -> void:
    if !music.playing:
        music.play()


func switch_music_by_id(music_id: int) -> void:
    play_music()
    music.get_stream_playback().switch_to_clip(music_id)


func switch_music_by_name(music_name: String) -> void:
    play_music()
    music.get_stream_playback().switch_to_clip_by_name(music_name)


func get_current_music_clip_name() -> String:
    var playback := music.get_stream_playback()
    if playback == null: return ""
    return playback.get_clip_name(playback.get_current_clip_index())


func play_ui_sound(audio: AudioStream, is_rand_pitch: bool = false) -> void:
    assert(global_ui_poly_playback != null)
    if audio == null: return
    var pitch: float = 1.0
    if is_rand_pitch:
        pitch = randf_range(0.9, 1.1)
    global_ui_poly_playback.play_stream(audio, 0, 0, pitch)


func play_global_sound(audio: AudioStream, is_rand_pitch: bool = true) -> void:
    assert(global_poly_playback != null)
    if audio == null: return
    var pitch: float = 1.0
    if is_rand_pitch:
        pitch = randf_range(0.85, 1.15)
    global_poly_playback.play_stream(audio, 0, 0, pitch)

## Creates an audio stream at pos (global) & returns the player. Player connects finished to queue_free
func play_positional_sound(audio: AudioStream, pos: Vector2, polyphony: int = 1, rand_pitch: bool = true, play_paused: bool = false, distance: float = 200.0) -> AudioStreamPlayer2D:
    if audio == null: return
    var player := AudioStreamPlayer2D.new()
    player.stream = audio
    var pitch: float = 1.0
    if rand_pitch:
        pitch = randf_range(0.9, 1.1)
    player.pitch_scale = pitch
    player.max_distance = distance
    player.global_position = pos
    player.max_polyphony = polyphony
    player.finished.connect(player.queue_free)
    positional_sounds.add_child(player)
    player.process_mode = Node.PROCESS_MODE_ALWAYS if play_paused else Node.PROCESS_MODE_PAUSABLE
    player.play()
    return player

## Creates an audio stream at pos (local to owner) & returns the player. Player connects finished to queue_free
func play_sound_follow_owner(audio: AudioStream, pos: Vector2, _owner: Node, polyphony: int = 1, rand_pitch: bool = true, play_paused: bool = false, distance: float = 200.0) -> AudioStreamPlayer2D:
    if audio == null: return
    var player = play_positional_sound(audio, pos, polyphony, rand_pitch, play_paused, distance)
    player.reparent(_owner, false)
    player.position = pos
    return player
