extends OptionElement


func _init() -> void:
    option_list = {
        "Disabled": Viewport.SCALING_3D_MODE_BILINEAR,
        "Bilinear": Viewport.SCALING_3D_MODE_BILINEAR,
        "FSR 2.2": Viewport.SCALING_3D_MODE_FSR2,
    }


func _apply_settings() -> void:
    print("applied " + id + " with value: ", str(current_value))
    parent_section.cache_setting(id, current_value)
    get_viewport().set_scaling_3d_mode(option_list[current_value])
    if current_value == "Disabled":
        get_viewport().set_scaling_3d_scale(1.0)


func load_settings(apply_values: bool) -> void:
    super.load_settings(apply_values)
    _check_anti_aliasing.call_deferred()
    if ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
        for i in btn.item_count:
            if btn.get_item_text(i) == "FSR 2.2":
                btn.set_item_disabled(i, true)
                break


func _on_option_selected(idx: int) -> void:
    super._on_option_selected(idx)
    _check_anti_aliasing()


# Checks if TAA is selected while FSR 2.2 is enabled
func _check_anti_aliasing() -> void:
    if !parent_section.option_elements.has("ANTI_ALIASING"): return
    var aa_ref: SettingsOption = parent_section.option_elements["ANTI_ALIASING"]
    var taa_idx: int = aa_ref.option_list.find("TAA")
    if current_value != "FSR 2.2":
        aa_ref.btn.set_item_disabled(taa_idx, false)
        return
    aa_ref.btn.set_item_disabled(taa_idx, true)
    if aa_ref.current_value == "TAA":
        var disabled_index: int = aa_ref.option_list.find("Disabled")
        # Reselect the anti aliasing mode
        aa_ref.current_value = "Disabled"
        aa_ref.btn.select(disabled_index)
        aa_ref._apply_settings()
