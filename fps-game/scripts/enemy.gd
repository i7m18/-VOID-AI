extends CharacterBody3D

var health := 100
var attack_cooldown := 0.0
var player: Node3D
var speed := 2.0
var alert_range := 42.0
var strafe_sign := 1.0
var preferred_distance := 14.0

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
 head_mat.albedo_color=Color(0.34,0.27,0.21)
 head.material_override=head_mat
 add_child(head)
 var helmet := MeshInstance3D.new()
 var helmet_mesh := SphereMesh.new()
 helmet_mesh.radius = 0.25
 helmet_mesh.height = 0.23
 helmet_mesh.radial_segments = 8
 helmet_mesh.rings = 4
 helmet.mesh = helmet_mesh
 helmet.position = Vector3(0,1.13,0)
 var helmet_mat := StandardMaterial3D.new()
 helmet_mat.albedo_color = Color(0.10,0.15,0.12)
 helmet_mat.roughness = 0.88
 helmet.material_override = helmet_mat
 add_child(helmet)
 var backpack := MeshInstance3D.new()
 var pack_mesh := BoxMesh.new()
 pack_mesh.size = Vector3(0.42,0.55,0.22)
 backpack.mesh = pack_mesh
 backpack.position = Vector3(0,0.14,0.27)
 backpack.material_override = material
 add_child(backpack)
 for side in [-1.0,1.0]:
  var shoulder := MeshInstance3D.new()
  var shoulder_mesh := BoxMesh.new()
  shoulder_mesh.size = Vector3(0.24,0.25,0.38)
  shoulder.mesh = shoulder_mesh
  shoulder.position = Vector3(side*0.43,0.23,0)
  shoulder.material_override = vest_mat
  add_child(shoulder)
  var leg := MeshInstance3D.new()
  var leg_mesh := BoxMesh.new()
  leg_mesh.size = Vector3(0.22,0.55,0.27)
  leg.mesh = leg_mesh
  leg.position = Vector3(side*0.18,-0.54,0.01)
  var leg_mat := StandardMaterial3D.new()
  leg_mat.albedo_color = Color(0.17,0.20,0.16)
  leg_mat.roughness = 0.97
  leg.material_override = leg_mat
  add_child(leg)
  var boot := MeshInstance3D.new()
  var boot_mesh := BoxMesh.new()
  boot_mesh.size = Vector3(0.24,0.13,0.35)
  boot.mesh = boot_mesh
  boot.position = Vector3(side*0.18,-0.82,-0.035)
  boot.material_override = dark_boot_material()
  add_child(boot)
 # بندقية ظاهرة على هيئة الجندي بدل الشكل الأسطواني المجرد.
 var rifle := MeshInstance3D.new()
 var rifle_mesh := BoxMesh.new()
 rifle_mesh.size = Vector3(0.10,0.10,0.70)
 rifle.mesh = rifle_mesh
 rifle.position = Vector3(0.42,0.02,-0.28)
 var rifle_mat := StandardMaterial3D.new()
 rifle_mat.albedo_color = Color(0.045,0.055,0.05)
 rifle_mat.metallic = 0.42
 rifle.material_override = rifle_mat
 add_child(rifle)
 var collision:=CollisionShape3D.new()
 var shape:=CapsuleShape3D.new()
 shape.radius=0.42
 shape.height=1.7
 collision.shape=shape
 add_child(collision)
 player=get_tree().get_first_node_in_group("player")
 speed=randf_range(2.8,3.8)
 preferred_distance=randf_range(11.0,17.0)
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
 else:
  var dir:=offset.normalized()
  var side:=Vector3(-dir.z,0,dir.x)*strafe_sign
  var advance:=0.0
  if distance > preferred_distance + 3.0:
   advance=1.0
  elif distance < preferred_distance - 4.0:
   advance=-0.55
  velocity.x=(dir.x*advance + side.x*0.72)*speed
  velocity.z=(dir.z*advance + side.z*0.72)*speed
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
 attack_cooldown=randf_range(1.1,1.8)
 # لا يصيب العدو اللاعب خلف الجدران: يجب أن يمر خط الرمي مباشرة إلى اللاعب.
 var from_point := global_position + Vector3(0,0.92,0)
 var to_point: Vector3 = player.global_position + Vector3(0,1.05,0)
 var query := PhysicsRayQueryParameters3D.create(from_point,to_point)
 query.exclude = [get_rid()]
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty() or hit.get("collider") != player:
  return
 if player.has_method("take_damage"):
  player.take_damage(4 if distance>22.0 else (6 if distance>12.0 else 8))

func dark_boot_material() -> StandardMaterial3D:
 var boot_mat := StandardMaterial3D.new()
 boot_mat.albedo_color = Color(0.045,0.05,0.045)
 boot_mat.roughness = 0.95
 return boot_mat

func take_damage(amount: int) -> void:
 health-=amount
 if health<=0:
  var root:=get_tree().current_scene
  if is_instance_valid(root) and root.has_method("enemy_down"):
   root.enemy_down()
  queue_free()
