extends CharacterBody3D

const WALK_SPEED := 6.2
const CAR_SPEED := 13.5
const JUMP_VELOCITY := 4.3
const MOUSE_SENSITIVITY := 0.0022
const WEAPON_NAMES := ["بندقية هجومية","رشاش خفيف","بندقية قنص"]
const WEAPON_ASSET_PATHS := ["res://assets/weapons/assault_rifle.glb","res://assets/weapons/compact_smg.glb","res://assets/weapons/sniper_rifle.glb"]
const MAGAZINES := [30,45,5]
const DAMAGE := [34,19,100]
const RATES := [0.17,0.095,0.85]
var health := 100
var weapon_index := 0
var ammo := [30,45,5]
var reserve_ammo := [150,225,25]
var reloading := false
var in_vehicle := false
var camera: Camera3D
var ray: RayCast3D
var weapon_model: Node3D
var fire_timer := 0.0
var reload_token := 0
var muzzle_flash: MeshInstance3D
var muzzle_light: OmniLight3D
var muzzle_flash_remaining := 0.0
var recoil_pitch := 0.0
var shot_audio: AudioStreamPlayer3D
var body_collider: CollisionShape3D
var body_capsule: CapsuleShape3D
var aiming := false
var sprinting := false
var crouched := false
var grenades := 3
var arm_group: Node3D

func _ready() -> void:
 add_to_group("player")
 var collider := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius=0.42
 capsule.height=1.8
 collider.shape=capsule
 body_collider = collider
 body_capsule = capsule
 add_child(collider)
 camera=Camera3D.new()
 camera.position=Vector3(0,0.55,0)
 camera.current=true
 add_child(camera)
 ray=RayCast3D.new()
 ray.target_position=Vector3(0,0,-100)
 ray.enabled=true
 ray.add_exception(self)
 camera.add_child(ray)
 _build_weapon_model()
 _build_view_arms()
 _build_muzzle_effect()
 _build_shot_audio()

func _process(delta: float) -> void:
 if muzzle_flash_remaining > 0.0:
  muzzle_flash_remaining = maxf(0.0,muzzle_flash_remaining-delta)
  var flash_visible := muzzle_flash_remaining > 0.0
  if is_instance_valid(muzzle_flash): muzzle_flash.visible = flash_visible
  if is_instance_valid(muzzle_light): muzzle_light.visible = flash_visible
 if recoil_pitch > 0.0 and is_instance_valid(camera):
  var recover := minf(recoil_pitch,delta*0.42)
  camera.rotation.x = clampf(camera.rotation.x+recover,-1.48,1.48)
  recoil_pitch -= recover

func _build_view_arms() -> void:
 # أكمام عسكرية وقفازات ظاهرة في منظور الشخص الأول لإحساس سلاح محمول باليد.
 arm_group = Node3D.new()
 arm_group.name = "FirstPersonArms"
 camera.add_child(arm_group)
 var sleeve_mat := StandardMaterial3D.new()
 sleeve_mat.albedo_color = Color(0.18,0.22,0.16)
 sleeve_mat.roughness = 0.95
 var glove_mat := StandardMaterial3D.new()
 glove_mat.albedo_color = Color(0.045,0.055,0.045)
 glove_mat.roughness = 0.88
 for side in [-1.0,1.0]:
  var sleeve := MeshInstance3D.new()
  var sleeve_mesh := CapsuleMesh.new()
  sleeve_mesh.radius = 0.115
  sleeve_mesh.height = 0.66
  sleeve.mesh = sleeve_mesh
  sleeve.material_override = sleeve_mat
  if side < 0:
   sleeve.position = Vector3(-0.23,-0.53,-0.39)
   sleeve.rotation = Vector3(deg_to_rad(-32),0,deg_to_rad(-26))
  else:
   sleeve.position = Vector3(0.45,-0.51,-0.20)
   sleeve.rotation = Vector3(deg_to_rad(-38),0,deg_to_rad(18))
  arm_group.add_child(sleeve)
  var glove := MeshInstance3D.new()
  var glove_mesh := SphereMesh.new()
  glove_mesh.radius = 0.12
  glove_mesh.height = 0.18
  glove_mesh.radial_segments = 8
  glove.mesh = glove_mesh
  glove.material_override = glove_mat
  glove.position = Vector3(-0.03,-0.27,-0.67) if side < 0 else Vector3(0.31,-0.29,-0.55)
  arm_group.add_child(glove)

