extends Camera3D


var target: Node: set = _set_target


func _set_target(value: Node) -> void:
    target = value
    set_process(value != null)


func _ready():
    set_process(target != null)


func _process(_delta: float) -> void:
    look_at(target.global_position, Vector3.UP)


func set_target(node_path: NodePath) -> void:
    if node_path == NodePath(""):
        target = null
        return
    target = get_node(node_path)
