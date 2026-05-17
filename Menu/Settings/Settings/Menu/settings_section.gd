extends VBoxContainer
class_name SettingsSection
##A container for each [SettingsOption]
##
##[member id] is used as the keys for [member SettingsManager.settings_data]

@warning_ignore("unused_signal")
signal apply_changes_pressed
signal setting_changed(id: String) ## update multi element displays

@export var id: String

var settings_menu: SettingsMenu
## each SettingsOption in this section
var option_elements: Dictionary
## copy of settings for this section
var settings_cache: Dictionary

var cached_changes: Dictionary = {}


func _enter_tree() -> void:
    settings_menu = owner


func _ready() -> void:
    settings_menu.settings_menu_opened.connect(_load_settings)
    settings_menu.settings_menu_closed.connect(clear_cache)
    apply_changes_pressed.connect(apply_stored_changes)
    SettingsManager.sections_ref[id] = self
    _initialize_manager_section_data()
    if settings_cache.is_empty():
        _load_settings.call_deferred()

# if btn to apply, connect signal; else call manually at some point
func update_saved_settings() -> void:
    SettingsManager.update_setting_section(id, settings_cache.duplicate(true))


func store_changed_setting(_element_id: String, value: Variant) -> void:
    cached_changes[_element_id] = value


func cache_setting(_element_id: String, value: Variant) -> void:
    settings_cache[_element_id] = value


func clear_cache() -> void:
    if get_tree().current_scene == settings_menu: return
    settings_cache.clear()


func clear_changes() -> void:
    cached_changes.clear()


## Called when a setting has been changed.
func settings_changed(_element_id: String, value: Variant = null) -> void:
    var changed: bool = check_for_changes(_element_id, value)
    settings_menu.apply_btn.set_disabled(changed)
    emit_signal("setting_changed", _element_id)

## true if no changes left
func check_for_changes(_element_id: String, value: Variant = null) -> bool:
    var saved_value: Variant = settings_cache[_element_id]
    if value == saved_value:
        if cached_changes.has(_element_id):
            cached_changes.erase(_element_id)
            SettingsManager.changed_elements_count -= 1
    elif !cached_changes.has(_element_id):
        store_changed_setting(_element_id, value)
        SettingsManager.changed_elements_count += 1
    elif cached_changes.has(_element_id):
        store_changed_setting(_element_id, value)

    if SettingsManager.changed_elements_count == 0:
        return true
    return false


func apply_stored_changes() -> void:
    if cached_changes.size() == 0: return
    var changes := cached_changes.duplicate(true)
    for key in changes:
        if option_elements.has(key):
            if option_elements[key].is_sub_element: continue
            option_elements[key].current_value = cached_changes[key]
            option_elements[key]._apply_settings()
    remove_all_changes()
    if settings_cache.hash() != SettingsManager.settings_data[id].hash():
        update_saved_settings()
        SettingsManager.save_settings.call_deferred()
    cached_changes.clear()


func remove_all_changes() -> void:
    SettingsManager.changed_elements_count -= cached_changes.size()
    if SettingsManager.changed_elements_count < 0:
        printerr("SettingsManager.changed_elements_count < 0")
    cached_changes.clear()
    if SettingsManager.changed_elements_count == 0:
        settings_menu.apply_btn.set_disabled(true)


func discard_changes() -> void:
    cached_changes.clear()


func _load_settings() -> void:
    settings_cache = SettingsManager.settings_data[id].duplicate(true)
    print("loading section: ", id, " with data:\n", settings_cache, "\n")
    if SettingsManager.no_save_file or SettingsManager.invalid_save_file:
        SettingsManager.save_settings.call_deferred()
    cached_changes.clear()


func _initialize_manager_section_data() -> void:
    if !SettingsManager.settings_data.has(id):
        SettingsManager.update_setting_section(id, {})
    elif SettingsManager.no_save_file:
        SettingsManager.update_setting_section(id, {})