func set_aiming(enabled: bool) -> void:
 aiming = enabled
 _update_aim_state()

func _update_aim_state() -> void:
 if not is_instance_valid(camera): return
 camera.fov = 48.0 if aiming else 78.0
 if is_instance_valid(weapon_model):
  weapon_model.position = Vector3(0.15,-0.19,-0.48) if aiming else Vector3(0.30,-0.27,-0.58)

func set_sprinting(enabled: bool) -> void:
 sprinting = enabled and not crouched and not in_vehicle

func toggle_crouch() -> void:
 crouched = not crouched
 if crouched: sprinting = false
 if is_instance_valid(body_capsule): body_capsule.height = 1.25 if crouched else 1.8
 if is_instance_valid(body_collider): body_collider.position.y = -0.26 if crouched else 0.0
 if is_instance_valid(camera): camera.position.y = 0.18 if crouched else 0.55

func throw_grenade() -> void:
 if grenades <= 0:
  var root := get_tree().current_scene
  if is_instance_valid(root) and root.has_method("show_message"):
   root.show_message("نفدت القنابل اليدوية")
  return
 var root := get_tree().current_scene
 if not is_instance_valid(root) or not bool(root.get("game_active")): return
 if root.has_method("throw_grenade"):
  grenades -= 1
  root.throw_grenade(camera.global_position,camera.global_basis.z * -1.0,self)
  _update_hud()

func _build_muzzle_effect() -> void:
 muzzle_flash = MeshInstance3D.new()
 muzzle_flash.name = "MuzzleFlash"
 var flash_mesh := SphereMesh.new()
 flash_mesh.radius = 0.085
 flash_mesh.height = 0.16
 flash_mesh.radial_segments = 6
 flash_mesh.rings = 3
 muzzle_flash.mesh = flash_mesh
 muzzle_flash.position = Vector3(0.30,-0.27,-1.18)
 var flash_material := StandardMaterial3D.new()
 flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 flash_material.albedo_color = Color(1.0,0.56,0.16)
 flash_material.emission_enabled = true
 flash_material.emission = Color(1.0,0.32,0.055)
 flash_material.emission_energy_multiplier = 4.0
 muzzle_flash.material_override = flash_material
 muzzle_flash.visible = false
 camera.add_child(muzzle_flash)
 muzzle_light = OmniLight3D.new()
 muzzle_light.light_color = Color(1.0,0.46,0.16)
 muzzle_light.light_energy = 2.8
 muzzle_light.omni_range = 4.5
 muzzle_light.position = Vector3(0.30,-0.27,-1.16)
 muzzle_light.visible = false
 camera.add_child(muzzle_light)

func _build_shot_audio() -> void:
 shot_audio = AudioStreamPlayer3D.new()
 shot_audio.name = "WeaponAudio"
 shot_audio.volume_db = -3.5
 shot_audio.max_distance = 75.0
 shot_audio.unit_size = 8.0
 add_child(shot_audio)
 _refresh_weapon_audio()

func _refresh_weapon_audio() -> void:
 if not is_instance_valid(shot_audio): return
 var path := "res://assets/audio/sniper_shot.wav" if weapon_index == 2 else "res://assets/audio/rifle_shot.wav"
 var actual_stream := load(path) as AudioStream
 if actual_stream != null:
  shot_audio.stream = actual_stream
  return
 # أصوات احتياطية إذا فشل تنزيل أحد الملفات الصوتية.
 var wav := AudioStreamWAV.new()
 wav.mix_rate = 22050
 wav.format = AudioStreamWAV.FORMAT_16_BITS
 wav.stereo = false
 var pcm := PackedByteArray()
 for i in range(3308):
  var t := float(i)/float(wav.mix_rate)
  var envelope := exp(-t*35.0)
  var low := sin(TAU*95.0*t)*0.45
  var noise := randf_range(-1.0,1.0)*0.75
  var sample := clampi(int((low+noise)*envelope*17500.0),-32768,32767)
  pcm.append(sample & 0xff)
  pcm.append((sample >> 8) & 0xff)
 wav.data = pcm
 shot_audio.stream = wav

