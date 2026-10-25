extends CharacterBody3D

var health := 100
var attack_cooldown := 0.0
var player: Node3D
var speed := 2.2

func _ready() -> void:
    var body_mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.42
    capsule_mesh.height = 1.65
    body_mesh.mesh = capsule_mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.20, 0.29, 0.22)
    material.roughness = 0.9
    body_mesh.material_override = material
    add_child(body_mesh)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.7
    collision.shape = shape
    add_child(collision)
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player): return
    attack_cooldown = maxf(0, attack_cooldown - delta)
    var to_player: Vector3 = player.global_position - global_position
    to_player.y = 0
    if to_player.length() > 1.6:
        velocity.x = to_player.normalized().x * speed
        velocity.z = to_player.normalized().z * speed
        look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
    else:
        velocity.x = 0
        velocity.z = 0
        if attack_cooldown <= 0:
            attack_cooldown = 1.0
            if player.has_method("take_damage"): player.take_damage(8)
    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        var root = get_tree().current_scene
        if root.has_method("enemy_down"): root.enemy_down()
        queue_free()
