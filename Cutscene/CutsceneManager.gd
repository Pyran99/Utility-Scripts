extends Node
#AUTOLOAD

# create CutsceneBase animation player
# add cameras
# add objects that will be used in animations
# save as scene, use scene in triggers

## when the library begins playing
signal begin_animation_library
## when the library has finished
signal finished_animation_library
## when an animation begins
signal begin_animation(_name: String)
## when an animation has finished
signal finished_animation(_name: String)

# @export var current_animation_lib: AnimationLibrary
# @export var objects_scene: PackedScene
@export var is_autoplaying: bool = false

# var current_lib_name: String
var current_cutscene_scene: Node
var current_animation_player: AnimationPlayer
var ui: CanvasLayer

# @onready var anim_player: AnimationPlayer = $AnimationPlayer


func _enter_tree() -> void:
    add_to_group("cutscene_manager")


func _ready():
    for i in get_children():
        if i is AnimationPlayer:
            i.queue_free()
        elif i is CanvasLayer:
            ui = i
            i.hide()


func setup_cutscene(scene_objects: PackedScene) -> void:
    if scene_objects == null: return
    GameManager.player.disable_player()
    cleanup_current_cutscene()
    add_new_cutscene(scene_objects)
    if current_cutscene_scene is CutsceneBase:
        current_cutscene_scene.begin_cutscene()
    else:
        push_warning("Cutscene scene does not inherit from CutsceneBase")


func cleanup_current_cutscene() -> void:
    if current_cutscene_scene != null:
        remove_child(current_cutscene_scene)
        current_cutscene_scene.queue_free()
        current_animation_player = null


func add_new_cutscene(_scene: PackedScene) -> void:
    if _scene == null: return
    current_cutscene_scene = _scene.instantiate()
    add_child(current_cutscene_scene)
    if current_cutscene_scene is AnimationPlayer:
        current_animation_player = current_cutscene_scene
        # current_animation_player.animation_finished.connect(animation_finished)


func animation_begin(_name: StringName) -> void:
    print("animation begin: ", _name)
    begin_animation.emit(_name)
    ui.hide()


func animation_finished(_name: StringName) -> void:
    print("animation finished: ", _name)
    finished_animation.emit(_name)
    ui.show()


func cutscene_started() -> void:
    print("cutscene started")
    begin_animation_library.emit()


func cutscene_finished() -> void:
    print("cutscene finished")
    cleanup_current_cutscene()
    GameManager.player.enable_player()
    finished_animation_library.emit()
    ui.hide()