func _build_weapon_model() -> void:
 weapon_model = Node3D.new()
 weapon_model.name = "WeaponModel"
 weapon_model.position = Vector3(0.30,-0.27,-0.58)
 camera.add_child(weapon_model)
 _update_weapon_model()

func _add_weapon_part(mesh: Mesh, position_value: Vector3, material: Material, rotation_value: Vector3=Vector3.ZERO) -> void:
 var part := MeshInstance3D.new()
 part.mesh = mesh
 part.position = position_value
 part.rotation = rotation_value
 part.material_override = material
 weapon_model.add_child(part)

func _update_weapon_model() -> void:
 if not is_instance_valid(weapon_model): return
 for child in weapon_model.get_children():
  child.free()

 # استخدم نموذج سلاح ثلاثي الأبعاد فعلياً، مع ضبط الحجم والمحور تلقائياً.
 if weapon_index < WEAPON_ASSET_PATHS.size():
  var packed := load(WEAPON_ASSET_PATHS[weapon_index]) as PackedScene
  if packed != null:
   var model := packed.instantiate() as Node3D
   if model != null:
    weapon_model.add_child(model)
    var bounds: Array = []
    _collect_weapon_bounds(model,model,bounds)
    if not bounds.is_empty():
     var aabb: AABB = bounds[0]
     if aabb.size.length() > 0.001:
      var longest_axis := 0
      if aabb.size.y > aabb.size.x and aabb.size.y >= aabb.size.z:
       longest_axis = 1
      elif aabb.size.z > aabb.size.x and aabb.size.z > aabb.size.y:
       longest_axis = 2
      model.rotation = Vector3.ZERO
      if longest_axis == 0:
       model.rotation.y = PI * 0.5
      elif longest_axis == 1:
       model.rotation.x = PI * 0.5
      var long_extent := maxf(aabb.size.x,maxf(aabb.size.y,aabb.size.z))
      var target_length := 0.84 if weapon_index == 2 else 0.72
      var uniform_scale := target_length / maxf(long_extent,0.001)
      model.scale = Vector3.ONE * uniform_scale
      model.position = -(model.basis * aabb.get_center())
      return
    model.queue_free()

 # احتياط آمن عند غياب أحد ملفات الأصول.
 var dark := StandardMaterial3D.new()
 dark.albedo_color = Color(0.075,0.09,0.085)
 dark.metallic = 0.48
 dark.roughness = 0.42
 var metal := StandardMaterial3D.new()
 metal.albedo_color = Color(0.19,0.22,0.20)
 metal.metallic = 0.68
 metal.roughness = 0.32
 var grip_mat := StandardMaterial3D.new()
 grip_mat.albedo_color = Color(0.12,0.14,0.12)
 grip_mat.roughness = 0.92
 var body_mesh := BoxMesh.new()
 body_mesh.size = Vector3(0.15,0.12,0.40 if weapon_index != 2 else 0.48)
 _add_weapon_part(body_mesh,Vector3(0,0,0),dark)
 var barrel_mesh := BoxMesh.new()
 barrel_mesh.size = Vector3(0.045,0.045,0.38 if weapon_index != 2 else 0.62)
 _add_weapon_part(barrel_mesh,Vector3(0,-0.005,-0.37 if weapon_index != 2 else -0.51),metal)
 var stock_mesh := BoxMesh.new()
 stock_mesh.size = Vector3(0.12,0.09,0.21)
 _add_weapon_part(stock_mesh,Vector3(0,0,0.27),grip_mat)
 var grip_mesh := BoxMesh.new()
 grip_mesh.size = Vector3(0.065,0.16,0.09)
 _add_weapon_part(grip_mesh,Vector3(0,0.11,0.08),grip_mat,Vector3(deg_to_rad(-12),0,0))
 var magazine_mesh := BoxMesh.new()
 magazine_mesh.size = Vector3(0.075,0.18,0.12 if weapon_index != 2 else 0.16)
 _add_weapon_part(magazine_mesh,Vector3(0,0.14,-0.055),dark,Vector3(deg_to_rad(-8),0,0))
 var handguard_mesh := BoxMesh.new()
 handguard_mesh.size = Vector3(0.105,0.09,0.22)
 _add_weapon_part(handguard_mesh,Vector3(0,0.015,-0.22),grip_mat)
 var sight_mesh := BoxMesh.new()
 sight_mesh.size = Vector3(0.055,0.045,0.07)
 _add_weapon_part(sight_mesh,Vector3(0,0.082,-0.11),metal)
 if weapon_index == 2:
  var scope := CylinderMesh.new()
  scope.top_radius = 0.055
  scope.bottom_radius = 0.055
  scope.height = 0.31
  _add_weapon_part(scope,Vector3(0,0.105,-0.10),dark,Vector3(deg_to_rad(90),0,0))
 var muzzle := BoxMesh.new()
 muzzle.size = Vector3(0.064,0.064,0.07)
 _add_weapon_part(muzzle,Vector3(0,-0.005,-0.69 if weapon_index != 2 else -0.85),dark)

