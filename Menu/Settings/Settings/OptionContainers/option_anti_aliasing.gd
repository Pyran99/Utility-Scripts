extends OptionElement


func _init() -> void:
    option_list = [
        "Disabled",
        "FXAA",
        "2x MSAA",
        "4x MSAA",
        "8x MSAA",
		"TAA"
    ]


func _apply_settings() -> void:
    match current_value:
        "Disabled":
            set_anti_aliasing_mode()
        "FXAA":
            set_anti_aliasing_mode(Viewport.SCREEN_SPACE_AA_FXAA)
        "2x MSAA":
            set_anti_aliasing_mode(
                Viewport.SCREEN_SPACE_AA_DISABLED,
                Viewport.MSAA_2X
            )
        "4x MSAA":
            set_anti_aliasing_mode(
                Viewport.SCREEN_SPACE_AA_DISABLED,
                Viewport.MSAA_4X
            )
        "8x MSAA":
            set_anti_aliasing_mode(
                Viewport.SCREEN_SPACE_AA_DISABLED,
                Viewport.MSAA_8X
            )
        "TAA":
            set_anti_aliasing_mode(
                Viewport.SCREEN_SPACE_AA_DISABLED,
                Viewport.MSAA_DISABLED, true
            )


func set_anti_aliasing_mode(fxa_mode: Viewport.ScreenSpaceAA = Viewport.SCREEN_SPACE_AA_DISABLED, msaa_mode: Viewport.MSAA = Viewport.MSAA_DISABLED, taa_mode: bool = false) -> void:
    var viewport := get_viewport()
    viewport.screen_space_aa = fxa_mode
    viewport.msaa_2d = msaa_mode
    viewport.use_taa = taa_mode
    # viewport.msaa_3d = msaa_mode
    print_debug("set aa to: " + str(fxa_mode) + " | " + str(msaa_mode) + " | " + str(taa_mode))
