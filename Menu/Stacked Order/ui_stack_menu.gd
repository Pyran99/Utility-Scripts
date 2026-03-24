extends CanvasLayer


var ui_stack: Array = []
var stack_layer: int = 0


func _ready():
    stack_layer = layer
    for i: Node in get_children():
        if i is VBoxContainer: continue
        i.queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if ui_stack.size() == 0:
            _on_button_pressed()
        elif ui_stack.size() == 1:
            clear_all_stack(false)
        elif ui_stack.size() > 1:
            remove_last_stack()
    if event.is_action_pressed("debug1"):
        clear_all_stack(false)

## 
func add_to_stack(node: Node, use_existing: bool = true) -> void:
    assert(node != null)
    if use_existing:
        node = get_existing_stack_node(node)
    if ui_stack.size() > 0:
        var last = ui_stack.back()
        last.hide()
        last.process_mode = Node.PROCESS_MODE_DISABLED
    ui_stack.append(node)
    if !node.is_inside_tree():
        add_child(node)
    else:
        move_child(node, get_child_count() - 1) # assumes child of this node
    node.show()
    node.process_mode = Node.PROCESS_MODE_INHERIT


func remove_from_stack(node: Node) -> void:
    if ui_stack.size() == 0: return
    if node == ui_stack.back():
        remove_last_stack()
        return
    var index := ui_stack.find(node)
    if index == -1: return
    var _node: Node = ui_stack.pop_at(index)
    if _node != null:
        _node.queue_free()


func remove_last_stack() -> void:
    if ui_stack.size() == 0: return
    var last: Node = ui_stack.pop_back()
    last.queue_free()
    if ui_stack.size() > 0:
        var next: Node = ui_stack.back()
        next.process_mode = Node.PROCESS_MODE_INHERIT
        next.show()


func get_existing_stack_node(node: Node) -> Node:
    if ui_stack.size() == 0: return node
    var idx := ui_stack.find(node) # FIXME
    if idx == -1: return node
    node.queue_free()
    var _node: Node = ui_stack.pop_at(idx)
    remove_child(_node)
    return _node


func clear_all_stack(keep_paused: bool = false) -> void:
    var ui: Node
    for i in range(ui_stack.size()):
        ui = ui_stack.pop_back()
        if ui != null:
            ui.queue_free()
    get_tree().paused = keep_paused


func _on_button_pressed() -> void:
    var instance := load("uid://vffh7yskf0pe")
    var pause_menu: Node = instance.instantiate()
    add_to_stack(pause_menu)


func _on_button_2_pressed() -> void:
    var instance := load("uid://b3jrki7voblnn")
    var options: Node = instance.instantiate()
    add_to_stack(options)


func _on_button_3_pressed() -> void:
    var instance := load("uid://c7asov2fdpexo")
    var other1: Node = instance.instantiate()
    add_to_stack(other1)


func _on_button_4_pressed() -> void:
    var instance := load("uid://cwmca4dhky72k")
    var other2: Node = instance.instantiate()
    add_to_stack(other2, false)
