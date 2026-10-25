extends CharacterBody3D

const CHARACTER_MODELS := ["res://assets/characters/character-male-a.glb","res://assets/characters/character-male-b.glb","res://assets/characters/character-male-c.glb"]

var health := 100
var attack_cooldown := 0.0
var player: Node3D
var speed := 2.0
var alert_range := 42.0
var strafe_sign := 1.0
var preferred_distance := 14.0
var shot_audio: AudioStreamPlayer3D

func _ready() -> void:
 add_to_group("hostile")
 shot_audio = AudioStreamPlayer3D.new()
 shot_audio.name = "EnemyWeaponAudio"
 shot_audio.stream = load("res://assets/audio/rifle_shot.wav") as AudioStream
 shot_audio.volume_db = -9.0
 shot_audio.max_distance = 58.0
 shot_audio.unit_size = 8.0
 add_child(shot_audio)
 var has_character_model := _build_character_model()
 var vest_mat := StandardMaterial3D.new()
 vest_mat.albedo_color = Color(0.10,0.14,0.12)
 vest_mat.roughness = 0.9

 if not has_character_model:
  var body_mesh := MeshInstance3D.new()
  var body_shape := CapsuleMesh.new()
  body_shape.radius = 0.42
  body_shape.height = 1.65
  body_mesh.mesh = body_shape
  var body_material := StandardMaterial3D.new()
  body_material.albedo_color = Color(0.18,0.25,0.20)
  body_material.roughness = 0.9
  body_mesh.material_override = body_material
  add_child(body_mesh)

 var vest := MeshInstance3D.new()
 var vest_shape := BoxMesh.new()
 vest_shape.size = Vector3(0.72,0.55,0.40)
 vest.mesh = vest_shape
 vest.material_override = vest_mat
 vest.position.y = 0.06
 add_child(vest)

 if not has_character_model:
  var head := MeshInstance3D.new()
  var sphere := SphereMesh.new()
  sphere.radius = 0.22
  sphere.height = 0.44
  head.mesh = sphere
  head.position.y = 0.95
  var head_mat := StandardMaterial3D.new()
  head_mat.albedo_color = Color(0.34,0.27,0.21)
  head.material_override = head_mat
  add_child(head)

 var helmet := MeshInstance3D.new()
 var helmet_mesh := SphereMesh.new()
 helmet_mesh.radius = 0.25
 helmet_mesh.height = 0.23
 helmet_mesh.radial_segments = 8
 helmet_mesh.rings = 4
 helmet.mesh = helmet_mesh
 helmet.position = Vector3(0,0.78,0)
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
 var pack_mat := StandardMaterial3D.new()
 pack_mat.albedo_color = Color(0.12,0.16,0.13)
 pack_mat.roughness = 0.95
 backpack.material_override = pack_mat
 add_child(backpack)

 if not has_character_model:
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

 var collision := CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.radius = 0.42
 shape.height = 1.7
 collision.shape = shape
 add_child(collision)

 player = get_tree().get_first_node_in_group("player")
 speed = randf_range(2.8,3.8)
 preferred_distance = randf_range(11.0,17.0)
 strafe_sign = -1.0 if randf() < 0.5 else 1.0

func _build_character_model() -> bool:
 var model_path: String = CHARACTER_MODELS[randi_range(0,CHARACTER_MODELS.size()-1)]
 var packed := load(model_path) as PackedScene
 if packed == null:
  return false
 var model := packed.instantiate() as Node3D
 if model == null:
  return false
 add_child(model)
 var bounds: Array = []
 _collect_character_bounds(model,model,bounds)
 if bounds.is_empty():
  model.queue_free()
  return false
 var box: AABB = bounds[0]
 if box.size.y < 0.01:
  model.queue_free()
  return false
 var fit_scale := 1.68/box.size.y
 model.scale = Vector3.ONE*fit_scale
 model.position = Vector3(0,-0.84-box.position.y*fit_scale,0)
 return true

func _collect_character_bounds(root_node: Node3D, current: Node, bounds: Array) -> void:
 if current is MeshInstance3D:
  var mesh_instance := current as MeshInstance3D
  if mesh_instance.mesh != null:
   var local_box := mesh_instance.get_aabb()
   var relative: Transform3D = root_node.global_transform.affine_inverse()*mesh_instance.global_transform
   for x in [local_box.position.x,local_box.end.x]:
    for y in [local_box.position.y,local_box.end.y]:
     for z in [local_box.position.z,local_box.end.z]:
      var point: Vector3 = relative*Vector3(x,y,z)
      if bounds.is_empty():
       bounds.append(AABB(point,Vector3.ZERO))
      else:
       var old: AABB = bounds[0]
       bounds[0] = old.expand(point)
 for child in current.get_children():
  _collect_character_bounds(root_node,child,bounds)

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
 if not is_on_floor(): velocity.y-=18.0*delta
 move_and_slide()

func _try_attack(distance: float) -> void:
 if attack_cooldown>0 or distance>alert_range: return
 attack_cooldown=randf_range(1.1,1.8)
 # لا يصيب العدو اللاعب خلف الجدران: يجب أن يمر خط الرمي مباشرة إلى اللاعب.
 var from_point := global_position + Vector3(0,0.92,0)
 var to_point: Vector3 = player.global_position + Vector3(0,0.7,0)
 var query := PhysicsRayQueryParameters3D.create(from_point,to_point)
 query.exclude = [get_rid()]
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty() or hit.get("collider") != player:
  return
 if is_instance_valid(shot_audio):
  shot_audio.pitch_scale = randf_range(0.88,1.12)
  shot_audio.play()
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
