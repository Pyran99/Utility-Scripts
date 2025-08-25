extends Node
#AUTOLOAD

#----------------------------DETAILS--------------------------------#
# Manager for changing game scenes                                  #
# Only need to call load_level with the path to the new scene       #
# set DEFAULT_LOAD_SCENE_PATH if you want to use a loading screen   #
# This will work when the game is launched from any scene           #
#-------------------------------------------------------------------#

signal loading_started
signal loading_finished
## sent when the new scene is finished loading from the thread, before being added
signal new_scene_loaded
## sent after _active_level is set
signal level_changed(new_level: Node)

## Default scene to load as a loading screen
const DEFAULT_LOAD_SCENE_PATH: String = "res://Utility/loading_screen.tscn"

@export var artificial_delay: float = 0.0 # to test loading progress bar

var _active_level: Node
var _active_load_scene: Node
var _load_scene: PackedScene
var _is_loading: bool = false
var new_scene_path: String = ""
var progress: Array = []
var loading_status: int = 0


func _ready():
    set_process(false)
    process_mode = Node.PROCESS_MODE_ALWAYS
    _load_loading_scene()
    _set_start_scene()


func _process(_delta: float) -> void:
    if !_is_loading:
        return
    loading_status = ResourceLoader.load_threaded_get_status(new_scene_path, progress)

    match loading_status:
        ResourceLoader.THREAD_LOAD_FAILED:
            _thread_load_resource_finished(loading_status)
        ResourceLoader.THREAD_LOAD_LOADED:
            _thread_load_resource_finished(loading_status)


func get_active_level() -> Node:
    return _active_level


func get_progress_value() -> float:
    if _is_loading:
        return progress[0]
    return 0

## Loads a scene from the given path. If path resource does not exist, will end the loading before the current level is unloaded. use_load_screen will spawn the default loading screen
func load_level(level_path: String, use_load_screen: bool = true) -> void:
    assert(!level_path.is_empty(), "level path is empty")
    if _is_loading:
        push_error("already loading: %s" % new_scene_path)
        return

    if !ResourceLoader.exists(level_path, "PackedScene"):
        push_error("level path does not exist: %s" % level_path)
        return

    _is_loading = true
    Engine.time_scale = 1
    loading_started.emit()
    handle_game_state(true)
    new_scene_path = level_path
    _start_loading(use_load_screen)


func handle_game_state(pause_game: bool) -> void:
    get_tree().paused = pause_game
    # If using GameManager to manage game state, call here
    # GameManager.handle_game_pause(pause_game)


func _thread_load_resource_finished(status: int) -> void:
    set_process(false)
    match status:
        ResourceLoader.THREAD_LOAD_FAILED:
            push_error("Failed to load level: %s" % new_scene_path)
            _finished_loading()
            return
        ResourceLoader.THREAD_LOAD_LOADED:
            new_scene_loaded.emit()
            if artificial_delay > 0.0:
                await get_tree().create_timer(artificial_delay).timeout
            var packed_scene = ResourceLoader.load_threaded_get(new_scene_path)
            _change_scene(packed_scene)

## sets load scene to default load scene
func _load_loading_scene() -> void:
    if DEFAULT_LOAD_SCENE_PATH.is_empty():
        return
    if ResourceLoader.exists(DEFAULT_LOAD_SCENE_PATH, "PackedScene"):
        _load_scene = load(DEFAULT_LOAD_SCENE_PATH)
    else:
        push_warning("Failed to load loading screen: %s" % DEFAULT_LOAD_SCENE_PATH)

## Create loading screen and start thread loading resource
func _start_loading(use_load_screen: bool) -> void:
    if use_load_screen:
        await _create_load_screen()
    
    ResourceLoader.load_threaded_request(new_scene_path)
    set_process(true)


func _create_load_screen() -> void:
    if _load_scene == null:
        push_warning("load scene is null")
        return
    _active_load_scene = _load_scene.instantiate()
    add_child(_active_load_scene)

    if _active_load_scene.has_method("play_fade_to_black"):
        await _active_load_scene.play_fade_to_black()

## change scene to packed
func _change_scene(packed_scene: PackedScene) -> void:
    if packed_scene == null:
        _finished_loading()
        return
    var tree := get_tree()
    tree.change_scene_to_packed(packed_scene)
    await tree.process_frame
    _set_active_level(tree.current_scene)
    _finished_loading()

## manually changing scene
# func _change_scene(packed_scene: PackedScene) -> void:
#     if packed_scene == null:
#         _finished_loading()
#         return
#     var tree := get_tree()
#     if is_instance_valid(_active_level):
#         _active_level.call_deferred("queue_free")
#         await tree.process_frame
#     tree.current_scene = null
#     var new_scene: Node = packed_scene.instantiate()
#     tree.root.add_child(new_scene)
#     tree.current_scene = new_scene
#     _set_active_level(new_scene)
#     _finished_loading()


func _finished_loading() -> void:
    new_scene_path = ""
    await _free_load_scene()
    _is_loading = false
    loading_status = 0
    loading_finished.emit()
    handle_game_state(false)


func _free_load_scene() -> void:
    if !is_instance_valid(_active_load_scene):
        return
    if _active_load_scene.has_method("play_fade_to_transparent"):
        await _active_load_scene.play_fade_to_transparent()

    _active_load_scene.queue_free()
    _active_load_scene = null

## Sets active level var and emits level changed
func _set_active_level(level: Node) -> void:
    if OS.is_debug_build():
        if is_instance_valid(_active_level):
            push_warning("Overwriting active level: %s" % _active_level.name)

    _active_level = level
    level_changed.emit(level)

## Sets any scene started from the editor as the active level. Needed if using active level to unload instead of change_scene_to_packed
func _set_start_scene() -> void:
    _set_active_level(get_tree().current_scene)
