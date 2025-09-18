extends Button


func _ready():
    mouse_entered.connect(_on_mouse_entered)
    if disabled:
        focus_mode = Control.FOCUS_NONE


func _on_mouse_entered():
    if disabled:
        return
    grab_focus()
