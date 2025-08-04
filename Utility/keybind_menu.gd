extends Control

#-------------------------
# Requires KeybindManager 
# Requires Utils          
# Requires KeybindButton  
# For new actions, dupe an hboxcontainer, set action, set default values to KeybindManager
#-------------------------


var previous_menu
var back_btn: Button

@onready var controls: VBoxContainer = %Controls
@onready var reset_btn: Button = %ResetBtn
@onready var reset_confirm: PanelContainer = %ResetConfirm
@onready var confirm_reset: Button = %ConfirmReset
@onready var cancel_reset: Button = %CancelReset
@onready var first_btn: Button = %PrimaryBtn


func _ready():
    reset_confirm.hide()
    reset_btn.pressed.connect(_on_reset_btn_pressed)
    confirm_reset.pressed.connect(confirm_reset_pressed)
    cancel_reset.pressed.connect(cancel_reset_pressed)
    # back_btn.pressed.connect(_on_back_btn_pressed)
    if %BackBtn:
        back_btn = %BackBtn
        back_btn.pressed.connect(_on_back_btn_pressed)


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if visible:
            _close_menu()


func _close_menu() -> void:
    hide()
    if previous_menu:
        previous_menu.show()


func _on_reset_btn_pressed() -> void:
    reset_confirm.show()
    cancel_reset.call_deferred("grab_focus")


func _on_back_btn_pressed() -> void:
    _close_menu()


func confirm_reset_pressed() -> void:
    KeybindManager.reset_keymap()
    var all_children = controls.find_children("*")
    # for item in Utils.get_all_children(controls):
    for item in all_children:
        if item is KeybindButton:
            item.display_current_key()
    reset_confirm.hide()
    reset_btn.call_deferred("grab_focus")
    pass


func cancel_reset_pressed() -> void:
    reset_confirm.hide()
    reset_btn.call_deferred("grab_focus")


func _on_visibility_changed() -> void:
    if visible:
        await get_tree().process_frame
        first_btn.call_deferred("grab_focus")
