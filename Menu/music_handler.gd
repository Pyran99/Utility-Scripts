## Add to levels to change music on ready
extends Node
class_name MusicHandler


@export var music_id: GlobalAudioPlayer.LevelMusicID


func _ready():
    GlobalAudioPlayer.switch_music_by_id(music_id)
