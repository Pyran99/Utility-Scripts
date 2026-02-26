@tool
@icon("res://icon.svg")
## Monitors for non mouse events to grab focus of an element. Add to any ui scene that would want a keyboard or controller input to grab focus
extends Control
class_name UIKeyInputManager

## The default control to grab focus if no last focused
@export var default_focus: Control: set = _set_default_focus
@export var save_last_focused: bool = true
## will grab focus on ready if monitored node is visible
@export var grab_focus_on_ready: bool = false
## Optional. Tries to grab focus when this node is visible
@export var monitored_visible: Node

var last_focused: Control

func _set_default_focus(value: Control) -> void:
    default_focus = value
    update_configuration_warnings()


func _ready() -> void:
    if Engine.is_editor_hint(): return
    ControllerIcons.input_type_changed.connect(_on_input_type_changed)
    get_viewport().gui_focus_changed.connect(_on_focus_changed)
    if monitored_visible != null:
        monitored_visible.visibility_changed.connect(_on_monitored_visibility_changed)
        _on_monitored_visibility_changed()
        if grab_focus_on_ready and monitored_visible.visible:
            _try_grab_focus.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
    if !event is InputEventKey: return
    if !is_visible_in_tree(): return
    if event.is_action_pressed("ui_cancel"): return
    if event.is_action_pressed("ui_manager_grab_focus"):
        if _try_grab_focus():
            get_viewport().set_input_as_handled()


func _try_grab_focus() -> bool:
    if get_viewport().gui_get_focus_owner() != null: return false
    if _grab_last_focused(): return true
    if default_focus == null: return false
    if !default_focus.is_visible_in_tree(): return false
    default_focus.grab_focus()
    return true


func _grab_last_focused() -> bool:
    if !save_last_focused: return false
    if last_focused == null: return false
    if !last_focused.is_visible_in_tree(): return false
    last_focused.grab_focus()
    return true


func _on_input_type_changed(type: ControllerIcons.InputType, controller: int) -> void:
    match type:
        ControllerIcons.InputType.CONTROLLER:
            _try_grab_focus()
    pass


func _on_focus_changed(node: Control) -> void:
    last_focused = node


func _on_monitored_visibility_changed() -> void:
    if !is_instance_valid(monitored_visible):
        push_warning("monitored_visible is invalid")
        return
    set_process_unhandled_key_input(monitored_visible.visible)
    if !monitored_visible.is_node_ready(): await monitored_visible.ready
    if monitored_visible.visible:
        _try_grab_focus()


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    if default_focus == null:
        warnings.append("default_focus is not set")
    return warnings
