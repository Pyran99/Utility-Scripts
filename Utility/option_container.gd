extends HBoxContainer

# Set in editor if multiple of same type of nodes in children
@export_group("Nodes")
## The option button
@export var option_button: Control
## The label to change color. If not set, will get first label. Not needed
@export var label: Label

var select_arrow: TextureRect
var default_color: Color = Color.WHITE


func _ready():
    assert(option_button != null)
    if option_button != null:
        option_button.mouse_entered.connect(_on_mouse_entered)
        option_button.mouse_exited.connect(_on_mouse_exited)
        option_button.focus_entered.connect(_on_mouse_entered)
        option_button.focus_exited.connect(_on_mouse_exited)

    for i in get_children():
        if select_arrow == null:
            if i is TextureRect:
                select_arrow = i
                select_arrow.hide()
                continue

        if label == null:
            if i is Label:
                label = i
                continue

    if label != null:
        default_color = label.modulate


func _on_mouse_entered():
    if label:
        label.modulate = Color.MEDIUM_PURPLE
    select_arrow.show()


func _on_mouse_exited():
    if option_button.has_focus():
        return
    if label:
        label.modulate = default_color
    select_arrow.hide()
