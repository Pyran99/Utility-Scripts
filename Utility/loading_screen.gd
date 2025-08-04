extends CanvasLayer
class_name LoadingScreen


var debug_play: bool = false: set = _set_debug_play

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var text_anim_player: AnimationPlayer = $AnimationPlayer2
@onready var control: Control = $Control
@onready var text: RichTextLabel = $Control/RichTextLabel
@onready var progress_bar: ProgressBar = $Control/ProgressBar
# @onready var sprite: Sprite2D = $Sprite2D
# @onready var circle_loader: TextureProgressBar = $TextureProgressBar


func _set_debug_play(value: bool) -> void:
    debug_play = value
    if value:
        play_fade_to_black()
    else:
        play_fade_to_transparent()


func _ready():
    # tween = create_tween()
    control.hide()
    # sprite.hide()
    SceneManager.new_scene_loaded.connect(_new_scene_loaded)
    # var tween: Tween = create_tween().set_loops()
    # tween.tween_property(circle_loader, "radial_initial_angle", 360.0, 1.5).as_relative()


func _process(_delta: float) -> void:
    # sprite.global_position = Vector2(149, sprite.global_position.y) + Vector2(progress_bar.size.x * (progress_bar.value / progress_bar.max_value), 0)
    if !SceneManager.get("progress"):
        return
    var tween = create_tween()
    tween.tween_property(progress_bar, "value", SceneManager.progress[0] * 100, 0.1)


func _new_scene_loaded() -> void:
    pass


func repeat_move_text() -> void:
    text.position = Vector2(-352.0, 276.0)
    text_anim_player.play("move_text")


func play_fade_to_black():
    anim_player.play("fade_out")
    await anim_player.animation_finished
    text_anim_player.play("move_text")
    if !text_anim_player.animation_finished.is_connected(repeat_move_text):
        text_anim_player.animation_finished.connect(repeat_move_text.unbind(1))
    control.show()
    # sprite.show()
    

func play_fade_to_transparent():
    control.hide()
    # sprite.hide()
    anim_player.play_backwards("fade_out")
    await anim_player.animation_finished
