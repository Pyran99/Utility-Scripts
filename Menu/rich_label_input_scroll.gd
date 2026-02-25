## Enables key inputs for scrolling through process
extends RichTextLabel


var bar: VScrollBar


func _enter_tree() -> void:
    finished.connect(_on_finished)


func _ready():
    set_process(false)
    bar = get_v_scroll_bar()


func _process(delta):
    if Input.is_action_pressed("move_down"):
        bar.value += 3
    elif Input.is_action_pressed("move_up"):
        bar.value -= 3


func _on_finished() -> void:
    set_process(bar.max_value > bar.page)
