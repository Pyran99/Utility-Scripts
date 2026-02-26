extends HBoxContainer
class_name OptionContainer

# Set in editor if multiple of same type of nodes in children
@export_group("Nodes")
@export var option_button: Control
@export var label: Label

var select_arrow: TextureRect
var default_color: Color = Color(0.418, 0.418, 0.418, 1.0)
var focused_color: Color = Color.WHITE
var options_menu: OptionsMenu


func _ready():
    assert(option_button != null, "Option button not set on " + name)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    if option_button != null:
        option_button.mouse_entered.connect(_on_mouse_entered)
        option_button.mouse_exited.connect(_on_mouse_exited)
        option_button.focus_entered.connect(_on_focus_entered)
        option_button.focus_exited.connect(_on_focus_exited)

    if label == null:
        for i in get_children():
            if i is Label:
                label = i
                break

    if label != null:
        label.modulate = default_color


func grab_btn_focus() -> void:
    if option_button == null: return
    option_button.grab_focus()
    if options_menu:
        options_menu.last_focus_item = option_button


func _on_mouse_entered():
    if option_button.has_focus(): return
    label.modulate = focused_color
    grab_btn_focus()


func _on_mouse_exited():
    if option_button.has_focus(): return
    label.modulate = default_color


func _on_focus_entered() -> void:
    label.modulate = focused_color


func _on_focus_exited() -> void:
    label.modulate = default_color
