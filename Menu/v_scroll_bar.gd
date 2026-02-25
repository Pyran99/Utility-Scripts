@tool
## A separate scroll bar for nodes with a internal vertical scroll bar
extends VScrollBar


@export var always_visible: bool = false
## Allows scrolling with mouse wheel anywhere while visible
@export var always_scrollable: bool = false
@export var scroll_bar_owner: Control: set = set_scroll_bar_owner

var bar: VScrollBar
var scroll_value: int = 30


func set_scroll_bar_owner(_value: Control) -> void:
    scroll_bar_owner = _value
    update_configuration_warnings()


func _ready():
    if Engine.is_editor_hint(): return
    if scroll_bar_owner == null: return
    if !scroll_bar_owner.has_method("get_v_scroll_bar"): return
    if !value_changed.is_connected(_on_value_changed):
        value_changed.connect(_on_value_changed)
    setup.call_deferred()
    update_properties.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if !visible: return
        if !always_scrollable: return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            bar.value -= scroll_value
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            bar.value += scroll_value


func setup() -> void:
    bar = scroll_bar_owner.get_v_scroll_bar()
    bar.hide()
    bar.value_changed.connect(_on_value_changed)
    if scroll_bar_owner is RichTextLabel:
        scroll_bar_owner.finished.connect(_on_rich_label_finished)


func update_properties() -> void:
    await get_tree().process_frame # some nodes may need to wait for draw call
    max_value = bar.max_value
    value = bar.value
    page = bar.page
    var _step = page * 0.7
    custom_step = _step
    if !always_visible:
        visible = max_value > page


func _on_value_changed(_value: float) -> void:
    value = _value
    if scroll_bar_owner is ScrollContainer:
        scroll_bar_owner.scroll_vertical = _value
    else:
        bar.value = _value


func _on_rich_label_finished() -> void:
    update_properties.call_deferred()


func _on_visibility_changed() -> void:
    if visible and bar:
        update_properties.call_deferred()


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    if !scroll_bar_owner:
        warnings.append("Missing Scroll Container")
    else:
        if !scroll_bar_owner.has_method("get_v_scroll_bar"):
            warnings.append("The assigned owner is not a node with a vertical scroll bar")
    return warnings
