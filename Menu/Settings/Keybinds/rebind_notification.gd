extends Control


var tween: Tween

@onready var lbl: Label = %Label


func _ready() -> void:
    reset_tween()


func set_text(text: String) -> void:
    lbl.text = text


func fade_out(value: float) -> void:
    modulate.a = value


func reset_tween() -> void:
    if tween:
        tween.kill()
    modulate.a = 1.0
    tween = create_tween()
    tween.tween_method(fade_out, 1.0, 0.0, 0.5).set_delay(1.0)
    tween.finished.connect(queue_free)
