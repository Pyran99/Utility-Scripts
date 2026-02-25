extends Node
class_name InteractComponent
# add as child of objects collision, player raycast calls user signals on collider

const MAT_HIGHLIGHT = preload("res://Utility/World Interaction/mat_highlight.tres")

@export var world_text: Label3D
@export var meshes: Array[MeshInstance3D]

var parent: Node


func _ready() -> void:
    parent = get_parent()
    _create_signals()


func _create_signals() -> void:
    parent.add_user_signal("focused")
    parent.add_user_signal("unfocused")
    parent.add_user_signal("interacted")
    parent.connect("focused", Callable(self , "_on_focused"))
    parent.connect("unfocused", Callable(self , "_on_unfocused"))
    parent.connect("interacted", Callable(self , "_on_interacted"))


func _on_focused() -> void:
    if meshes.size() == 0: return
    for mesh in meshes:
        mesh.material_overlay = MAT_HIGHLIGHT
    if world_text != null:
        world_text.show()


func _on_unfocused() -> void:
    if meshes.size() == 0: return
    for mesh in meshes:
        mesh.material_overlay = null
    if world_text != null:
        world_text.hide()


func _on_interacted() -> void:
    print("interacted: ", parent.name)
    pass
