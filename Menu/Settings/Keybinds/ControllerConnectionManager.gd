extends RefCounted
class_name ControllerConnectionManager


enum ControlType {
    KEYBOARD,
    CONTROLLER,
}
@warning_ignore("unused_signal")
signal control_type_changed(type: ControlType, device_id: int)

static var instance: ControllerConnectionManager
var control_type: ControlType = ControlType.KEYBOARD
var current_device: int = -1
var change_on_connected: bool = false


func _init() -> void:
    if instance == null:
        instance = self
        Input.joy_connection_changed.connect(_on_joy_connection_changed)
        return
    push_warning("ControllerConnectionManager is already initialized")


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
    var info := Input.get_joy_info(device_id)
    print("connected device %s: %d" % [info["raw_name"], device_id])
    print(Input.get_joy_info(device_id))
    if change_on_connected:
        if connected:
            change_control_type_to(ControlType.CONTROLLER)
            current_device = device_id
        else:
            change_control_type_to(ControlType.KEYBOARD)
            current_device = -1


func is_control_type(type: ControlType) -> bool:
    return control_type == type


func change_control_type_to(type: ControlType) -> void:
    if Input.get_connected_joypads().is_empty() and type == ControlType.CONTROLLER:
        print("No controllers connected, defaulting to keyboard")
        current_device = -1
        type = ControlType.KEYBOARD
    control_type = type
    control_type_changed.emit(control_type, current_device)
