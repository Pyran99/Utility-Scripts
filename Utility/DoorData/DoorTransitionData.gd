extends Resource
class_name DoorTransitionData

## The name of the door trigger area that was used to change scene. Set by door trigger area, then reset by doors_in_level.
@export var door_used: String:
    set(value):
        door_used = value
