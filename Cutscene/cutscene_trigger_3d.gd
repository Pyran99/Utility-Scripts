extends Area3D


@export var has_played: bool = false: set = _set_has_played
@export_file("*.tscn") var cutscene_path: String

@onready var col_shape: CollisionShape3D = $CollisionShape3D


func _set_has_played(value: bool) -> void:
    has_played = value
    if has_played:
        _disable_collision()
    else:
        _enable_collision()


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    if has_played:
        _disable_collision()


func _enable_collision() -> void:
    col_shape.set_deferred("disabled", false)


func _disable_collision() -> void:
    col_shape.set_deferred("disabled", true)


func _add_cutscene() -> void:
    CutsceneManager.setup_cutscene(cutscene_path)


func _on_body_entered(_body: Node3D) -> void:
    if has_played: return
    has_played = true
    _add_cutscene()
