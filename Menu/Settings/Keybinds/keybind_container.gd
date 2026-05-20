extends HBoxContainer
class_name KeybindContainer


signal action_rebound(action: String, event: InputEvent, type: KeybindManager.InputType)

var menu: KeybindMenu
var action_name: String
var btns: Array[Button]

@onready var lbl: Label = $Label


func _ready() -> void:
    if menu == null:
        return
    lbl.text = action_name
    for i in get_children():
        if i is Button:
            btns.append(i)
            i.container = self
            i.action = action_name
            i.name = action_name
            if action_name == "move_up":
                if i.type == KeybindManager.InputType.CONTROLLER:
                    _set_gamepad_movement_name()
            i.rebound_action.connect(_on_button_rebound)
            i.rebind_mode_changed.connect(menu._on_rebind_mode_changed)
            menu.release_pressed_button.connect(i.release_pressed_button)


func _set_gamepad_movement_name() -> void:
    lbl.text = "movement"

## bounce button signal to menu
func _on_button_rebound(action: String, event: InputEvent, type: KeybindManager.InputType) -> void:
    action_rebound.emit(action, event, type)
