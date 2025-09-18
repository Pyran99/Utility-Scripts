extends HBoxContainer
class_name OptionContainer

# Set in editor if multiple of same type of nodes in children
@export_group("Nodes")
@export var option_button: Control
@export var label: Label

var select_arrow: TextureRect
var default_color: Color = Color.WHITE
var options_menu: OptionsMenu


func _ready():
    assert(option_button != null, "Option button not set on " + name)
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

        if label == null:
            if i is Label:
                label = i

    if label != null:
        default_color = label.modulate


func grab_btn_focus() -> void:
    if option_button == null:
        return
    option_button.grab_focus()
    if options_menu:
        options_menu.last_focus_item = option_button


func _on_mouse_entered():
    label.modulate = Color(0.49, 0.965, 1.0)
    select_arrow.show()
    grab_btn_focus()


func _on_mouse_exited():
    if option_button.has_focus():
        return

    label.modulate = default_color
    select_arrow.hide()
