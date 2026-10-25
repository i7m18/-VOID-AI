extends CharacterBody3D

var health := 100
var attack_cooldown := 0.0
var player: Node3D
var speed := 2.0
var alert_range := 42.0
var strafe_sign := 1.0

func _ready() -> void:
 var body_mesh:=MeshInstance3D.new()
 var body_shape:=CapsuleMesh.new()
 body_shape.radius=0.42
 body_shape.height=1.65
 body_mesh.mesh=body_shape
 var material:=StandardMaterial3D.new()
 material.albedo_color=Color(0.18,0.25,0.20)
 material.roughness=0.9
 body_mesh.material_override=material
 add_child(body_mesh)
 var vest:=MeshInstance3D.new()
 var vest_shape:=BoxMesh.new()
 vest_shape.size=Vector3(0.72,0.55,0.4)
 vest.mesh=vest_shape
 var vest_mat:=StandardMaterial3D.new()
 vest_mat.albedo_color=Color(0.10,0.13,0.12)
 vest.material_override=vest_mat
 vest.position.y=0.08
 add_child(vest)
 var head:=MeshInstance3D.new()
 var sphere:=SphereMesh.new()
 sphere.radius=0.22
 sphere.height=0.44
 head.mesh=sphere
 head.position.y=0.95
 var head_mat:=StandardMaterial3D.new()
 head_mat.albedo_color=Color(0.48,0.40,0.32)
 head.material_override=head_mat
 add_child(head)
 var collision:=CollisionShape3D.new()
 var shape:=CapsuleShape3D.new()
 shape.radius=0.42
 shape.height=1.7
 collision.shape=shape
 add_child(collision)
 player=get_tree().get_first_node_in_group("player")
 speed=randf_range(1.9,3.0)
 strafe_sign=-1.0 if randf()<0.5 else 1.0

func _physics_process(delta: float) -> void:
 if not is_instance_valid(player): return
 var root:=get_tree().current_scene
 if is_instance_valid(root) and not bool(root.get("game_active")): return
 attack_cooldown=maxf(0.0,attack_cooldown-delta)
 var offset: Vector3=player.global_position-global_position
 offset.y=0
 var distance:=offset.length()
 if distance>alert_range:
  velocity.x=move_toward(velocity.x,0,delta*4)
  velocity.z=move_toward(velocity.z,0,delta*4)
 elif distance>12.0:
  var dir:=offset.normalized()
  var side:=Vector3(-dir.z,0,dir.x)*strafe_sign*0.25
  velocity.x=(dir.x+side.x)*speed
  velocity.z=(dir.z+side.z)*speed
  look_at(Vector3(player.global_position.x,global_position.y,player.global_position.z))
  _try_attack(distance)
 elif distance>2.3:
  var dir:=offset.normalized()
  velocity.x=dir.x*speed*0.65
  velocity.z=dir.z*speed*0.65
  look_at(Vector3(player.global_position.x,global_position.y,player.global_position.z))
  _try_attack(distance)
 else:
  velocity.x=0
  velocity.z=0
  if attack_cooldown<=0:
   attack_cooldown=0.9
   if player.has_method("take_damage"): player.take_damage(10)
 if not is_on_floor(): velocity.y-=18.0*delta
 move_and_slide()

func _try_attack(distance: float) -> void:
 if attack_cooldown>0 or distance>alert_range: return
 attack_cooldown=randf_range(1.3,2.1)
 if player.has_method("take_damage"):
  player.take_damage(5 if distance>12 else 7)

func take_damage(amount: int) -> void:
 health-=amount
 if health<=0:
  var root:=get_tree().current_scene
  if is_instance_valid(root) and root.has_method("enemy_down"):
   root.enemy_down()
  queue_free()
