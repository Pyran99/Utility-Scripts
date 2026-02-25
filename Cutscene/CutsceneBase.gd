@tool
extends AnimationPlayer
class_name CutsceneBase
#TODO this functionality could be moved to the cutscene manager

# @export var entry_animation: String = ""
@export var entry_delay: float = 0.0

var idx: int = -1
var total_animations: int
var cutscene_manager: CutsceneManager
var autoplay_timer: Timer

@export_group("Inspector")
# @export_tool_button("Create AnimationPlayer", "AnimationPlayer")
# @warning_ignore("unused_private_class_variable")
# var _create_action: Callable = _inspector_create_animation_player
@export_tool_button("Create Camera3D", "Camera3D")
@warning_ignore("unused_private_class_variable")
var _create_camera: Callable = _inspector_create_camera3d
# @export var anim_player: AnimationPlayer: set = _set_anim_player
@export var main_camera: Camera3D: set = _set_camera


#region Inspector Functions
func _inspector_create_animation_player() -> void:
    # if anim_player != null: return
    var undo_redo = EditorInterface.get_editor_undo_redo()
    undo_redo.create_action("Created AnimationPlayer")
    var _anim_player = AnimationPlayer.new()
    undo_redo.add_do_method(self , "_inspector_create_player", _anim_player)
    undo_redo.add_undo_method(self , "_inspector_create_player", null)
    undo_redo.add_do_reference(_anim_player)
    undo_redo.add_undo_reference(_anim_player)
    undo_redo.commit_action()


func _inspector_create_player(player: AnimationPlayer) -> void:
    if player == null:
        # if anim_player != null:
        #     anim_player.queue_free()
        return
    add_child(player)
    player.owner = get_tree().edited_scene_root
    player.name = "AnimationPlayer"
    # anim_player = player


func _inspector_create_camera3d() -> void:
    if main_camera != null: return
    var undo_redo = EditorInterface.get_editor_undo_redo()
    undo_redo.create_action("Created Camera3D")
    var _camera = Camera3D.new()
    undo_redo.add_do_method(self , "_inspector_create_camera", _camera)
    undo_redo.add_undo_method(self , "_inspector_create_camera", null)
    undo_redo.add_do_reference(_camera)
    undo_redo.add_undo_reference(_camera)
    undo_redo.commit_action()


func _inspector_create_camera(camera: Camera3D) -> void:
    if camera == null:
        if main_camera != null:
            main_camera.queue_free()
        return
    add_child(camera)
    camera.owner = get_tree().edited_scene_root
    camera.name = "Camera3D"
    main_camera = camera

# func _set_anim_player(value: AnimationPlayer) -> void:
#     anim_player = value
#     update_configuration_warnings()


func _set_camera(value: Camera3D) -> void:
    main_camera = value
    update_configuration_warnings()
#endregion


func _ready() -> void:
    if Engine.is_editor_hint(): return
    cutscene_manager = get_tree().get_first_node_in_group("cutscene_manager")
    autoplay_timer = $AutoplayTimer
    print("anim list:\n>>", get_animation_list())
    total_animations = get_animation_list().size()
    animation_finished.connect(_on_animation_finished)
    autoplay_timer.timeout.connect(_on_autoplay_timer_timeout)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if is_playing():
                if current_animation_position < 2.0:
                    print("wait more: ", current_animation_position)
                    return
            play_next_animation()


func begin_cutscene() -> void:
    if entry_delay > 0.0:
        await get_tree().create_timer(entry_delay).timeout
    # play(entry_animation)
    play_next_animation()
    cutscene_manager.cutscene_started()


func play_next_animation() -> void:
    if is_playing():
        pause()
    idx += 1
    if idx >= total_animations:
        finished_cutscene()
        return
    var next = get_animation_list()[idx]
    print("next animation:\n>>", next)
    if next == "RESET":
        play_next_animation()
        return
    play(next)
    cutscene_manager.animation_begin(next)


func finished_cutscene() -> void:
    cutscene_manager.cutscene_finished()


func _on_animation_finished(_name: StringName) -> void:
    cutscene_manager.animation_finished(_name)
    if cutscene_manager.is_autoplaying:
        autoplay_timer.start()


func _on_autoplay_timer_timeout() -> void:
    play_next_animation()


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray
    # if == null:
    #     warnings.append("no AnimationPlayer")
    if main_camera == null:
        warnings.append("no Camera3D")
    return warnings
