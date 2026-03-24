extends CanvasLayer
class_name UIStackMenu
## Organized order of opened ui scenes
##[br][Node]'s added to [member ui_stack] wil be reopened in reverse order when closed

## Emits when the last element is removed
##[br]Connect to a method that resumes game if needed
signal last_element_removed

var ui_stack: Array = []
var stack_layer: int = 0

func _ready():
    stack_layer = layer
    for i: Node in get_children():
        if i is VBoxContainer: continue
        i.queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
    # if event.is_action_pressed("pause"):
    #     if ui_stack.size() == 0:
    #         _on_button_pressed()
    #     elif ui_stack.size() == 1:
    #         clear_all_stack(false)
    #     elif ui_stack.size() > 1:
    #         remove_last_stack()
    ## dictionary testing
    if event.is_action_pressed("pause"):
        if ui_stack_dictionary.size() == 0:
            _on_button_pressed()
        elif ui_stack_dictionary.size() == 1:
            clear_all_stack2(false)
        elif ui_stack_dictionary.size() > 1:
            remove_last_stack2()
    if event.is_action_pressed("debug1"):
        clear_all_stack(false)

## Disable the last node in the stack, then add the new [param node].
##[br][param reuse_existing] will use the node in the stack with the same [member Node.name] as [param node]
##[br]passed [param node] will be [method Node.queue_free] if existing is found in stack
func add_to_stack(node: Node, reuse_existing: bool = true) -> void:
    assert(node != null)
    if node.name == ui_stack.back().name:
        node.queue_free()
        return
    if reuse_existing:
        node = get_existing_stack_node(node)
    if ui_stack.size() > 0:
        var last: Node = ui_stack.back()
        last.hide()
        last.process_mode = Node.PROCESS_MODE_DISABLED
    ui_stack.append(node)
    if !node.is_inside_tree():
        add_child(node)
    else:
        move_child(node, get_child_count()) # assumes child of this node
    node.show()
    node.process_mode = Node.PROCESS_MODE_INHERIT

## Removes [param node] from stack if found
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

## Removes the last node in the stack, then shows the last-1
func remove_last_stack() -> void:
    if ui_stack.size() == 0: return
    var last: Node = ui_stack.pop_back()
    last.queue_free()
    if ui_stack.size() > 0:
        var next: Node = ui_stack.back()
        next.process_mode = Node.PROCESS_MODE_INHERIT
        next.show()
    else:
        last_element_removed.emit()

## Returns [param node] from stack if found using [member Node.name]
func get_existing_stack_node(node: Node) -> Node:
    if ui_stack.size() == 0: return node
    var idx: int = -1
    for i in ui_stack.size():
        if ui_stack[i].name == node.name:
            idx = i
            break
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
    # last_element_removed.emit()
    get_tree().paused = keep_paused


func _on_button_pressed() -> void:
    # var instance := load("uid://vffh7yskf0pe")
    # var pause_menu: Node = instance.instantiate()
    # add_to_stack(pause_menu)
    add_to_stack_by_uid("uid://vffh7yskf0pe")


func _on_button_2_pressed() -> void:
    # var instance := load("uid://b3jrki7voblnn")
    # var options: Node = instance.instantiate()
    # add_to_stack(options)
    add_to_stack_by_uid("uid://b3jrki7voblnn")


func _on_button_3_pressed() -> void:
    var instance := load("uid://c7asov2fdpexo")
    var other1: Node = instance.instantiate()
    add_to_stack(other1)


func _on_button_4_pressed() -> void:
    var instance := load("uid://cwmca4dhky72k")
    var other2: Node = instance.instantiate()
    add_to_stack(other2)

#region Dictionary style

##[{"uid": "uid://b3jrki7voblnn", "node": node}, {}]
var ui_stack_dictionary: Array[Dictionary] = []

##@experimental
##Instead of passing a packed scene
##[br]This likely needs a dictionary array stack
func add_to_stack_by_uid(uid: StringName, reuse_existing: bool = true) -> void:
    var node: Node = null
    for i in ui_stack_dictionary:
        if i["uid"] == uid:
            node = i["node"]
            print("existing")
            break
    if node == null:
        var instance := load(uid)
        node = instance.instantiate()
    add_to_stack_dictionary(uid, node, reuse_existing)


func add_to_stack_dictionary(uid: StringName, node: Node, reuse_existing: bool = true) -> void:
    assert(node != null)
    # if node.name == ui_stack_dictionary.back().name:
    #     node.queue_free()
    #     return
    # if reuse_existing:
    #     node = get_existing_stack_node(node)
    if ui_stack_dictionary.size() > 0:
        var last: Node = ui_stack_dictionary.back()["node"]
        last.hide()
        last.process_mode = Node.PROCESS_MODE_DISABLED
    if ui_stack_dictionary.has({"uid": uid, "node": node}):
        ui_stack_dictionary.erase({"uid": uid, "node": node})
    ui_stack_dictionary.append({"uid": uid, "node": node}) # FIXME
    if !node.is_inside_tree():
        add_child(node)
    else:
        move_child(node, get_child_count()) # assumes child of this node
    node.show()
    node.process_mode = Node.PROCESS_MODE_INHERIT


func remove_last_stack2() -> void:
    if ui_stack_dictionary.size() == 0: return
    var last: Node = ui_stack_dictionary.pop_back()["node"]
    last.queue_free()
    if ui_stack_dictionary.size() > 0:
        var next: Node = ui_stack_dictionary.back()["node"]
        next.process_mode = Node.PROCESS_MODE_INHERIT
        next.show()
    else:
        last_element_removed.emit()


func remove_from_stack2(node: Node) -> void:
    if ui_stack_dictionary.size() == 0: return
    var index: int = -1
    for i in range(ui_stack_dictionary.size()):
        if ui_stack_dictionary[i]["node"] == node:
            index = i
    print(index)
    if index == -1: return
    var _node: Node = ui_stack_dictionary.pop_at(index)["node"]
    if _node != null:
        _node.queue_free()


func clear_all_stack2(keep_paused: bool = false) -> void:
    var ui: Node
    for i in range(ui_stack_dictionary.size()):
        ui = ui_stack_dictionary.pop_back()["node"]
        if ui != null:
            ui.queue_free()
    # last_element_removed.emit()
    get_tree().paused = keep_paused

#endregion
