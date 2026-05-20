@abstract
extends VBoxContainer
class_name MultiElement
## A wrapper node for multi elements.

@export var main_element: SettingsOption
@export var sub_elements: Array[SettingsOption]

var parent_section: SettingsSection

var current_value:
    get:
        return main_element.current_value


## Called to update the visibility of sub elements based on the main elements's current value.
@abstract
func _display_sub_elements() -> void


func _enter_tree() -> void:
    parent_section = owner
    parent_section.setting_changed.connect(update_element)
    parent_section.apply_changes_pressed.connect(apply_settings)
    parent_section.settings_menu.changes_discarded.connect(load_settings.bind(false))
    SettingsManager.retrieve_settings.connect(load_settings)
    init_main_element()
    init_sub_elements()


func init_main_element() -> void:
    var id: String = main_element.id
    main_element.is_multi_element = true
    main_element.parent_section = parent_section
    main_element.section = parent_section.id
    parent_section.option_elements[id] = main_element


## Used to initialize sub elements of the multi element.
func init_sub_elements() -> void:
    for element in sub_elements:
        element.is_multi_element = true
        element.is_sub_element = true
        element.parent_section = parent_section
        element.section = parent_section.id
        parent_section.option_elements[element.id] = element


## Called when settings are loaded to display the appropriate elements.
func load_settings(_apply_values: bool) -> void:
    _display_sub_elements.call_deferred()

## Called when the main element's value changes do display the appropriate elements.
func update_element(id: String) -> void:
    if id == main_element.id:
        _display_sub_elements.call_deferred()


## Called when the apply button is pressed.
func apply_settings() -> void:
    if parent_section.cached_changes.has(main_element.id):
        for sub in sub_elements:
            if (not sub.is_visible_in_tree() or parent_section.cached_changes.has(sub.id)): continue
            sub._apply_settings()
