extends OptionElement


func _init() -> void:
    option_list = SettingsManager.LANGUAGES.duplicate(true)


func get_valid_values() -> Dictionary:
    if !option_list.has(default_value):
        push_error("Invalid default value for element '" + id + "'.")
        if option_list is Dictionary:
            default_value = option_list.keys().front()
        else:
            default_value = option_list[option_list.size() - 1]
    var _data: Dictionary = {
        "default_value": default_value,
        "valid_options": option_list
    }
    return _data


func add_option_items() -> void:
    var idx: int = 0
    var item_count: int = btn.item_count
    for key in option_list:
        if item_count == 0:
            (btn as OptionButton).add_icon_item(load(option_list[key]["flag"]), option_list[key]["language"])
        if key == current_value:
            btn.select(idx)
            selected_idx = idx
        idx += 1


# func _unhandled_key_input(event: InputEvent) -> void:
#     if event.is_action_pressed(&"translation_toggle_test"):
#         if OS.is_debug_build():
#             _cycle_translation()


func _cycle_translation() -> void:
    if !OS.is_debug_build(): return
    var current_locale := TranslationServer.get_locale()
    var current_idx: int = option_list.keys().find(current_locale)
    if current_idx == -1: return
    current_idx = (current_idx + 1) % option_list.size()
    var new_locale: String = option_list.keys()[current_idx]
    TranslationServer.set_locale(new_locale)
    btn.select(current_idx)
    _on_option_selected(current_idx)
    print("Locale changed to: ", new_locale)


func _on_option_selected(idx: int) -> void:
    if parent_section.settings_cache.size() == 0:
        printerr("Settings cache is empty for '" + section + "'")
        return
    var text: String = btn.get_item_text(idx)
    for i in option_list:
        if option_list[i]["language"] == text:
            text = i
            break
    parent_section.settings_changed(id, text)
    if update_immediately and parent_section.settings_menu.update_immediately:
        parent_section.apply_stored_changes()


func _get_locale_by_language(language: String) -> String:
    for i in option_list:
        if option_list[i]["language"] == language:
            return i
    return ""


func _get_language_by_locale(locale: String) -> String:
    return option_list[locale].get("language", "")


func _apply_settings() -> void:
    TranslationServer.set_locale(current_value)
    SettingsManager.language_changed.emit(current_value)
    parent_section.cache_setting(id, current_value)
