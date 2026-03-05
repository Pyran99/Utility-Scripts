@tool
extends AnimationPlayer
class_name CutsceneBase


@export var entry_delay: float = 0.0

var idx: int = -1
var total_animations: int

@export_group("Inspector")
@export_tool_button("Create Camera3D", "Camera3D")
@warning_ignore("unused_private_class_variable")
var _create_camera: Callable = _inspector_create_camera3d
@export_tool_button("Create AudioStreamPlayer", "AudioStreamPlayer")
@warning_ignore("unused_private_class_variable")
var _create_audio_player: Callable = _inspector_create_audio_player
@export var main_camera: Camera3D: set = _set_camera
@export var audio_player: AudioStreamPlayer


#region Inspector Functions

func _inspector_create_camera3d() -> void:
    if main_camera != null: return
    var undo_redo = EditorInterface.get_editor_undo_redo()
    undo_redo.create_action("Created Camera3D")
    var _camera = Camera3D.new()
    undo_redo.add_do_method(self , "_i_create_camera", _camera)
    undo_redo.add_undo_method(self , "_i_create_camera", null)
    undo_redo.add_do_reference(_camera)
    undo_redo.add_undo_reference(_camera)
    undo_redo.commit_action()


func _i_create_camera(camera: Camera3D) -> void:
    if camera == null:
        if main_camera != null:
            main_camera.queue_free()
        return
    add_child(camera)
    camera.owner = get_tree().edited_scene_root
    camera.name = "Camera3D"
    main_camera = camera


func _set_camera(value: Camera3D) -> void:
    main_camera = value
    update_configuration_warnings()


func _inspector_create_audio_player() -> void:
    if audio_player != null: return
    var undo_redo = EditorInterface.get_editor_undo_redo()
    undo_redo.create_action("Created AudioPlayer")
    var _audio_player = AudioStreamPlayer.new()
    undo_redo.add_do_method(self , "_i_create_audio_player", _audio_player)
    undo_redo.add_undo_method(self , "_i_create_audio_player", null)
    undo_redo.add_do_reference(_audio_player)
    undo_redo.add_undo_reference(_audio_player)
    undo_redo.commit_action()


func _i_create_audio_player(_player: AudioStreamPlayer) -> void:
    add_child(_player)
    _player.owner = get_tree().edited_scene_root
    _player.name = "AudioStreamPlayer"
    audio_player = _player


#endregion


func _enter_tree() -> void:
    add_to_group("cutscene")


func _ready() -> void:
    if Engine.is_editor_hint(): return
    total_animations = get_animation_list().size()
    animation_finished.connect(_on_animation_finished)
    CutsceneManager.autoplay.connect(_on_autoplay_timer_timeout)
    begin_cutscene.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _handle_animation_skip()


func begin_cutscene() -> void:
    if is_queued_for_deletion(): return
    print("anim list:\n>>", get_animation_list())
    if entry_delay > 0.0:
        await get_tree().create_timer(entry_delay).timeout
    play_next_animation()
    CutsceneManager.cutscene_started()


func play_next_animation() -> void:
    if is_playing():
        pause()
    idx += 1
    if idx >= total_animations:
        finished_cutscene()
        return
    var next = get_animation_list()[idx]
    if next == "RESET":
        play_next_animation()
        return
    play(next)
    CutsceneManager.animation_begin(next)


func finished_cutscene() -> void:
    CutsceneManager.cutscene_finished()


func reparent_node_by_unique_name(node: StringName, target: StringName, keep_transform: bool = false) -> void:
    var _node = get_node("%" + node)
    var _target = get_node("%" + target)
    _reparent_node_to_target(_node, _target, keep_transform)


func reparent_node_by_nodepath(node: NodePath, target: NodePath, keep_transform: bool = false) -> void:
    var _node = get_node(node)
    var _target = get_node(target)
    _reparent_node_to_target(_node, _target, keep_transform)


func reset_camera_parent() -> void:
    _reparent_node_to_target(main_camera, self )


func set_camera_look_target_path(target: NodePath) -> void:
    var _node = get_node(target)
    _set_camera_look_target(_node)


func set_camera_look_name(node: StringName) -> void:
    var _node = get_node("%" + node)
    _set_camera_look_target(_node)


func clear_camera_look_target() -> void:
    if main_camera.has_method("set_target"):
        main_camera.set_target(NodePath(""))
    else:
        printerr("Camera does not have set_target method")


func _reparent_node_to_target(node: Node, target: Node, keep_transform: bool = false) -> void:
    if node == null: return
    if target == null: return
    node.reparent(target, keep_transform)


func _set_camera_look_target(target: Node) -> void:
    if main_camera.has_method("set_target"):
        main_camera.target = target
    else:
        printerr("Camera does not have set_target method")


func _handle_animation_skip() -> void:
    if is_playing():
        if current_animation_position < 2.5:
            print("wait more: ", current_animation_position)
            return
    _on_animation_finished(current_animation)
    play_next_animation()


func _on_animation_finished(_name: StringName) -> void:
    CutsceneManager.animation_finished(_name)


func _on_autoplay_timer_timeout() -> void:
    if idx == total_animations - 1:
        print("final animation")
        return
    play_next_animation()


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray
    if main_camera == null:
        warnings.append("no Camera3D")
    return warnings


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        get_tree().paused = !get_tree().paused