func _collect_weapon_bounds(root_node: Node3D, current: Node, bounds: Array) -> void:
 if current is MeshInstance3D:
  var mesh_instance := current as MeshInstance3D
  if mesh_instance.mesh != null:
   var mesh_bounds := mesh_instance.get_aabb()
   var relative_transform: Transform3D = root_node.global_transform.affine_inverse() * mesh_instance.global_transform
   for x in [mesh_bounds.position.x,mesh_bounds.end.x]:
    for y in [mesh_bounds.position.y,mesh_bounds.end.y]:
     for z in [mesh_bounds.position.z,mesh_bounds.end.z]:
      var point: Vector3 = relative_transform * Vector3(x,y,z)
      if bounds.is_empty():
       bounds.append(AABB(point,Vector3.ZERO))
      else:
       var old_bounds: AABB = bounds[0]
       bounds[0] = old_bounds.expand(point)
 for child in current.get_children():
  _collect_weapon_bounds(root_node,child,bounds)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey:
  if event.keycode == KEY_SHIFT:
   set_sprinting(event.pressed)
  if not event.pressed: return
  if event.keycode == KEY_ESCAPE:
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  elif event.keycode == KEY_R:
   reload_weapon()
  elif event.keycode == KEY_Q:
   switch_weapon()
  elif event.keycode == KEY_E:
   toggle_vehicle()
  elif event.keycode == KEY_F:
   var root = get_tree().current_scene
   if is_instance_valid(root) and root.has_method("interact_objective"):
    root.interact_objective()
  elif event.keycode == KEY_G:
   throw_grenade()
  elif event.keycode == KEY_C:
   toggle_crouch()
  elif event.keycode == KEY_1:
   _set_weapon(0)
  elif event.keycode == KEY_2:
   _set_weapon(1)
  elif event.keycode == KEY_3:
   _set_weapon(2)
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_RIGHT:
   set_aiming(event.pressed)
  elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
   Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
   fire()

func look_by(relative: Vector2) -> void:
 var sensitivity := MOUSE_SENSITIVITY * (0.62 if aiming else 1.0)
 rotate_y(-relative.x*sensitivity)
 camera.rotate_x(-relative.y*sensitivity)
 camera.rotation.x=clamp(camera.rotation.x,-1.48,1.48)

func _physics_process(delta: float) -> void:
 var root := get_tree().current_scene
 if root and not bool(root.get("game_active")): return
 fire_timer=maxf(0.0,fire_timer-delta)
 if in_vehicle:
  velocity.y=0
 elif not is_on_floor():
  velocity.y-=18.0*delta
 var move_input:=Vector2.ZERO
 if is_instance_valid(root) and root.has_method("get_move_input"):
  move_input=root.get_move_input()
 var keys:=Vector2(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),float(Input.is_key_pressed(KEY_W))-float(Input.is_key_pressed(KEY_S)))
 if keys.length()>0: move_input=keys.normalized()
 var direction: Vector3=(transform.basis*Vector3(move_input.x,0,-move_input.y)).normalized()
 var speed:=CAR_SPEED if in_vehicle else WALK_SPEED*(1.55 if sprinting else (0.70 if crouched else 1.0))
 velocity.x=direction.x*speed
 velocity.z=direction.z*speed
 if Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not in_vehicle:
  velocity.y=JUMP_VELOCITY
 move_and_slide()
 if in_vehicle:
  var car=root.get("vehicle")
  if is_instance_valid(car):
   car.global_position=global_position+global_basis*Vector3(0,-0.15,0.65)
   car.global_rotation.y=rotation.y

