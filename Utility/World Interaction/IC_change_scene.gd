extends BaseInteractedAction


@export var minigame_name: String
@export var scene_to_load: PackedScene


func _on_interacted() -> void:
    print("loading: ", scene_to_load)
    if scene_to_load == null: return
    if GameManager.minigame_complete_states.get(minigame_name, false):
        print("already completed: ", minigame_name)
        return
    GameManager.save_level_data()
    SceneManager.change_scene(scene_to_load)
