## @experimental
## testing keybind options
extends Resource
class_name Keybinds


@export var keyboard_pool: Array[InputEventKey]
@export var controller_pool: Array[InputEventAction]
@export var controller_btns: Array[InputEventJoypadButton]
@export var controller_motion: Array[InputEventJoypadMotion]
