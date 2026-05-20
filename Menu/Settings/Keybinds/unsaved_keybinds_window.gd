extends Control


var menu: KeybindMenu = null

@onready var apply_btn: Button = %ApplyBtn
@onready var discard_btn: Button = %DiscardBtn
@onready var cancel_btn: Button = %CancelBtn


func _ready() -> void:
    assert(menu != null)
    apply_btn.pressed.connect(_on_apply_pressed)
    discard_btn.pressed.connect(_on_discard_pressed)
    cancel_btn.pressed.connect(_on_cancel_pressed)
    apply_btn.grab_focus.call_deferred()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        _on_cancel_pressed()


func _on_apply_pressed() -> void:
    menu._on_apply_pressed()
    menu._on_back_pressed()


func _on_discard_pressed() -> void:
    menu._on_discard_pressed()
    menu._on_back_pressed()


func _on_cancel_pressed() -> void:
    queue_free()