func fire() -> void:
 if in_vehicle or reloading or fire_timer>0.0: return
 if int(ammo[weapon_index])<=0:
  reload_weapon()
  return
 fire_timer=RATES[weapon_index]
 ammo[weapon_index]=int(ammo[weapon_index])-1
 var kick := 0.022 if weapon_index == 0 else (0.014 if weapon_index == 1 else 0.058)
 camera.rotation.x = clampf(camera.rotation.x-kick,-1.48,1.48)
 recoil_pitch = minf(0.16,recoil_pitch+kick)
 muzzle_flash_remaining = 0.055
 if is_instance_valid(muzzle_flash): muzzle_flash.visible = true
 if is_instance_valid(muzzle_light): muzzle_light.visible = true
 if is_instance_valid(shot_audio):
  shot_audio.pitch_scale = randf_range(0.92,1.06)
  shot_audio.play()
 ray.force_raycast_update()
 if ray.is_colliding():
  var target=ray.get_collider()
  if is_instance_valid(target) and target.has_method("take_damage"):
   target.take_damage(DAMAGE[weapon_index])
   var root := get_tree().current_scene
   if is_instance_valid(root) and root.has_method("show_hitmarker"):
    root.show_hitmarker()
 _update_hud()

func switch_weapon() -> void:
 _set_weapon((weapon_index+1)%WEAPON_NAMES.size())

func _set_weapon(index: int) -> void:
 weapon_index=clampi(index,0,WEAPON_NAMES.size()-1)
 _update_weapon_model()
 _update_aim_state()
 _refresh_weapon_audio()
 reloading=false
 reload_token+=1
 _update_hud()

func get_weapon_name() -> String:
 return WEAPON_NAMES[weapon_index]

func get_current_ammo() -> int:
 return int(ammo[weapon_index])

func get_current_reserve_ammo() -> int:
 return int(reserve_ammo[weapon_index])

func reload_weapon() -> void:
 if reloading or int(ammo[weapon_index])>=MAGAZINES[weapon_index] or int(reserve_ammo[weapon_index])<=0: return
 reloading=true
 reload_token+=1
 var token:=reload_token
 _update_hud()
 await get_tree().create_timer(1.35 if weapon_index!=2 else 1.7).timeout
 if not is_inside_tree() or token!=reload_token: return
 var needed: int=MAGAZINES[weapon_index]-int(ammo[weapon_index])
 var loaded: int=mini(needed,int(reserve_ammo[weapon_index]))
 ammo[weapon_index]=int(ammo[weapon_index])+loaded
 reserve_ammo[weapon_index]=int(reserve_ammo[weapon_index])-loaded
 reloading=false
 _update_hud()

func toggle_vehicle() -> void:
 var root:=get_tree().current_scene
 if not is_instance_valid(root) or not bool(root.get("game_active")): return
 var car=root.get("vehicle")
 if not is_instance_valid(car): return
 if in_vehicle:
  in_vehicle=false
  global_position+=-global_basis.z*2.0+Vector3.UP*0.1
  camera.position.y=0.55
 elif global_position.distance_to(car.global_position)<5.0:
  in_vehicle=true
  global_position=car.global_position
  camera.position.y=1.35
 _update_hud()

func take_damage(amount: int) -> void:
 if in_vehicle: amount=int(ceil(float(amount)*0.45))
 health=maxi(0,health-amount)
 _update_hud()
 var root:=get_tree().current_scene
 if is_instance_valid(root) and root.has_method("player_hit"):
  root.player_hit()

func _update_hud() -> void:
 var root:=get_tree().current_scene
 if is_instance_valid(root) and root.has_method("_update_hud"):
  root._update_hud()
