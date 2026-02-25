extends CharacterBody3D
# some initial setup for a player

const SPEED := 5.0
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 4.5
const SENSITIVITY_MOD: float = 0.001
const MIN_CAMERA_ROTATION: float = deg_to_rad(-70.0)
const MAX_CAMERA_ROTATION: float = deg_to_rad(70.0)

@export var camera_base: Node3D
@export var camera_rot: Node3D
@export var camera_sensitivity: float = 1.0
@export var interact_distance: float = 2.0
@export var light: SpotLight3D
@export var mesh_base: Node3D
@export var task_list: Control

var interact_result
var speed: float

@onready var interact_popup: HBoxContainer = %InteractPopupContainer
@onready var camera: Camera3D = %Camera3D
@onready var ui: CanvasLayer = %CanvasLayer


func _process(_delta: float) -> void:
    _interact_cast()


func _physics_process(delta: float) -> void:
    #_handle_gravity(delta)
    #_handle_jump()
    _handle_movement(delta)
    move_and_slide()


func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _handle_camera(event)


func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        _interact()
    #if event.is_action_pressed("light"):
        #toggle_light()
    if event.is_action_pressed("debug2"):
        GameManager.toggle_mouse_mode()



func disable_player() -> void:
    set_process(false)
    set_physics_process(false)
    set_process_input(false)
    set_process_unhandled_key_input(false)
    ui.hide()


func enable_player() -> void:
    show()
    set_process(true)
    set_physics_process(true)
    set_process_input(true)
    set_process_unhandled_key_input(true)
    camera.current = true
    ui.show()


func _handle_gravity(_delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * _delta


func _handle_jump() -> void:
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY


func _handle_movement(_delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction := (camera_base.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    #_handle_sprint()
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)


func _handle_camera(event: InputEventMouseMotion) -> void:
    if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_base.rotate_y(-event.relative.x * camera_sensitivity * SENSITIVITY_MOD)
        camera_base.orthonormalize()
        camera_rot.rotation.x = clampf(camera_rot.rotation.x - event.relative.y * (camera_sensitivity * SENSITIVITY_MOD), MIN_CAMERA_ROTATION, MAX_CAMERA_ROTATION)
        _handle_mesh_look()


func _handle_mesh_look() -> void:
    mesh_base.rotation.y = camera_base.rotation.y


func _interact() -> void:
    if interact_result == null: return
    if !interact_result.has_user_signal("interacted"): return
    interact_result.emit_signal("interacted")


func _interact_cast() -> void:
    var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
    var screen_center: Vector2i = get_viewport().get_visible_rect().size / 2.0
    var origin: Vector3 = camera.project_ray_origin(screen_center)
    var end: Vector3 = origin + camera.project_ray_normal(screen_center) * interact_distance
    var query = PhysicsRayQueryParameters3D.create(origin, end, 64)
    query.collide_with_bodies = true
    var result := space_state.intersect_ray(query)
    var current_result = result.get("collider")
    if current_result != interact_result:
        if interact_result != null and interact_result.has_user_signal("unfocused"):
            interact_result.emit_signal("unfocused")
            #interact_popup.hide()
        interact_result = current_result
        if interact_result != null and interact_result.has_user_signal("focused"):
            interact_result.emit_signal("focused")
            #interact_popup.show()
    if OS.is_debug_build():
        if Engine.get_process_frames() % 60 == 0:
            if current_result:
                end = result.get("position", end)
            _debug_sphere_at_pos(end, 1.0)


func _debug_sphere_at_pos(pos: Vector3, duration: float = 1.0) -> void:
    var n_mesh = MeshInstance3D.new()
    n_mesh.mesh = SphereMesh.new()
    n_mesh.scale = Vector3(0.25, 0.25, 0.25)
    get_tree().create_timer(duration).timeout.connect(n_mesh.queue_free)
    get_tree().current_scene.add_child(n_mesh)
    n_mesh.global_position = pos
