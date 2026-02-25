@abstract
extends Node
class_name BaseInteractedAction


var parent

func _ready():
    parent = get_parent()
    if !parent.is_node_ready(): await parent.ready
    if !parent.has_user_signal("interacted"): return
    parent.connect("interacted", Callable(self , "_on_interacted"))


@abstract
func _on_interacted() -> void
