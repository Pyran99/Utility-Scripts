extends Node
#AUTOLOAD

## when the library begins playing
signal begin_animation_library
## when the library has finished
signal finished_animation_library
## when an animation begins
signal begin_animation(_name: String)
## when an animation has finished
signal finished_animation(_name: String)
signal autoplay

@export var is_autoplaying: bool = false: set = _set_is_autoplaying
@export var autoplay_time: float = 2.0

var current_cutscene_scene: CutsceneBase: set = _set_current_cutscene
var ui: CanvasLayer
var autoplay_timer: Timer
var window_focus_click_intercept: Control


func _set_is_autoplaying(value: bool) -> void:
    is_autoplaying = value
    if !is_node_ready(): await ready
    if !is_autoplaying:
        autoplay_timer.stop()
        return
    if !is_cutscene_playing():
        autoplay.emit()


func _set_current_cutscene(value: CutsceneBase) -> void:
    current_cutscene_scene = value
    set_process_unhandled_key_input(current_cutscene_scene != null)


func _ready():
    SceneManager.level_changed.connect(_on_new_scene_loaded.unbind(1))
    _on_new_scene_loaded()
    window_focus_click_intercept = %Control
    ui = %CanvasLayer
    autoplay_timer = %AutoplayTimer
    autoplay_timer.one_shot = true
    autoplay_timer.timeout.connect(_on_autoplay_timer_timeout)
    set_process_unhandled_key_input(current_cutscene_scene != null)


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("debug1"):
        is_autoplaying = !is_autoplaying
    if event.is_action_pressed("pause"):
        if current_cutscene_scene != null:
            get_viewport().set_input_as_handled()


func setup_cutscene(cutscene_path: String) -> void:
    if !FileAccess.file_exists(cutscene_path):
        printerr("Cutscene does not exist: ", cutscene_path)
        return
    var cutscene = load(cutscene_path)
    GameManager.player.disable_player()
    _cleanup_current_cutscene()
    _add_new_cutscene(cutscene)


func animation_begin(_name: StringName) -> void:
    print("animation begin: ", _name)
    autoplay_timer.stop()
    begin_animation.emit(_name)
    ui.hide()


func animation_finished(_name: StringName) -> void:
    print("animation finished: ", _name)
    finished_animation.emit(_name)
    ui.show()
    if is_autoplaying:
        autoplay_timer.start(autoplay_time)


func cutscene_started() -> void:
    print("cutscene started")
    begin_animation_library.emit()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func cutscene_finished() -> void:
    print("cutscene finished")
    _cleanup_current_cutscene()
    GameManager.player.enable_player()
    finished_animation_library.emit()
    ui.hide()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_cutscene_playing() -> bool:
    if current_cutscene_scene == null: return false
    return current_cutscene_scene.is_playing()


func _cleanup_current_cutscene() -> void:
    if current_cutscene_scene == null: return
    var p = current_cutscene_scene.get_parent()
    if p:
        p.remove_child(current_cutscene_scene)
    current_cutscene_scene.queue_free()


func _add_new_cutscene(_scene: PackedScene) -> void:
    if _scene == null: return
    current_cutscene_scene = _scene.instantiate()
    get_tree().current_scene.add_child(current_cutscene_scene)


func _on_autoplay_timer_timeout() -> void:
    if is_autoplaying:
        autoplay.emit()

## Cleanup any existing cutscene nodes before they start playing
func _on_new_scene_loaded() -> void:
    for scene in get_tree().get_nodes_in_group("cutscene"):
        scene.queue_free()
        print("removed cutscene: ", scene)


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        window_focus_click_intercept.mouse_filter = Control.MOUSE_FILTER_STOP
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        await get_tree().process_frame
        window_focus_click_intercept.mouse_filter = Control.MOUSE_FILTER_IGNORE
