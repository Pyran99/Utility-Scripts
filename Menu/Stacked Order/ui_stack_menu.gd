extends CanvasLayer
class_name UIStackMenu
## Creates an in order list of opened ui scenes
##
##Usage: Add new UI menu's with [method add_to_stack] or [method add_to_stack_by_uid] to create an ordered list of scenes. Close or Back buttons in a scene should be connected to [method remove_last_stack] or [method remove_last_stack_dictionary].
##[br]New scenes added will cause the previous scene in the stack to be hidden & process disabled.
##[br]Node's added to [member ui_stack] or [member ui_stack_dictionary] wil be reopened in reverse order when closed, with the currently opened scene being freed.
##[br]The default usage uses an instantiated scene to check for that scene already in the stack, this may cause problems or performance hits if the instantiated scene has setups with [method Node._init].
##[br]The UID usage would keep track of scenes by their UID to check before instantiation.


## Emits when the last element is removed
##[br]Connect to a method that resumes game if needed
signal last_element_removed

var ui_stack: Array = []
##@experimental
## This could be setup to change the layer order of nodes
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
        clear_all_stack_dictionary(false)

## Toggle processing for this node. If this script handles opening a pause menu it should not process in a main menu
func set_processing(do_processing: bool) -> void:
    if do_processing:
        process_mode = Node.PROCESS_MODE_ALWAYS
    else:
        process_mode = Node.PROCESS_MODE_DISABLED


## Disable the last node in the stack, then add the new [param node].
##[br][param reuse_existing] will use the node in the stack with the same [member Node.name] as [param node]
##[br]passed [param node] will be [method Node.queue_free] if existing is found in stack
func add_to_stack(node: Node, reuse_existing: bool = true) -> void:
    assert(node != null)
    if reuse_existing:
        node = get_existing_stack_node(node)
    if ui_stack.size() > 0:
        if node.name == ui_stack.back().name:
            node.queue_free()
            return
        var last: Node = ui_stack.back()
        _disable_node(last)
    ui_stack.append(node)
    _add_or_move_node_in_tree(node)
    _enable_node(node)

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
##[br]If the last node in stack is removed, emits [signal last_element_removed]
func remove_last_stack() -> void:
    if ui_stack.size() == 0: return
    var last: Node = ui_stack.pop_back()
    last.queue_free()
    if ui_stack.size() > 0:
        var next: Node = ui_stack.back()
        _enable_node(next)
    else:
        last_element_removed.emit()

## Returns existing node from stack if found using [member Node.name]. Passed [param node] will be [method Node.queue_free]. The new node will be removed from the stack & removed from the scene tree then returned. Otherwise returns [param node]
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

## Removes & frees all elements in [member ui_stack]
func clear_all_stack(keep_paused: bool = false) -> void:
    var ui: Node
    for i in range(ui_stack.size()):
        ui = ui_stack.pop_back()
        if ui != null:
            ui.queue_free()
    last_element_removed.emit()
    get_tree().paused = keep_paused

## Assumes nodes are added as child of this node
func _add_or_move_node_in_tree(node: Node) -> void:
    if !node.is_inside_tree():
        add_child(node)
    else:
        move_child(node, get_child_count())


func _enable_node(node: Node) -> void:
    node.show()
    node.process_mode = Node.PROCESS_MODE_INHERIT


func _disable_node(node: Node) -> void:
    node.hide()
    node.process_mode = Node.PROCESS_MODE_DISABLED


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


#region Dictionary system

##[{"uid": "uid://b3jrki7voblnn", "node": node}, ...]
var ui_stack_dictionary: Array[Dictionary] = []


## Used for a stack that is handled by the unique UID for scenes. This would avoid needing to [method PackedScene.instantiate] a scene before checking if it already exists in the stack.
##[br]If the UID is not found, it will be loaded & instantiated
func add_to_stack_by_uid(uid: StringName) -> void:
    var node: Node = null
    for i in ui_stack_dictionary:
        if i["uid"] == uid:
            node = i["node"]
            break
    if node == null:
        var instance := load(uid)
        node = instance.instantiate()
    add_to_stack_dictionary(uid, node)


func add_to_stack_dictionary(uid: StringName, node: Node) -> void:
    assert(node != null)
    if ui_stack_dictionary.size() > 0:
        var last: Node = ui_stack_dictionary.back()["node"]
        _disable_node(last)
    if ui_stack_dictionary.has({"uid": uid, "node": node}):
        ui_stack_dictionary.erase({"uid": uid, "node": node})
    ui_stack_dictionary.append({"uid": uid, "node": node})
    _add_or_move_node_in_tree(node)
    _enable_node(node)


func remove_last_stack_dictionary() -> void:
    if ui_stack_dictionary.size() == 0: return
    var last: Node = ui_stack_dictionary.pop_back()["node"]
    last.queue_free()
    if ui_stack_dictionary.size() > 0:
        var next: Node = ui_stack_dictionary.back()["node"]
        _enable_node(next)
    else:
        last_element_removed.emit()


func remove_from_stack_dictionary(node: Node) -> void:
    if ui_stack_dictionary.size() == 0: return
    var index: int = -1
    for i in range(ui_stack_dictionary.size()):
        if ui_stack_dictionary[i]["node"] == node:
            index = i
    if index == -1: return
    var _node: Node = ui_stack_dictionary.pop_at(index)["node"]
    if _node != null:
        _node.queue_free()

## Removes & frees all elements in [member ui_stack_dictionary]
func clear_all_stack_dictionary(keep_paused: bool = false) -> void:
    var ui: Node
    for i in range(ui_stack_dictionary.size()):
        ui = ui_stack_dictionary.pop_back()["node"]
        if ui != null:
            ui.queue_free()
    last_element_removed.emit()
    get_tree().paused = keep_paused

#endregion
