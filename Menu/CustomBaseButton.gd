## A Button that will connect mouse & focus signals, play hover audio
extends Button
class_name CustomBaseButton

#const SFX_BTN_HOVER := preload("uid://cpbeu8b6g0prn")

@export var play_hover_sound: bool = true


func _ready():
    _connect_signals()
    if disabled:
        focus_mode = Control.FOCUS_NONE


func _connect_signals() -> void:
    if !mouse_entered.is_connected(_on_mouse_entered):
        mouse_entered.connect(_on_mouse_entered)
    if !mouse_exited.is_connected(_on_mouse_exited):
        mouse_exited.connect(_on_mouse_exited)
    if !focus_entered.is_connected(_on_focused_entered):
        focus_entered.connect(_on_focused_entered)
    if !focus_exited.is_connected(_on_focus_exited):
        focus_exited.connect(_on_focus_exited)


func _on_mouse_entered() -> void:
    if disabled:
        focus_mode = Control.FOCUS_NONE
        return
    focus_mode = Control.FOCUS_ALL
    get_viewport().gui_release_focus()
    if play_hover_sound:
        #GlobalAudioManager.play_ui_sound(SFX_BTN_HOVER)
        pass


func _on_mouse_exited() -> void:
    pass


func _on_focused_entered() -> void:
    pass


func _on_focus_exited() -> void:
    pass
