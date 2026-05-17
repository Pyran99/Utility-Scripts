extends Control

signal keybinds_reset

@onready var confirm_btn: Button = %ConfirmBtn
@onready var cancel_btn: Button = %CancelBtn


func _ready() -> void:
    confirm_btn.pressed.connect(_on_confirm_pressed)
    cancel_btn.pressed.connect(_on_cancel_pressed)


func _on_confirm_pressed() -> void:
    KeybindManager.reset_keybinds()
    keybinds_reset.emit()
    queue_free()


func _on_cancel_pressed() -> void:
    queue_free()
