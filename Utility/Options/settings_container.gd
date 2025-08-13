extends VBoxContainer


var focused: Control = null


func _ready():
    for i in get_children():
        if i is HBoxContainer:
            if i.option_button != null:
                i.option_button.mouse_entered.connect(_on_mouse_entered.bind(i))
                i.option_button.focus_entered.connect(_on_mouse_entered.bind(i))


func _on_mouse_entered(node: Control):
    if focused != null and focused != node:
        focused.option_button.release_focus()

    focused = node
