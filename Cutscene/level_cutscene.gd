extends Node3D


func _ready() -> void:
    GameManager.change_level_state(GameManager.LevelStates.GAME)
