extends CharacterBody3D

const SPEED := 7.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002
var health := 100
var ammo := 30
var reserve_ammo := 120
var reloading := false
var camera: Camera3D
var ray: RayCast3D
var fire_timer := 0.0

func _ready() -> void:
    add_to_group("player")
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    collider.shape = capsule
    add_child(collider)
    camera = Camera3D.new()
    camera.position = Vector3(0, 0.55, 0)
    camera.current = true
    add_child(camera)
    ray = RayCast3D.new()
    ray.target_position = Vector3(0, 0, -100)
    ray.enabled = true
    camera.add_child(ray)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            fire()
    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        reload_weapon()

func _physics_process(delta: float) -> void:
    fire_timer = maxf(0.0, fire_timer - delta)
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
        velocity.y = JUMP_VELOCITY
    var input_dir := Vector2(
        float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
        float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
    ).normalized()
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * SPEED
    velocity.z = direction.z * SPEED
    move_and_slide()

func fire() -> void:
    if fire_timer > 0.12 or reloading or ammo <= 0:
        if ammo <= 0: reload_weapon()
        return
    fire_timer = 0.18
    ammo -= 1
    ray.force_raycast_update()
    if ray.is_colliding():
        var target = ray.get_collider()
        if target and target.has_method("take_damage"):
            target.take_damage(34)
    var root = get_tree().current_scene
    if root.has_method("_update_hud"): root._update_hud()

func reload_weapon() -> void:
    if reloading or ammo >= 30 or reserve_ammo <= 0: return
    reloading = true
    await get_tree().create_timer(1.3).timeout
    var needed := 30 - ammo
    var loaded := mini(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded
    reloading = false
    var root = get_tree().current_scene
    if root.has_method("_update_hud"): root._update_hud()

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    var root = get_tree().current_scene
    if root.has_method("_update_hud"): root._update_hud()
    if health <= 0:
        health = 100
        ammo = 30
        reserve_ammo = 120
        global_position = Vector3(0, 1.2, 12)
