extends MultiElement


func _display_sub_elements() -> void:
    match current_value:
        "Disabled":
            for element in sub_elements:
                element.hide()
        "Bilinear":
            sub_elements[0].show() # scale
            sub_elements[1].hide() # mode
            sub_elements[2].hide() # sharpness
        "FSR 2.2":
            sub_elements[0].hide()
            sub_elements[1].show()
            sub_elements[2].show()
