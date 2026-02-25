## Add to a scene for viewport screenshots
extends Node2D

@export var use_camera: bool = true

@onready var camera: Camera2D = $Camera2D


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("save_screenshot"):
        _save_screenshot()


func _save_screenshot() -> void:
    var time = Time.get_datetime_string_from_system().replace(":", "_")
    var file := "res://screenshot_{owner}_{time}.png".format({
        "owner": owner.name,
        "time": time
        })
    if use_camera:
        camera.enabled = true
        camera.make_current()
        await get_tree().process_frame
        queue_redraw()
        await get_tree().process_frame
    var image := get_viewport().get_texture().get_image()
    image.save_png(file)
    push_warning("Screenshot saved to: " + file)
    await get_tree().process_frame
    if use_camera:
        camera.enabled = false
